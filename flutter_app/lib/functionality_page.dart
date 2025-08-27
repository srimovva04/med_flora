// import 'dart:io'; // <-- CHANGE 1: Removed this import as it's not web-compatible.
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'plant_result.dart';
import 'config.dart';

class FunctionalityPage extends StatefulWidget {
  const FunctionalityPage({super.key});

  @override
  FunctionalityPageState createState() => FunctionalityPageState();
}

class FunctionalityPageState extends State<FunctionalityPage> {
  final picker = ImagePicker();
  final String cloudinaryUrl = "https://api.cloudinary.com/v1_1/dqshgffzl/image/upload";
  final String uploadPreset = "medleaf_preset";
  final String apiUrl = Config.apiUrl; // Your Flask endpoint

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      // Upload image to Cloudinary
      // <-- CHANGE 2: Pass the pickedFile object directly, not a File object.
      String? imageUrl = await _uploadToCloudinary(pickedFile);

      if (imageUrl != null) {
        // Fetch plant data from Flask API
        Map<String, dynamic>? plantData = await _fetchPlantData(imageUrl);

        if (plantData != null && mounted) { // Check if the widget is still in the tree
          // Navigate to result page with real plant data
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlantResultPage(
                plantData: plantData,
                imageUrl: imageUrl,
              ),
            ),
          );
        } else {
          _showErrorDialog("Failed to fetch plant details.");
        }
      } else {
        _showErrorDialog("Image upload failed. Please try again.");
      }
    }
  }

  // <-- CHANGE 3: Changed the parameter from 'File' to 'XFile'.
// In your functionality_page.dart file

Future<String?> _uploadToCloudinary(XFile pickedFile) async {
  try {
    final bytes = await pickedFile.readAsBytes();

    var request = http.MultipartRequest("POST", Uri.parse(cloudinaryUrl))
      ..fields['upload_preset'] = uploadPreset
      // --- FIX IS HERE ---
      // Add this line to force Cloudinary to convert the image to a JPG
      ..fields['format'] = 'jpg'
      ..files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: pickedFile.name,
      ));

    var response = await request.send();
    if (response.statusCode == 200) {
      var responseData = await response.stream.bytesToString();
      var jsonData = json.decode(responseData);
      return jsonData['secure_url'];
    } else {
      debugPrint("Cloudinary upload failed: ${response.statusCode}");
      final errorBody = await response.stream.bytesToString();
      debugPrint("Error body: $errorBody");
      return null;
    }
  } catch (e) {
    debugPrint("Cloudinary upload error: $e");
    return null;
  }
}

  Future<Map<String, dynamic>?> _fetchPlantData(String imageUrl) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"image_url": imageUrl}),
      );

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body); // Parsed JSON plant data
      } else {
        debugPrint("API error: ${response.body}");
        return null;
      }
    } catch (e) {
      debugPrint("API request failed: $e");
      return null;
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return; // Don't show dialog if the widget is disposed.
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Error"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF16666B),
        elevation: 5,
        centerTitle: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center, // Ensure it's centered
          children: const [
            Icon(
              Icons.settings_suggest_rounded, // Functionality-related icon
              color: Colors.white,
              size: 26,
            ),
            SizedBox(width: 8), // Adjust space a bit if needed
            Text(
              "Select Functionality",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E8F80), Color(0xFF16666B)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              SizedBox(
                width: 260,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 5,
                  ),
                  onPressed: () => _pickImage(ImageSource.camera),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.camera_alt, color: Color(0xFF16666B)),
                      SizedBox(width: 10),
                      Text(
                        'Scan Image',
                        style: TextStyle(
                          color: Color(0xFF16666B),
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: 260,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 5,
                  ),
                  onPressed: () => _pickImage(ImageSource.gallery),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.photo_library, color: Color(0xFF16666B)),
                      SizedBox(width: 10),
                      Text(
                        'Upload Image',
                        style: TextStyle(
                          color: Color(0xFF16666B),
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 50),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 30),
                child: Text(
                  "Detect plant variety, medicinal uses, and care tips instantly! ",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// hardcode image
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'plant_result.dart';
// import 'config.dart';
//
// class FunctionalityPage extends StatefulWidget {
//   const FunctionalityPage({super.key});
//
//   @override
//   FunctionalityPageState createState() => FunctionalityPageState();
// }
//
// class FunctionalityPageState extends State<FunctionalityPage> {
//   final picker = ImagePicker();
//   final String cloudinaryUrl = "https://api.cloudinary.com/v1_1/dqshgffzl/image/upload";
//   final String uploadPreset = "medleaf_preset";
//   final String apiUrl = Config.apiUrl; // Your Flask endpoint
//
//   Future<void> _pickImage(ImageSource source) async {
//     final pickedFile = await picker.pickImage(source: source);
//     if (pickedFile != null) {
//       File image = File(pickedFile.path);
//
//       // Upload image to Cloudinary
//       String? imageUrl = await _uploadToCloudinary(image);
//
//       if (imageUrl != null) {
//         // Fetch plant data from Flask API
//         Map<String, dynamic>? plantData = await _fetchPlantData(imageUrl);
//
//         if (plantData != null) {
//           // Navigate to result page with real plant data
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => PlantResultPage(
//                 plantData: plantData,
//                 imageUrl: imageUrl,
//               ),
//             ),
//           );
//         } else {
//           _showErrorDialog("Failed to fetch plant details.");
//         }
//       } else {
//         _showErrorDialog("Image upload failed. Please try again.");
//       }
//     }
//   }
//
//   Future<String?> _uploadToCloudinary(File image) async {
//     try {
//       var request = http.MultipartRequest("POST", Uri.parse(cloudinaryUrl))
//         ..fields['upload_preset'] = uploadPreset
//         ..files.add(await http.MultipartFile.fromPath('file', image.path));
//
//       var response = await request.send();
//       if (response.statusCode == 200) {
//         var responseData = await response.stream.bytesToString();
//         var jsonData = json.decode(responseData);
//         return jsonData['secure_url']; // Cloudinary image URL
//       } else {
//         print("Cloudinary upload failed: ${response.statusCode}");
//         return null;
//       }
//     } catch (e) {
//       print("Cloudinary upload error: $e");
//       return null;
//     }
//   }
//
//   Future<Map<String, dynamic>?> _fetchPlantData(String imageUrl) async {
//     try {
//       final response = await http.post(
//         Uri.parse("http://184.72.171.56:5000/predict"),
//         headers: {"Content-Type": "application/json"},
//         body: jsonEncode({
//           "image_url": "https://i.postimg.cc/J0N884BX/i-Stock-516064124.jpg" // ← use test URL here
//         }),
//       );
//
//       print("Response status: ${response.statusCode}");
//       print("Response body: ${response.body}");
//
//       if (response.statusCode == 200) {
//         return jsonDecode(response.body);
//       } else {
//         return null;
//       }
//     } catch (e) {
//       debugPrint("API request failed: $e");
//       return null;
//     }
//   }
//
//   // Future<Map<String, dynamic>?> _fetchPlantData(String imageUrl) async {
//   //   try {
//   //     final response = await http.post(
//   //       Uri.parse(apiUrl),
//   //       headers: {"Content-Type": "application/json"},
//   //       body: jsonEncode({"image_url": imageUrl}),
//   //     );
//   //     print("Response status: ${response.statusCode}");
//   //     print("Response body: ${response.body}");
//   //
//   //     if (response.statusCode == 200) {
//   //       return jsonDecode(response.body); // Parsed JSON plant data
//   //     } else {
//   //       print("API error: ${response.body}");
//   //       return null;
//   //     }
//   //   } catch (e) {
//   //     print("API request failed: $e");
//   //     return null;
//   //   }
//   // }
//
//   void _showErrorDialog(String message) {
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: const Text("Error"),
//           content: Text(message),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text("OK"),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: const Color(0xFF16666B),
//         elevation: 5,
//         centerTitle: true,
//         title: Row(
//           mainAxisAlignment: MainAxisAlignment.center, // Ensure it's centered
//           children: const [
//             Icon(
//               Icons.settings_suggest_rounded, // Functionality-related icon
//               color: Colors.white,
//               size: 26,
//             ),
//             SizedBox(width: 8), // Adjust space a bit if needed
//             Text(
//               "Select Functionality",
//               style: TextStyle(
//                 fontSize: 22,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.white,
//                 letterSpacing: 1.1,
//               ),
//             ),
//           ],
//         ),
//       ),
//
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             colors: [Color(0xFF1E8F80), Color(0xFF16666B)],
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//           ),
//         ),
//         child: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const SizedBox(height: 40),
//               SizedBox(
//                 width: 260,
//                 child: ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.white,
//                     padding: const EdgeInsets.symmetric(vertical: 15),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(30),
//                     ),
//                     elevation: 5,
//                   ),
//                   onPressed: () => _pickImage(ImageSource.camera),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: const [
//                       Icon(Icons.camera_alt, color: Color(0xFF16666B)),
//                       SizedBox(width: 10),
//                       Text(
//                         'Scan Image',
//                         style: TextStyle(
//                           color: Color(0xFF16666B),
//                           fontSize: 20,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 40),
//               SizedBox(
//                 width: 260,
//                 child: ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.white,
//                     padding: const EdgeInsets.symmetric(vertical: 15),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(30),
//                     ),
//                     elevation: 5,
//                   ),
//                   onPressed: () => _pickImage(ImageSource.gallery),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: const [
//                       Icon(Icons.photo_library, color: Color(0xFF16666B)),
//                       SizedBox(width: 10),
//                       Text(
//                         'Upload Image',
//                         style: TextStyle(
//                           color: Color(0xFF16666B),
//                           fontSize: 20,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 50),
//               const Padding(
//                 padding: EdgeInsets.symmetric(horizontal: 30),
//                 child: Text(
//                   "Detect plant variety, medicinal uses, and care tips instantly!",
//                   style: TextStyle(
//                     color: Colors.white70,
//                     fontSize: 16,
//                     fontStyle: FontStyle.italic,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
