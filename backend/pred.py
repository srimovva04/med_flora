import os
import sys
import re
import json
from io import BytesIO

import torch
import torch.nn as nn
import torchvision.transforms as transforms
from PIL import Image, UnidentifiedImageError
import requests
from flask import Flask, request, jsonify
from flask_cors import CORS
from langchain_mistralai import ChatMistralAI
from langchain_core.prompts import ChatPromptTemplate

# ===================================================================
# 1. PYTORCH MODEL CLASS DEFINITION
# ===================================================================
# This class structure must match the one used when the model was saved.
class ScratchPredictor(nn.Module):
    def __init__(self, num_classes):
        super().__init__()
        self.features = nn.Sequential(
            nn.Conv2d(3, 64, kernel_size=3, padding=1),
            nn.BatchNorm2d(64),
            nn.ReLU(inplace=True),
            nn.MaxPool2d(kernel_size=2, stride=2),
            nn.Conv2d(64, 128, kernel_size=3, padding=1),
            nn.BatchNorm2d(128),
            nn.ReLU(inplace=True),
            nn.MaxPool2d(kernel_size=2, stride=2),
            nn.Conv2d(128, 256, kernel_size=3, padding=1),
            nn.BatchNorm2d(256),
            nn.ReLU(inplace=True),
            nn.MaxPool2d(kernel_size=2, stride=2),
            nn.Conv2d(256, 512, kernel_size=3, padding=1),
            nn.BatchNorm2d(512),
            nn.ReLU(inplace=True),
            nn.MaxPool2d(kernel_size=2, stride=2),
            nn.Conv2d(512, 512, kernel_size=3, padding=1),
            nn.BatchNorm2d(512),
            nn.ReLU(inplace=True),
        )
        self.global_avg_pool = nn.AdaptiveAvgPool2d((1, 1))
        self.classifier = nn.Sequential(
            nn.Flatten(),
            nn.Dropout(0.5),
            nn.Linear(512, 2048),
            nn.ReLU(inplace=True),
            nn.BatchNorm1d(2048),
            nn.Dropout(0.3),
            nn.Linear(2048, 1024),
            nn.ReLU(inplace=True),
            nn.BatchNorm1d(1024),
            nn.Dropout(0.3),
            nn.Linear(1024, num_classes)
        )

    def forward(self, x):
        x = self.features(x)
        x = self.global_avg_pool(x)
        x = self.classifier(x)
        return x

# ===================================================================
# 2. MODEL LOADING AND GLOBAL SETUP
# ===================================================================

# --- Gunicorn/Pickle Workaround ---
# Solves the '__main__' module error when loading the full PyTorch model.
sys.modules['__main__'] = sys.modules[__name__]

# --- Load PyTorch Model ---
MODEL_PATH = "new_data.pth"
DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu")
model = torch.load(MODEL_PATH, map_location=DEVICE, weights_only=False)
model.to(DEVICE)
model.eval()

# --- Image Preprocessing ---
preprocess = transforms.Compose([
    transforms.Resize(256),
    transforms.CenterCrop(224),
    transforms.ToTensor(),
    transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225])
])

# --- Mistral AI Setup ---
MISTRAL_API_KEY = os.getenv("MISTRAL_API_KEY")
if not MISTRAL_API_KEY:
    raise ValueError("MISTRAL_API_KEY environment variable not set!")

model_mistral = ChatMistralAI(model="mistral-small-latest", temperature=0.3, api_key=MISTRAL_API_KEY)

TEMPLATE = """
*STRICTLY GIVE BACK JSON NOTHING EXTRA ,NO HEADING TO THE TEXT, NO JSON WRITTEN IN FRONT OF THE JSON*
Provide the following details about the plant '{plant_name}' in STRICT JSON format.
{{
    "name": "...", "description": "...", "uses": "...", "natural_medicinal_benefits": "...",
    "pharmaceutical_uses": "...", "chemical_composition": "...", "plant_height": "...",
    "locations_in_india": [...], "climate": {{"temperature": "...", "rainfall": "..."}},
    "pharmaceutical_usage": {{"product1": "...", "product2": "..."}},
    "soil_conditions": {{"type": "...", "pH": "...", "best_conditions": "..."}},
    "varieties": [...], "fertilizer_requirement": "...",
    "irrigation": {{"summer": "...", "rainy": "...", "winter": "..."}},
    "harvesting": {{"method": "...", "frequency": "..."}}, "coordinates": [...]
}}
"""

def get_plant_info(plant_name):
    """Queries Mistral AI for plant details and returns a JSON object."""
    prompt = ChatPromptTemplate.from_template(TEMPLATE)
    chain = prompt | model_mistral
    response = chain.invoke({"plant_name": plant_name})
    raw_content = response.content.strip()

    try:
        json_start = raw_content.find('{')
        json_end = raw_content.rfind('}') + 1
        if json_start != -1 and json_end != 0:
            json_str = raw_content[json_start:json_end]
            return json.loads(json_str)
        else:
            raise json.JSONDecodeError("No JSON object found", raw_content, 0)
    except Exception as e:
        print(f"❌ JSON parsing error: {e}")
        return {"error": "Failed to parse JSON response from AI", "raw_response": raw_content}

# ===================================================================
# 3. FLASK APPLICATION
# ===================================================================

app = Flask(__name__)
# --- Enable CORS ---
CORS(app)

@app.route("/predict", methods=["POST"])
def predict():
    """Receives an image URL, predicts the plant, and returns its details."""
    data = request.json
    if not data or "image_url" not in data:
        return jsonify({"error": "No image URL provided"}), 400

    image_url = data["image_url"]

    try:
        # 1. Fetch and validate the image
        headers = {'User-Agent': 'Mozilla/5.0'}
        response = requests.get(image_url, headers=headers, timeout=15)
        response.raise_for_status()

        content_type = response.headers.get('Content-Type')
        if not content_type or not content_type.startswith('image/'):
            return jsonify({"error": f"URL did not point to a valid image. Content-Type: {content_type}"}), 400

        # 2. Process the image using Pillow
        image_bytes = BytesIO(response.content)
        image = Image.open(image_bytes).convert("RGB")
        image_tensor = preprocess(image).unsqueeze(0).to(DEVICE)

        # 3. Predict using the PyTorch model
        with torch.no_grad():
            output = model(image_tensor)
            _, predicted_class_idx = torch.max(output, 1)

        class_names = model.class_names
        predicted_label = class_names[predicted_class_idx.item()]

        # 4. Get detailed information from Mistral AI
        plant_info = get_plant_info(predicted_label)
        return jsonify(plant_info)

    except requests.exceptions.RequestException as e:
        return jsonify({"error": f"Failed to download image: {str(e)}"}), 400
    except UnidentifiedImageError:
        return jsonify({"error": "Could not identify image file. It may be corrupt or not a supported format."}), 400
    except AttributeError:
         return jsonify({"error": "Model is missing the 'class_names' attribute."}), 500
    except Exception as e:
        return jsonify({"error": f"An unexpected error occurred on the server: {str(e)}"}), 500

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=5000, debug=True)
