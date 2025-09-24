import 'package:flutter/material.dart';
import 'plant_details.dart'; // Using the original details page import

class PlantResultPage extends StatefulWidget {
  final Map<String, dynamic> plantData;
  final String imageUrl;

  const PlantResultPage({
    super.key,
    required this.plantData,
    required this.imageUrl,
  });

  @override
  State<PlantResultPage> createState() => _PlantResultPageState();
}

class _PlantResultPageState extends State<PlantResultPage> {
  // State variables to control the visibility of description and locations
  bool showDescription = false;
  bool showLocations = false;

  @override
  Widget build(BuildContext context) {
    // Safely access data with fallback values
    final String plantName = widget.plantData["name"] ?? "Unknown Plant";
    final String plantDescription = widget.plantData["description"] ?? "No description available.";
    final String plantLocations = widget.plantData["locations_in_india"] ?? "Locations not specified.";

    return Scaffold(
      appBar: AppBar(
        // The simpler AppBar from the new design
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Text(
              'Plant Identified',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const Spacer(flex: 1),
            Center(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
               child: CircleAvatar(
                 radius: 100,
                 // A background color is good practice, visible if the image is transparent or fails
                 backgroundColor: Colors.grey.shade200,
                 child: ClipOval(
                   child: Image.network(
                     widget.imageUrl,
                     // Ensure the image fills the circle
                     fit: BoxFit.cover,
                     width: 200,  // 2 * radius
                     height: 200, // 2 * radius

                     // This builder shows a widget while the image is loading
                     loadingBuilder: (context, child, loadingProgress) {
                       if (loadingProgress == null) return child; // Return the image if it's loaded
                       return const Center(child: CircularProgressIndicator());
                     },

                     // This builder returns a widget to display when an error occurs
                     errorBuilder: (context, error, stackTrace) {
                       return const Icon(Icons.error, color: Colors.red, size: 50);
                     },
                   ),
                 ),
               ),
              ),
            ),
            const SizedBox(height: 24),
            Text.rich(
              TextSpan(
                text: 'Predicted Plant: ',
                style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
                children: [
                  TextSpan(
                    // Displaying the dynamic plant name
                    text: plantName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      showDescription = !showDescription;
                      if (showDescription) showLocations = false; // Close other tab
                    });
                  },
                  child: _buildInfoChip(icon: Icons.description_outlined, label: 'Description'),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      showLocations = !showLocations;
                      if (showLocations) showDescription = false; // Close other tab
                    });
                  },
                  child: _buildInfoChip(icon: Icons.location_on_outlined, label: 'Found in'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Conditionally display the description
            if (showDescription)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  plantDescription, // Dynamic description
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade700, height: 1.4),
                ),
              ),
            // Conditionally display the locations
            if (showLocations)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  plantLocations, // Dynamic locations
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade700, height: 1.4),
                ),
              ),
            const Spacer(flex: 2),
            ElevatedButton(
              onPressed: () {
                // Navigate to the original PlantDetailsPage, passing the data
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => PlantDetailsPage(plantData: widget.plantData),
                  ),
                );
              },
              child: const Text('View More Information'), // Changed text for clarity
            ),
            const Spacer(flex: 1),
          ],
        ),
      ),
    );
  }

  // Helper widget from the new design
  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
          )
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600, size: 20),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: Colors.grey.shade700)),
        ],
      ),
    );
  }
}



/// old ui
// import 'package:flutter/material.dart';
// import 'plant_details.dart';
//
// class PlantResultPage extends StatelessWidget {
//   final Map<String, dynamic> plantData;
//   final String imageUrl;
//
//   const PlantResultPage({super.key, required this.plantData, required this.imageUrl});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       // Background gradient with smooth transition
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         title: const Text('Plant Identification', style: TextStyle(color: Colors.white)),
//         backgroundColor: const Color(0xFF16666B),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.info_outline),
//             onPressed: () {
//               // You can implement additional info functionality here
//             },
//           ),
//         ],
//         flexibleSpace: Container(
//           decoration: const BoxDecoration(
//             gradient: LinearGradient(
//               colors: [Color(0xFF1E8F80), Color(0xFF16666B)],
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//             ),
//           ),
//         ),
//       ),
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [Color(0xFF4DB6AC), Color(0xFF1E8F80)],
//           ),
//         ),
//         padding: const EdgeInsets.all(20.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Plant Image with rounded corners and shadow effect
//             Center(
//               child: Container(
//                 width: 250,
//                 height: 250,
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(20),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black26,
//                       blurRadius: 12,
//                       spreadRadius: 3,
//                     ),
//                   ],
//                 ),
//                 child: ClipRRect(
//                   borderRadius: BorderRadius.circular(20),
//                   child: Image.network(
//                     imageUrl,
//                     fit: BoxFit.cover,
//                     loadingBuilder: (context, child, loadingProgress) {
//                       if (loadingProgress == null) return child;
//                       return const Center(child: CircularProgressIndicator());
//                     },
//                     errorBuilder: (context, error, stackTrace) {
//                       return const Center(
//                         child: Icon(Icons.broken_image, size: 100, color: Colors.red),
//                       );
//                     },
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 20),
//
//             // Text for plant data with Card styling for better readability
//             Expanded(
//               child: SingleChildScrollView(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Plant Name with icon
//                     Card(
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(15),
//                       ),
//                       color: Colors.white,
//                       elevation: 5,
//                       margin: const EdgeInsets.only(bottom: 15),
//                       child: Padding(
//                         padding: const EdgeInsets.all(10),
//                         child: Row(
//                           children: [
//                             const Icon(Icons.local_florist, color: Color(0xFF16666B), size: 30),
//                             const SizedBox(width: 10),
//                             Expanded(
//                               child: Text(
//                                 'Predicted Plant: ${plantData["name"]}',
//                                 style: const TextStyle(
//                                   color: Color(0xFF16666B),
//                                   fontSize: 20,
//                                   fontWeight: FontWeight.bold,
//                                   letterSpacing: 1.5,
//                                 ),
//                                 maxLines: 2, // Limiting it to 2 lines, can increase or remove based on need
//                                 overflow: TextOverflow.ellipsis,  // Use ellipsis for text overflow
//                                 softWrap: true, // Allows text to wrap to the next line
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//
//
//                     // Description with icon
//                     Card(
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(15),
//                       ),
//                       color: Colors.white,
//                       elevation: 5,
//                       margin: const EdgeInsets.only(bottom: 15),
//                       child: Padding(
//                         padding: const EdgeInsets.all(10),
//                         child: Row(
//                           children: [
//                             const Icon(Icons.description, color: Color(0xFF16666B), size: 30),
//                             const SizedBox(width: 10),
//                             Expanded(
//                               child: Text(
//                                 'Description: ${plantData["description"]}',
//                                 style: const TextStyle(
//                                   color: Color(0xFF16666B),
//                                   fontSize: 18,
//                                   height: 1.5,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//
//                     // Location with icon
//                     Card(
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(15),
//                       ),
//                       color: Colors.white,
//                       elevation: 5,
//                       margin: const EdgeInsets.only(bottom: 30),
//                       child: Padding(
//                         padding: const EdgeInsets.all(10),
//                         child: Row(
//                           children: [
//                             const Icon(Icons.location_on, color: Color(0xFF16666B), size: 30),
//                             const SizedBox(width: 10),
//                             Expanded(
//                               child: Text(
//                                 'Found In: ${plantData["locations_in_india"]}',
//                                 style: const TextStyle(
//                                   color: Color(0xFF16666B),
//                                   fontSize: 18,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//
//             // Button with enhanced styling: gradient background
//             Center(
//               child: SizedBox(
//                 width: 250,
//                 child: ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     foregroundColor: Colors.white,
//                     backgroundColor: const Color(0xFF16666B),
//                     padding: const EdgeInsets.symmetric(vertical: 15),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(30),
//                     ),
//                     elevation: 6,
//                   ),
//                   onPressed: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => PlantDetailsPage(plantData: plantData),
//                       ),
//                     );
//                   },
//                   child: const Text(
//                     'View More Information',
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
