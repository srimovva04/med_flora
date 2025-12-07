import os
import requests
from flask import Flask, request, jsonify
from flask_cors import CORS

app = Flask(__name__)
# Enable CORS for all routes, allowing your Flutter app to call this
CORS(app)

# --- Configuration ---
# IMPORTANT: Best practice is to set this as an environment variable
PLANTNET_API_KEY = os.getenv("PLANTNET_API_KEY")
PLANTNET_API_URL = "https://my-api.plantnet.org/v2/identify/all"

if not PLANTNET_API_KEY:
    raise RuntimeError("PLANTNET_API_KEY environment variable is not set!")


PLANT_NAME_MAP = {
    # Detected Name (lowercase) : "Canonical Name to Return"
    
    # Abelmoschus moschatus
    "abelmoschus moschatus": "Abelmoschus moschatus Medik.",
    "musk mallow": "Abelmoschus moschatus Medik.",
    "ambrette": "Abelmoschus moschatus Medik.",
    
    # Aegle marmelos
    "aegle marmelos": "Aegle marmelos (L.) Corrêa",
    "bael": "Aegle marmelos (L.) Corrêa",
    "bengal quince": "Aegle marmelos (L.) Corrêa",
    "stone apple": "Aegle marmelos (L.) Corrêa",
    
    # Aerva sanguinolenta
    "aerva sanguinolenta": "Aerva sanguinolenta",
    
    # Aloe vera
    "aloe vera": "Aloe vera (L.) Burm.f.",
    "aloe barbadensis": "Aloe vera (L.) Burm.f.",
    "aloe barbadensis miller": "Aloe vera (L.) Burm.f.",
    "aloe succotrina": "Aloe vera (L.) Burm.f.",
    
    # Alpinia galanga
    "alpinia galanga": "Alpinia galanga (L.) Willd.",
    "greater galangal": "Alpinia galanga (L.) Willd.",
    "galangal": "Alpinia galanga (L.) Willd.",
    
    # Andrographis paniculata
    "andrographis paniculata": "Andrographis paniculata (Burm.f.) Wall.",
    "king of bitters": "Andrographis paniculata (Burm.f.) Wall.",
    "kalmegh": "Andrographis paniculata (Burm.f.) Wall.",
    
    # Aquilaria malaccensis
    "aquilaria malaccensis": "Aquilaria malaccensis Lam.",
    "agarwood": "Aquilaria malaccensis Lam.",
    "oud": "Aquilaria malaccensis Lam.",
    
    # Aristolochia indica
    "aristolochia indica": "Aristolochia indica L.",
    "indian birthwort": "Aristolochia indica L.",
    
    # Artemisia absinthium
    "artemisia absinthium": "Artemisia absinthium L.",
    "wormwood": "Artemisia absinthium L.",
    "absinthe": "Artemisia absinthium L.",
    
    # Asparagus officinalis
    "asparagus officinalis": "Asparagus officinalis L.",
    "asparagus": "Asparagus officinalis L.",
    
    # Azadirachta indica
    "azadirachta indica": "Azadirachta indica",
    "neem": "Azadirachta indica",
    
    # Bacopa monnieri
    "bacopa monnieri": "Bacopa monnieri (L.) Wettst.",
    "brahmi": "Bacopa monnieri (L.) Wettst.",
    "water hyssop": "Bacopa monnieri (L.) Wettst.",
    
    # Belamcanda chinensis
    "belamcanda chinensis": "Belamcanda chinensis (L.) Redouté",
    "blackberry lily": "Belamcanda chinensis (L.) Redouté",
    
    # Bixa orellana
    "bixa orellana": "Bixa orellana L.",
    "annatto": "Bixa orellana L.",
    "achiote": "Bixa orellana L.",
    
    # Boerhavia diffusa
    "boerhavia diffusa": "Boerhavia diffusa",
    "punarnava": "Boerhavia diffusa",
    
    # Breynia androgyna
    "breynia androgyna": "Breynia androgyna (L.) Chakrab. & N.P.Balakr.",
    
    # Brucea mollis
    "brucea mollis": "Brucea mollis Wall. Ex Kurz",
    
    # Canna indica
    "canna indica": "Canna indica L.",
    "indian shot": "Canna indica L.",
    
    # Cassia fistula
    "cassia fistula": "Cassia fistula L.",
    "golden shower": "Cassia fistula L.",
    "indian laburnum": "Cassia fistula L.",
    
    # Catharanthus roseus
    "catharanthus roseus": "Catharanthus roseus (L.) G.Don",
    "madagascar periwinkle": "Catharanthus roseus (L.) G.Don",
    "vinca rosea": "Catharanthus roseus (L.) G.Don",
    
    # Centella asiatica
    "centella asiatica": "Centella asiatica (L.) Urb.",
    "gotu kola": "Centella asiatica (L.) Urb.",
    "brahma manduki": "Centella asiatica (L.) Urb.",
    
    # Chamaecostus cuspidatus
    "chamaecostus cuspidatus": "Chamaecostus cuspidatus (Nees & Mart.) C.D.Specht & D.W.Stev.",
    "costus cuspidatus": "Chamaecostus cuspidatus (Nees & Mart.) C.D.Specht & D.W.Stev.",
    
    # Cinnamomum tamala
    "cinnamomum tamala": "Cinnamomum tamala T.Nees & Eberm.",
    "indian bay leaf": "Cinnamomum tamala T.Nees & Eberm.",
    "tejpat": "Cinnamomum tamala T.Nees & Eberm.",
    
    # Cinnamomum verum
    "cinnamomum verum": "Cinnamomum verum J.Presl",
    "cinnamon": "Cinnamomum verum J.Presl",
    "ceylon cinnamon": "Cinnamomum verum J.Presl",
    
    # Cissus quadrangularis
    "cissus quadrangularis": "Cissus quadrangularis L.",
    "hadjod": "Cissus quadrangularis L.",
    "veld grape": "Cissus quadrangularis L.",
    
    # Citrus aurantiifolia
    "citrus aurantiifolia": "Citrus aurantiifolia (Christm.) Swingle",
    "lime": "Citrus aurantiifolia (Christm.) Swingle",
    "key lime": "Citrus aurantiifolia (Christm.) Swingle",
    
    # Clerodendrum colebrookianum
    "clerodendrum colebrookianum": "Clerodendrum colebrookianum Walp.",
    
    # Clitoria ternatea
    "clitoria ternatea": "Clitoria ternatea L.",
    "butterfly pea": "Clitoria ternatea L.",
    "blue pea": "Clitoria ternatea L.",
    
    # Cloranthus elatior
    "cloranthus elatior": "Cloranthus elatior",
    
    # Crinum asiaticum
    "crinum asiaticum": "Crinum asiaticum Linn.",
    "poison bulb": "Crinum asiaticum Linn.",
    
    # Crinum viviparum
    "crinum viviparum": "Crinum viviparum (Lam.) R.Ansari & V.J.Nair",
    
    # Croton tiglium
    "croton tiglium": "Croton tiglium L.",
    "purging croton": "Croton tiglium L.",
    
    # Curculigo orchioides
    "curculigo orchioides": "Curculigo orchioides",
    "kali musli": "Curculigo orchioides",
    
    # Curcuma augustifolia
    "curcuma augustifolia": "Curcuma augustifolia",
    
    # Curcuma caesia
    "curcuma caesia": "Curcuma caesia Roxb.",
    "black turmeric": "Curcuma caesia Roxb.",
    "kali haldi": "Curcuma caesia Roxb.",
    
    # Curcuma zedoaria
    "curcuma zedoaria": "Curcuma zedoaria (Christm.) Roscoe",
    "white turmeric": "Curcuma zedoaria (Christm.) Roscoe",
    "zedoary": "Curcuma zedoaria (Christm.) Roscoe",
    
    # Cymbopogon nardus
    "cymbopogon nardus": "Cymbopogon nardus (L.) Rendle",
    "citronella": "Cymbopogon nardus (L.) Rendle",
    "citronella grass": "Cymbopogon nardus (L.) Rendle",
    
    # Datura metal
    "datura metal": "Datura metal",
    "datura metel": "Datura metal",
    "devil's trumpet": "Datura metal",
    
    # Dendrobium Nobile
    "dendrobium nobile": "Dendrobium Nobile",
    "noble dendrobium": "Dendrobium Nobile",
    
    # Desmodium gangeticum
    "desmodium gangeticum": "Desmodium gangeticum",
    
    # Eclipta prostrata
    "eclipta prostrata": "Eclipta prostrata",
    "bhringraj": "Eclipta prostrata",
    "false daisy": "Eclipta prostrata",
    
    # Elaeocarpus robustus
    "elaeocarpus robustus": "Elaeocarpus robustus Roxb.",
    
    # Elaeocarpus serratus
    "elaeocarpus serratus": "Elaeocarpus serratus",
    "rudraksha": "Elaeocarpus serratus",
    
    # Elettaria cardamomum
    "elettaria cardamomum": "Elettaria cardamomum (L.) Maton",
    "cardamom": "Elettaria cardamomum (L.) Maton",
    "green cardamom": "Elettaria cardamomum (L.) Maton",
    
    # Eryngium foetidum
    "eryngium foetidum": "Eryngium foetidum L.",
    "culantro": "Eryngium foetidum L.",
    "long coriander": "Eryngium foetidum L.",
    
    # Etlingera elatior
    "etlingera elatior": "Etlingera elatior (Jack) R.M.Sm.",
    "torch ginger": "Etlingera elatior (Jack) R.M.Sm.",
    
    # Euphorbia neriifolia
    "euphorbia neriifolia": "Euphorbia neriifolia L.",
    "indian spurge tree": "Euphorbia neriifolia L.",
    
    # Flemingia strobilifera
    "flemingia strobilifera": "Flemingia strobilifera (L.) W.T.Aiton",
    
    # Foeniculum vulgare
    "foeniculum vulgare": "Foeniculum vulgare",
    "fennel": "Foeniculum vulgare",
    
    # Garcinia cowa
    "garcinia cowa": "Garcinia cowa Roxb",
    
    # Garcinia morella
    "garcinia morella": "Garcinia morella (Gaertn.) Desr.",
    "mysore gamboge": "Garcinia morella (Gaertn.) Desr.",
    
    # Garcinia pedunculata
    "garcinia pedunculata": "Garcinia pedunculata Roxb. ex Buch.-Ham.",
    
    # Gardenia jasminoides
    "gardenia jasminoides": "Gardenia jasminoides,",
    "cape jasmine": "Gardenia jasminoides,",
    
    # Gymnema sylvestre
    "gymnema sylvestre": "Gymnema sylvestre (Retz.) R.Br. ex Sm.",
    "gurmar": "Gymnema sylvestre (Retz.) R.Br. ex Sm.",
    "sugar destroyer": "Gymnema sylvestre (Retz.) R.Br. ex Sm.",
    
    # Hedychium spicatum
    "hedychium spicatum": "Hedychium spicatum Buch.-Ham. ex Sm.",
    "spiked ginger lily": "Hedychium spicatum Buch.-Ham. ex Sm.",
    
    # Hellenia speciosa
    "hellenia speciosa": "Hellenia speciosa (J.Koenig) Govaerts",
    "costus speciosus": "Hellenia speciosa (J.Koenig) Govaerts",
    
    # Hibiscus rosasinensis
    "hibiscus rosasinensis": "Hibiscus rosasinensis",
    "hibiscus rosa-sinensis": "Hibiscus rosasinensis",
    "chinese hibiscus": "Hibiscus rosasinensis",
    
    # Homalomena aromatica
    "homalomena aromatica": "Homalomena aromatica Schott",
    
    # Houttuynia cordata
    "houttuynia cordata": "Houttuynia cordata",
    "fish mint": "Houttuynia cordata",
    
    # Hygrophila auriculata
    "hygrophila auriculata": "Hygrophila auriculata (Schumach.) Heine",
    "marsh barbel": "Hygrophila auriculata (Schumach.) Heine",
    
    # Jatropha curcas
    "jatropha curcas": "Jatropha curcas L.",
    "physic nut": "Jatropha curcas L.",
    
    # Justicia adhatoda
    "justicia adhatoda": "Justicia adhatoda L.",
    "malabar nut": "Justicia adhatoda L.",
    "vasaka": "Justicia adhatoda L.",
    
    # Kaempferia galanga
    "kaempferia galanga": "Kaempferia galanga",
    "sand ginger": "Kaempferia galanga",
    "kencur": "Kaempferia galanga",
    
    # Kalanchoe pinnata
    "kalanchoe pinnata": "Kalanchoe pinnata (Lam.) Pers.",
    "miracle leaf": "Kalanchoe pinnata (Lam.) Pers.",
    "air plant": "Kalanchoe pinnata (Lam.) Pers.",
    
    # Lasia spinosa
    "lasia spinosa": "Lasia spinosa (L.) ThwaitesMicrosoft.QuickAction.Bluetooth",
    
    # Lawsonia inermis
    "lawsonia inermis": "Lawsonia inermis L.",
    "henna": "Lawsonia inermis L.",
    "mehndi": "Lawsonia inermis L.",
    
    # Leucas aspera
    "leucas aspera": "Leucas aspera Link",
    "thumbai": "Leucas aspera Link",
    
    # Mentha arvensis
    "mentha arvensis": "Mentha arvensis L.",
    "corn mint": "Mentha arvensis L.",
    "wild mint": "Mentha arvensis L.",
    
    # Mesua ferrea
    "mesua ferrea": "Mesua ferrea L.",
    "iron wood": "Mesua ferrea L.",
    "cobra saffron": "Mesua ferrea L.",
    
    # Mimusops elengi
    "mimusops elengi": "Mimusops elengi L.",
    "spanish cherry": "Mimusops elengi L.",
    
    # Murraya koenigii
    "murraya koenigii": "Murraya koenigii (L.)",
    "curry leaf": "Murraya koenigii (L.)",
    "curry tree": "Murraya koenigii (L.)",
    
    # Nyctanthes arbor-tristis
    "nyctanthes arbor-tristis": "Nyctanthes arbor-tristis L.",
    "night jasmine": "Nyctanthes arbor-tristis L.",
    "parijat": "Nyctanthes arbor-tristis L.",
    
    # Ocimum americanum
    "ocimum americanum": "Ocimum americanum L.",
    "hoary basil": "Ocimum americanum L.",
    
    # Ocimum basilicum
    "ocimum basilicum": "Ocimum basilicum",
    "sweet basil": "Ocimum basilicum",
    "basil": "Ocimum basilicum",
    
    # Ocimum tenuiflorum
    "ocimum tenuiflorum": "Ocimum tenuiflorum",
    "holy basil": "Ocimum tenuiflorum",
    "tulsi": "Ocimum tenuiflorum",
    
    # Operculina turpethum
    "operculina turpethum": "Operculina turpethum (L.) Silva Manso",
    "turpeth": "Operculina turpethum (L.) Silva Manso",
    
    # Opuntia vulgaris
    "opuntia vulgaris": "Opuntia vulgaris Mill",
    "prickly pear": "Opuntia vulgaris Mill",
    
    # Oxalis corniculata
    "oxalis corniculata": "Oxalis corniculata L.",
    "creeping wood sorrel": "Oxalis corniculata L.",
    
    # Paederia foetida
    "paederia foetida": "Paederia foetida L.",
    "skunkvine": "Paederia foetida L.",
    
    # Paederia scandens
    "paederia scandens": "Paederia scandens",
    
    # Passiflora edulis
    "passiflora edulis": "Passiflora edulis Sims",
    "passion fruit": "Passiflora edulis Sims",
    
    # Persicaria chinensis
    "persicaria chinensis": "Persicaria chinensis (L.) H.Gross.",
    "chinese knotweed": "Persicaria chinensis (L.) H.Gross.",
    
    # Phlogacanthus thyrsiformis
    "phlogacanthus thyrsiformis": "Phlogacanthus thyrsiformis (Roxb. ex Hardw.) Mabb.",
    
    # Phyllanthus niruri
    "phyllanthus niruri": "Phyllanthus niruri L.",
    "stone breaker": "Phyllanthus niruri L.",
    "bhumyamalaki": "Phyllanthus niruri L.",
    
    # Picria fel-terrae
    "picria fel-terrae": "Picria fel-terrae Lour.",
    
    # Pimenta dioica
    "pimenta dioica": "Pimenta dioica (L.) Merr.",
    "allspice": "Pimenta dioica (L.) Merr.",
    
    # Piper longum
    "piper longum": "Piper longum L.",
    "long pepper": "Piper longum L.",
    "pippali": "Piper longum L.",
    
    # Piper nigrum
    "piper nigrum": "Piper nigrum L.",
    "black pepper": "Piper nigrum L.",
    "pepper": "Piper nigrum L.",
    
    # Plectranthus amboinicus
    "plectranthus amboinicus": "Plectranthus amboinicus (Lour.) Spreng.",
    "indian borage": "Plectranthus amboinicus (Lour.) Spreng.",
    "mexican mint": "Plectranthus amboinicus (Lour.) Spreng.",
    
    # Plumbago zeylanica
    "plumbago zeylanica": "Plumbago zeylanica L.",
    "ceylon leadwort": "Plumbago zeylanica L.",
    "chitrak": "Plumbago zeylanica L.",
    
    # Pogostemon benghalensis
    "pogostemon benghalensis": "Pogostemon benghalensis",
    
    # Psidium guajava
    "psidium guajava": "Psidium guajava L.",
    "guava": "Psidium guajava L.",
    
    # Rauvolfia serpentina
    "rauvolfia serpentina": "Rauvolfia serpentina Benth. ex Kurz",
    "indian snakeroot": "Rauvolfia serpentina Benth. ex Kurz",
    "sarpagandha": "Rauvolfia serpentina Benth. ex Kurz",
    
    # Rotheca serrata
    "rotheca serrata": "Rotheca serrata (L.) Steane & Mabb.",
    "clerodendrum serratum": "Rotheca serrata (L.) Steane & Mabb.",
    
    # Santalum album
    "santalum album": "Santalum album L.",
    "sandalwood": "Santalum album L.",
    
    # Sapindus mukorossi
    "sapindus mukorossi": "Sapindus mukorossi",
    "soapnut": "Sapindus mukorossi",
    "reetha": "Sapindus mukorossi",
    
    # Saraca asoca
    "saraca asoca": "Saraca asoca (Roxb.) Willd.",
    "ashoka tree": "Saraca asoca (Roxb.) Willd.",
    
    # Senna alata
    "senna alata": "Senna alata (L.) Roxb.",
    "candle bush": "Senna alata (L.) Roxb.",
    
    # Simarouba glauca
    "simarouba glauca": "Simarouba glauca DC.",
    "paradise tree": "Simarouba glauca DC.",
    
    # Smilax china
    "smilax china": "Smilax chinaL.",
    "china root": "Smilax chinaL.",
    
    # Solanum indicum
    "solanum indicum": "Solanum indicum",
    "indian nightshade": "Solanum indicum",
    
    # Spinacia oleracea
    "spinacia oleracea": "Spinacia oleracea",
    "spinach": "Spinacia oleracea",
    
    # Stephania japonica var. discolor
    "stephania japonica": "Stephania japonica var. discolor (Blume) Forman",
    "stephania japonica var. discolor": "Stephania japonica var. discolor (Blume) Forman",
    
    # Stereospermum chelonoides
    "stereospermum chelonoides": "Stereospermum chelonoides DC.",
    
    # Streblus asper
    "streblus asper": "Streblus asper Lour.",
    "toothbrush tree": "Streblus asper Lour.",
    
    # Syzygium cumini
    "syzygium cumini": "Syzygium cumini (L.) Skeels",
    "java plum": "Syzygium cumini (L.) Skeels",
    "jamun": "Syzygium cumini (L.) Skeels",
    
    # Tacca chantrieri
    "tacca chantrieri": "Tacca chantrieri André",
    "bat flower": "Tacca chantrieri André",
    
    # Terminalia arjuna
    "terminalia arjuna": "Terminalia arjuna",
    "arjuna": "Terminalia arjuna",
    
    # Terminalia bellirica
    "terminalia bellirica": "Terminalia bellirica (Gaertn.) Roxb.",
    "bahera": "Terminalia bellirica (Gaertn.) Roxb.",
    "bibhitaki": "Terminalia bellirica (Gaertn.) Roxb.",
    
    # Terminalia catappa
    "terminalia catappa": "Terminalia catappa L.",
    "indian almond": "Terminalia catappa L.",
    
    # Terminalia chebula
    "terminalia chebula": "Terminalia chebula",
    "haritaki": "Terminalia chebula",
    "black myrobalan": "Terminalia chebula",
    
    # Tinospora cordifolia
    "tinospora cordifolia": "Tinospora cordifolia",
    "guduchi": "Tinospora cordifolia",
    "giloy": "Tinospora cordifolia",
    
    # Vanilla planifolia
    "vanilla planifolia": "Vanilla planifolia",
    "vanilla": "Vanilla planifolia",
    
    # Vitex negundo
    "vitex negundo": "Vitex negundo L.",
    "five-leaved chaste tree": "Vitex negundo L.",
    "nirgundi": "Vitex negundo L.",
    
    # Zanthoxylum nitidum
    "zanthoxylum nitidum": "Zanthoxylum nitidum DC.",
    "shiny-leaf prickly ash": "Zanthoxylum nitidum DC.",
    
    # Zingiber officinale
    "zingiber officinale": "Zingiber officinale Rosc.",
    "ginger": "Zingiber officinale Rosc.",
    
    # Ziziphus jujuba
    "ziziphus jujuba": "Ziziphus jujuba Mill.",
    "jujube": "Ziziphus jujuba Mill.",
    "chinese date": "Ziziphus jujuba Mill.",
}


@app.route('/predict', methods=['POST'])
def identify_plant():
    # 1. Get the JSON data from the Flutter app's request
    data = request.get_json()

    if not data or 'image_url' not in data:
        return jsonify({"error": "No image_url provided"}), 400

    image_url = data.get('image_url')
    
    # (Optional) You can also get location data if your logic needs it
    # latitude = data.get('latitude')
    # longitude = data.get('longitude')
    
    # 2. Prepare the request for the PlantNet API
    # We send the image URL as a query parameter
    payload = {
        'api-key': PLANTNET_API_KEY,
        'images': [image_url],
        'organs': 'leaf' # You could also pass this from the app
    }

    try:
        # 3. Call the PlantNet API (using GET with params)
        response = requests.get(PLANTNET_API_URL, params=payload)
        response.raise_for_status() # Raises an exception for 4xx/5xx errors

        plantnet_data = response.json()

        # 4. Parse the PlantNet response
        if plantnet_data and plantnet_data.get('results'):
            
            # --- START: New mapping logic ---
            
            # Iterate through all results from PlantNet
            for result in plantnet_data.get('results', []):
                scientific_name_lower = result.get('species', {}).get('scientificNameWithoutAuthor', '').lower()
                
                # Check if this detected name is in our mapping
                if scientific_name_lower in PLANT_NAME_MAP:
                    # Found a match! Return our canonical name.
                    mapped_name = PLANT_NAME_MAP[scientific_name_lower]
                    score = result['score']
                    
                    return jsonify({
                        "name": mapped_name,
                        "score": score
                        # You can add more data here if needed
                    })
            
            # If no match was found in our map, fall back to the top result
            print("No mapped match found, using top result.")
            top_result = plantnet_data['results'][0]
            plant_name = top_result['species']['scientificNameWithoutAuthor']
            score = top_result['score']
            
            return jsonify({
                "name": plant_name,
                "score": score
                # You can add more data here if needed
            })
            # --- END: New mapping logic ---
            
        else:
            # PlantNet returned 200, but no results
            return jsonify({"error": "No results from PlantNet"}), 404

    except requests.exceptions.HTTPError as http_err:
        # Handle API errors from PlantNet
        return jsonify({"error": f"PlantNet API error: {http_err}", "details": response.text}), response.status_code
    except Exception as e:
        # Handle other internal errors
        return jsonify({"error": f"An internal error occurred: {str(e)}"}), 500

if __name__ == '__main__':
    # Run the app on port 5000 (default)
    # app.run(debug=True, port=5000)
    app.run(debug=True, host='0.0.0.0', port=5000)



