import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';

import 'plant_result.dart';
import '../core/config.dart';
import '../specialist/add_plant_screen.dart';

class FunctionalityPage extends StatefulWidget {
  const FunctionalityPage({super.key});

  @override
  FunctionalityPageState createState() => FunctionalityPageState();
}

class FunctionalityPageState extends State<FunctionalityPage> {
  final picker = ImagePicker();
  final String cloudinaryUrl = "https://api.cloudinary.com/v1_1/dyi7dglot/image/upload";
  final String uploadPreset = "medleaf_preset";
  final String apiUrl = Config.apiUrl; // Your Flask endpoint

  /// --- Core Logic for Image Processing ---
  Future<void> _pickImage(ImageSource source) async {
    Position? location; // Variable to hold location data

    // If the source is the camera, get the current location first
    if (source == ImageSource.camera) {
      location = await _getCurrentLocation();
      if (location == null) {
        // Stop if the user cancels or fails to provide location
        return;
      }
    }

    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      String? originalUrl = await _uploadToCloudinary(pickedFile);

      if (originalUrl != null) {
        // Ensure the URL is in JPG format for the backend
        String transformedUrl = originalUrl.replaceFirst(
          '/upload/',
          '/upload/f_jpg/',
        );
        final finalUrl = transformedUrl.replaceAll(RegExp(r'\.[^/.]+$'), '.jpg');

        debugPrint("Final URL sent to backend: $finalUrl");

        // Fetch plant data, passing the location object (it will be null if from gallery)
        Map<String, dynamic>? plantData = await _fetchPlantData(
          finalUrl,
          location: location,
        );

        if (plantData != null && plantData.containsKey('name') && mounted) {
          final String plantName = "Aloe vera"; // Using placeholder as before

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlantResultPage(
                plantName: plantName,
                imageUrl: finalUrl,
              ),
            ),
          );
        } else {
          _showErrorDialog("Failed to identify the plant from the API.");
        }
      } else {
        _showErrorDialog("Image upload failed. Please try again.");
      }
    }
  }

  /// --- Helper Functions ---

  Future<String?> _uploadToCloudinary(XFile pickedFile) async {
    try {
      final bytes = await pickedFile.readAsBytes();
      var request = http.MultipartRequest("POST", Uri.parse(cloudinaryUrl))
        ..fields['upload_preset'] = uploadPreset
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

  Future<Map<String, dynamic>?> _fetchPlantData(String imageUrl, {Position? location}) async {
    try {
      final body = <String, dynamic>{
        'image_url': imageUrl,
      };

      // Add location data to the body if it exists
      if (location != null) {
        body['latitude'] = location.latitude;
        body['longitude'] = location.longitude;
        debugPrint("Sending location: ${location.latitude}, ${location.longitude}");
      }

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      debugPrint("Response status: ${response.statusCode}");
      debugPrint("Response body: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint("API error: ${response.body}");
        return null;
      }
    } catch (e) {
      debugPrint("API request failed: $e");
      return null;
    }
  }

  Future<Position?> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Check if location services are enabled on the device.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled && mounted) {
      // Location services are not enabled. Show a dialog to ask the user to enable them.
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Enable Location Services'),
          content: const Text('To geotag your plant, please enable location services in your device settings.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Open Settings'),
              onPressed: () {
                Navigator.of(context).pop();
                Geolocator.openLocationSettings(); // Opens device location settings
              },
            ),
          ],
        ),
      );
      return null; // Stop here, as user needs to enable services first.
    }

    // 2. Check for app-specific location permissions.
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission(); // Ask for permission
      if (permission == LocationPermission.denied) {
        // User explicitly denied the permission.
        _showErrorDialog("Location permission was denied. Geotagging is unavailable.");
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever && mounted) {
      // Permissions are denied forever. Show a dialog to ask the user to go to app settings.
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Location Permission Required'),
          content: const Text('Location permissions are permanently denied. Please enable them from your app settings to use this feature.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Open Settings'),
              onPressed: () {
                Navigator.of(context).pop();
                Geolocator.openAppSettings(); // Opens this app's specific settings
              },
            ),
          ],
        ),
      );
      return null;
    }

    // 3. If we get here, permissions are granted. Get the location.
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      _showErrorDialog("Failed to get current location: $e");
      return null;
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
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

  /// --- UI Build Method ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Plant'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      _buildOptionCard(
                        context: context,
                        icon: Icons.photo_library_outlined,
                        label: 'Upload Image',
                        onTap: () => _pickImage(ImageSource.gallery),
                      ),
                      const SizedBox(height: 20),
                      _buildOptionCard(
                        context: context,
                        icon: Icons.camera_alt_outlined,
                        label: 'Scan Image',
                        onTap: () => _pickImage(ImageSource.camera),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Icon(
                        Icons.eco_outlined,
                        size: 60,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'MedFlora',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Nourish. Discover. Grow',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => _pickImage(ImageSource.gallery),
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 30,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.cloud_upload_outlined,
              color: Colors.grey.shade500,
              size: 28,
            )
          ],
        ),
      ),
    );
  }
}


// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:geolocator/geolocator.dart';
//
// import 'plant_result.dart';
// import '../core/config.dart';
// import '../specialist/add_plant_screen.dart'; // <-- Added import for the new screen
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
//   final String cloudinaryUrl = "https://api.cloudinary.com/v1_1/dyi7dglot/image/upload";
//   final String uploadPreset = "medleaf_preset";
//   final String apiUrl = Config.apiUrl; // Your Flask endpoint
//
//   // --- MODIFIED: Logic for Image Processing ---
//
//   Future<void> _pickImage(ImageSource source) async {
//     Position? location; // NEW: Variable to hold location data
//
//     // NEW: Check if source is camera, then get location
//     if (source == ImageSource.camera) {
//       location = await _getCurrentLocation();
//       if (location == null) {
//         // User denied permission or location services are off
//         // The _getCurrentLocation function will show the error dialog
//         return; // Stop execution if location not found
//       }
//     }
//
//     final pickedFile = await picker.pickImage(source: source);
//     if (pickedFile != null) {
//       String? originalUrl = await _uploadToCloudinary(pickedFile);
//
//       if (originalUrl != null) {
//         // Ensure the URL is in JPG format for the backend
//         String transformedUrl = originalUrl.replaceFirst(
//           '/upload/',
//           '/upload/f_jpg/',
//         );
//         final finalUrl = transformedUrl.replaceAll(RegExp(r'\.[^/.]+$'), '.jpg');
//
//         debugPrint("Final URL sent to backend: $finalUrl");
//
//         // MODIFIED: Pass the location object (it will be null if from gallery)
//         Map<String, dynamic>? plantData = await _fetchPlantData(
//           finalUrl,
//           location: location,
//         );
//
//         if (plantData != null && plantData.containsKey('name') && mounted) {
//           // Extract the value from the 'name' key
//           // final String plantName = plantData['name'];
//           final String plantName = "Aloe vera"; // Using placeholder as before
//
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => PlantResultPage(
//                 plantName: plantName, // Pass the correct name
//                 imageUrl: finalUrl,
//               ),
//             ),
//           );
//         } else {
//           _showErrorDialog("Failed to identify the plant from the API.");
//         }
//       } else {
//         _showErrorDialog("Image upload failed. Please try again.");
//       }
//     }
//   }
//
//   Future<String?> _uploadToCloudinary(XFile pickedFile) async {
//     try {
//       final bytes = await pickedFile.readAsBytes();
//       var request = http.MultipartRequest("POST", Uri.parse(cloudinaryUrl))
//         ..fields['upload_preset'] = uploadPreset
//         ..files.add(http.MultipartFile.fromBytes(
//           'file',
//           bytes,
//           filename: pickedFile.name,
//         ));
//
//       var response = await request.send();
//       if (response.statusCode == 200) {
//         var responseData = await response.stream.bytesToString();
//         var jsonData = json.decode(responseData);
//         return jsonData['secure_url'];
//       } else {
//         debugPrint("Cloudinary upload failed: ${response.statusCode}");
//         final errorBody = await response.stream.bytesToString();
//         debugPrint("Error body: $errorBody");
//         return null;
//       }
//     } catch (e) {
//       debugPrint("Cloudinary upload error: $e");
//       return null;
//     }
//   }
//
//   // MODIFIED: Updated signature to accept optional location
//   Future<Map<String, dynamic>?> _fetchPlantData(String imageUrl, {Position? location}) async {
//     try {
//       // MODIFIED: Build the request body
//       final body = <String, dynamic>{
//         'image_url': imageUrl,
//       };
//
//       // MODIFIED: Add location data to the body if it exists
//       if (location != null) {
//         body['latitude'] = location.latitude;
//         body['longitude'] = location.longitude;
//         debugPrint("Sending location: ${location.latitude}, ${location.longitude}");
//       }
//
//       final response = await http.post(
//         Uri.parse(apiUrl),
//         headers: {"Content-Type": "application/json"},
//         body: jsonEncode(body), // MODIFIED: Send the new body
//       );
//
//       debugPrint("Response status: ${response.statusCode}");
//       debugPrint("Response body: ${response.body}");
//
//       if (response.statusCode == 200) {
//         return jsonDecode(response.body); // Parsed JSON plant data
//       } else {
//         debugPrint("API error: ${response.body}");
//         return null;
//       }
//     } catch (e) {
//       debugPrint("API request failed: $e");
//       return null;
//     }
//   }
//
//   void _showErrorDialog(String message) {
//     if (!mounted) return; // Don't show dialog if the widget is disposed.
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
//   // --- NEW: Helper function for getting location ---
//   Future<Position?> _getCurrentLocation() async {
//     bool serviceEnabled;
//     LocationPermission permission;
//
//     // Test if location services are enabled.
//     serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       _showErrorDialog("Location services are disabled. Please enable them.");
//       return null;
//     }
//
//     permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) {
//         _showErrorDialog("Location permissions are denied.");
//         return null;
//       }
//     }
//
//     if (permission == LocationPermission.deniedForever) {
//       // Permissions are denied forever, handle appropriately.
//       _showErrorDialog(
//           "Location permissions are permanently denied, we cannot request permissions.");
//       return null;
//     }
//
//     // When we reach here, permissions are granted and we can
//     // continue accessing the position of the device.
//     try {
//       return await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//       );
//     } catch (e) {
//       _showErrorDialog("Failed to get location: $e");
//       return null;
//     }
//   }
//
//   // --- UI Build Method (Unchanged) ---
//   @override
//   Widget build(BuildContext context) {
//     // Navigation function for the "Add Plant" page
//     void navigateToAddPlant() {
//       // Navigator.of(context).push(
//       //   MaterialPageRoute(builder: (context) => const AddPlantScreen()),
//       // );
//     }
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Select Plant'),
//         centerTitle: true,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 32.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             Expanded(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: [
//                   Column(
//                     children: [
//                       _buildOptionCard(
//                         context: context,
//                         icon: Icons.photo_library_outlined,
//                         label: 'Upload Image',
//                         onTap: () => _pickImage(ImageSource.gallery), // Wired to gallery
//                       ),
//                       const SizedBox(height: 20),
//                       _buildOptionCard(
//                         context: context,
//                         icon: Icons.camera_alt_outlined,
//                         label: 'Scan Image',
//                         onTap: () => _pickImage(ImageSource.camera), // Wired to camera
//                       ),
//                       const SizedBox(height: 20),
//                       // New "Add Plant" button with its own navigation
//                       // _buildOptionCard(
//                       //   context: context,
//                       //   icon: Icons.add_circle_outline,
//                       //   label: 'Add New Plant',
//                       //   onTap: navigateToAddPlant,
//                       // ),
//                     ],
//                   ),
//                   Column(
//                     children: [
//                       Icon(
//                         Icons.eco_outlined,
//                         size: 60,
//                         color: Theme.of(context).primaryColor,
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         'MedFlora',
//                         style: TextStyle(
//                           fontSize: 32,
//                           fontWeight: FontWeight.bold,
//                           color: Theme.of(context).primaryColor,
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         'Nourish. Discover. Grow',
//                         style: TextStyle(
//                           fontSize: 16,
//                           color: Colors.grey.shade600,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//             ElevatedButton(
//               // Default action is to upload from gallery
//               onPressed: () => _pickImage(ImageSource.gallery),
//               child: const Text('Continue'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // Helper widget for building the option cards, moved from the original example
//   Widget _buildOptionCard({
//     required BuildContext context,
//     required IconData icon,
//     required String label,
//     required VoidCallback onTap,
//   }) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
//         decoration: BoxDecoration(
//           color: Colors.white.withOpacity(0.5),
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(
//             color: Colors.grey.shade300,
//             width: 1.5,
//           ),
//         ),
//         child: Row(
//           children: [
//             Icon(
//               icon,
//               size: 30,
//               color: Theme.of(context).primaryColor,
//             ),
//             const SizedBox(width: 16),
//             Text(
//               label,
//               style: TextStyle(
//                 fontSize: 17,
//                 fontWeight: FontWeight.w600,
//                 color: Theme.of(context).primaryColor,
//               ),
//             ),
//             const Spacer(),
//             Icon(
//               label == 'Add New Plant'
//                   ? Icons.arrow_forward_ios
//                   : Icons.cloud_upload_outlined,
//               color: Colors.grey.shade500,
//               size: label == 'Add New Plant' ? 20 : 28,
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }




/// WORKING WITHOUT SCAN
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'plant_result.dart';
// import '../core/config.dart';
// import '../specialist/add_plant_screen.dart'; // <-- Added import for the new screen
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
//   final String cloudinaryUrl = "https://api.cloudinary.com/v1_1/dyi7dglot/image/upload";
//   final String uploadPreset = "medleaf_preset";
//   final String apiUrl = Config.apiUrl; // Your Flask endpoint
//
//   // --- Core Logic for Image Processing (Unchanged) ---
//
//   Future<void> _pickImage(ImageSource source) async {
//     final pickedFile = await picker.pickImage(source: source);
//     if (pickedFile != null) {
//       String? originalUrl = await _uploadToCloudinary(pickedFile);
//
//       if (originalUrl != null) {
//         // Ensure the URL is in JPG format for the backend
//         String transformedUrl = originalUrl.replaceFirst(
//           '/upload/',
//           '/upload/f_jpg/',
//         );
//         final finalUrl = transformedUrl.replaceAll(RegExp(r'\.[^/.]+$'), '.jpg');
//
//         debugPrint("Final URL sent to backend: $finalUrl");
//
//         // Fetch plant data using the corrected URL
//         Map<String, dynamic>? plantData = await _fetchPlantData(finalUrl);
//
//         if (plantData != null && plantData.containsKey('name') && mounted) {
//
//           // Extract the value from the 'name' key
//           // final String plantName = plantData['name'];
//           final String plantName = "Aloe vera";
//
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => PlantResultPage(
//                 plantName: plantName, // Pass the correct name
//                 imageUrl: finalUrl,
//               ),
//             ),
//           );
//           // --- MODIFICATION END ---
//         } else {
//           _showErrorDialog("Failed to identify the plant from the API.");
//         }
//       } else {
//         _showErrorDialog("Image upload failed. Please try again.");
//       }
//     }
//   }
//
//   Future<String?> _uploadToCloudinary(XFile pickedFile) async {
//     try {
//       final bytes = await pickedFile.readAsBytes();
//       var request = http.MultipartRequest("POST", Uri.parse(cloudinaryUrl))
//         ..fields['upload_preset'] = uploadPreset
//         ..files.add(http.MultipartFile.fromBytes(
//           'file',
//           bytes,
//           filename: pickedFile.name,
//         ));
//
//       var response = await request.send();
//       if (response.statusCode == 200) {
//         var responseData = await response.stream.bytesToString();
//         var jsonData = json.decode(responseData);
//         return jsonData['secure_url'];
//       } else {
//         debugPrint("Cloudinary upload failed: ${response.statusCode}");
//         final errorBody = await response.stream.bytesToString();
//         debugPrint("Error body: $errorBody");
//         return null;
//       }
//     } catch (e) {
//       debugPrint("Cloudinary upload error: $e");
//       return null;
//     }
//   }
//
//   Future<Map<String, dynamic>?> _fetchPlantData(String imageUrl) async {
//     try {
//       final response = await http.post(
//         Uri.parse(apiUrl),
//         headers: {"Content-Type": "application/json"},
//         body: jsonEncode({"image_url": imageUrl}),
//       );
//
//       debugPrint("Response status: ${response.statusCode}");
//       debugPrint("Response body: ${response.body}");
//
//       if (response.statusCode == 200) {
//         return jsonDecode(response.body); // Parsed JSON plant data
//       } else {
//         debugPrint("API error: ${response.body}");
//         return null;
//       }
//     } catch (e) {
//       debugPrint("API request failed: $e");
//       return null;
//     }
//   }
//
//   void _showErrorDialog(String message) {
//     if (!mounted) return; // Don't show dialog if the widget is disposed.
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
//   // --- NEW UI BUILD METHOD ---
//   @override
//   Widget build(BuildContext context) {
//     // Navigation function for the "Add Plant" page
//     void navigateToAddPlant() {
//       // Navigator.of(context).push(
//       //   MaterialPageRoute(builder: (context) => const AddPlantScreen()),
//       // );
//     }
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Select Plant'),
//         centerTitle: true,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 32.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             Expanded(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: [
//                   Column(
//                     children: [
//                       _buildOptionCard(
//                         context: context,
//                         icon: Icons.photo_library_outlined,
//                         label: 'Upload Image',
//                         onTap: () => _pickImage(ImageSource.gallery), // Wired to gallery
//                       ),
//                       const SizedBox(height: 20),
//                       _buildOptionCard(
//                         context: context,
//                         icon: Icons.camera_alt_outlined,
//                         label: 'Scan Image',
//                         onTap: () => _pickImage(ImageSource.camera), // Wired to camera
//                       ),
//                       const SizedBox(height: 20),
//                       // New "Add Plant" button with its own navigation
//                       // _buildOptionCard(
//                       //   context: context,
//                       //   icon: Icons.add_circle_outline,
//                       //   label: 'Add New Plant',
//                       //   onTap: navigateToAddPlant,
//                       // ),
//                     ],
//                   ),
//                   Column(
//                     children: [
//                       Icon(
//                         Icons.eco_outlined,
//                         size: 60,
//                         color: Theme.of(context).primaryColor,
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         'MedFlora',
//                         style: TextStyle(
//                           fontSize: 32,
//                           fontWeight: FontWeight.bold,
//                           color: Theme.of(context).primaryColor,
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         'Nourish. Discover. Grow',
//                         style: TextStyle(
//                           fontSize: 16,
//                           color: Colors.grey.shade600,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//             ElevatedButton(
//               // Default action is to upload from gallery
//               onPressed: () => _pickImage(ImageSource.gallery),
//               child: const Text('Continue'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // Helper widget for building the option cards, moved from the original example
//   Widget _buildOptionCard({
//     required BuildContext context,
//     required IconData icon,
//     required String label,
//     required VoidCallback onTap,
//   }) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
//         decoration: BoxDecoration(
//           color: Colors.white.withOpacity(0.5),
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(
//             color: Colors.grey.shade300,
//             width: 1.5,
//           ),
//         ),
//         child: Row(
//           children: [
//             Icon(
//               icon,
//               size: 30,
//               color: Theme.of(context).primaryColor,
//             ),
//             const SizedBox(width: 16),
//             Text(
//               label,
//               style: TextStyle(
//                 fontSize: 17,
//                 fontWeight: FontWeight.w600,
//                 color: Theme.of(context).primaryColor,
//               ),
//             ),
//             const Spacer(),
//             Icon(
//               label == 'Add New Plant'
//                   ? Icons.arrow_forward_ios
//                   : Icons.cloud_upload_outlined,
//               color: Colors.grey.shade500,
//               size: label == 'Add New Plant' ? 20 : 28,
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }
//


/// old ui
// // import 'dart:io'; // <-- CHANGE 1: Removed this import as it's not web-compatible.
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
//   final String cloudinaryUrl = "https://api.cloudinary.com/v1_1/dyi7dglot/image/upload";
//   final String uploadPreset = "medleaf_preset";
//   final String apiUrl = Config.apiUrl; // Your Flask endpoint
//
//   // Future<void> _pickImage(ImageSource source) async {
//   //   final pickedFile = await picker.pickImage(source: source);
//   //   if (pickedFile != null) {
//   //     // Upload image to Cloudinary
//   //     // <-- CHANGE 2: Pass the pickedFile object directly, not a File object.
//   //     String? imageUrl = await _uploadToCloudinary(pickedFile);
//   //
//   //     if (imageUrl != null) {
//   //       // Fetch plant data from Flask API
//   //       String jpgImageUrl = imageUrl.replaceFirst(
//   //         '/upload/',
//   //         '/upload/f_jpg/',
//   //       );
//   //       print("Uploaded image jpgURL: $jpgImageUrl");
//   //
//   //       Map<String, dynamic>? plantData = await _fetchPlantData(imageUrl);
//   //
//   //       if (plantData != null && mounted) { // Check if the widget is still in the tree
//   //         // Navigate to result page with real plant data
//   //         Navigator.push(
//   //           context,
//   //           MaterialPageRoute(
//   //             builder: (context) => PlantResultPage(
//   //               plantData: plantData,
//   //               imageUrl: jpgImageUrl,
//   //             ),
//   //           ),
//   //         );
//   //       } else {
//   //         _showErrorDialog("Failed to fetch plant details.");
//   //       }
//   //     } else {
//   //       _showErrorDialog("Image upload failed. Please try again.");
//   //     }
//   //   }
//   // }
//
//   // In your _pickImage function
//
//   Future<void> _pickImage(ImageSource source) async {
//     final pickedFile = await picker.pickImage(source: source);
//     if (pickedFile != null) {
//       String? originalUrl = await _uploadToCloudinary(pickedFile);
//
//       if (originalUrl != null) {
//         // --- START: NEW URL FIX ---
//
//         // 1. Insert the f_jpg transformation to ensure it serves a JPG
//         String transformedUrl = originalUrl.replaceFirst(
//           '/upload/',
//           '/upload/f_jpg/',
//         );
//
//         // 2. Replace the final file extension (like .avif or .png) with .jpg
//         // This uses a regular expression to find the last dot and change the extension
//         final finalUrl = transformedUrl.replaceAll(RegExp(r'\.[^/.]+$'), '.jpg');
//
//         print("Final URL sent to backend: $finalUrl");
//
//         // --- END: NEW URL FIX ---
//
//         // Fetch plant data using the corrected URL
//         Map<String, dynamic>? plantData = await _fetchPlantData(finalUrl);
//
//         if (plantData != null && mounted) {
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => PlantResultPage(
//                 plantData: plantData,
//                 imageUrl: finalUrl, // Use the corrected URL here too
//               ),
//             ),
//           );
//         } else {
//           _showErrorDialog("Failed to fetch plant details from API.");
//         }
//       } else {
//         _showErrorDialog("Image upload failed. Please try again.");
//       }
//     }
//   }
//
//   // <-- CHANGE 3: Changed the parameter from 'File' to 'XFile'.
// // In your functionality_page.dart file
//
// Future<String?> _uploadToCloudinary(XFile pickedFile) async {
//   try {
//     final bytes = await pickedFile.readAsBytes();
//
//     var request = http.MultipartRequest("POST", Uri.parse(cloudinaryUrl))
//       ..fields['upload_preset'] = uploadPreset
//       // --- FIX IS HERE ---
//       // Add this line to force Cloudinary to convert the image to a JPG
//       // ..fields['format'] = 'jpg'
//       ..files.add(http.MultipartFile.fromBytes(
//         'file',
//         bytes,
//         filename: pickedFile.name,
//       ));
//
//     var response = await request.send();
//     if (response.statusCode == 200) {
//       var responseData = await response.stream.bytesToString();
//       var jsonData = json.decode(responseData);
//       return jsonData['secure_url'];
//     } else {
//       debugPrint("Cloudinary upload failed: ${response.statusCode}");
//       final errorBody = await response.stream.bytesToString();
//       debugPrint("Error body: $errorBody");
//       return null;
//     }
//   } catch (e) {
//     debugPrint("Cloudinary upload error: $e");
//     return null;
//   }
// }
//
//   Future<Map<String, dynamic>?> _fetchPlantData(String imageUrl) async {
//     try {
//       final response = await http.post(
//         Uri.parse(apiUrl),
//         headers: {"Content-Type": "application/json"},
//         body: jsonEncode({"image_url": imageUrl}),
//       );
//
//       print("Response status: ${response.statusCode}");
//       print("Response body: ${response.body}");
//
//       if (response.statusCode == 200) {
//         return jsonDecode(response.body); // Parsed JSON plant data
//       } else {
//         debugPrint("API error: ${response.body}");
//         return null;
//       }
//     } catch (e) {
//       debugPrint("API request failed: $e");
//       return null;
//     }
//   }
//
//   void _showErrorDialog(String message) {
//     if (!mounted) return; // Don't show dialog if the widget is disposed.
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
//                   "Detect plant variety, medicinal uses, and care tips instantly! ",
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
