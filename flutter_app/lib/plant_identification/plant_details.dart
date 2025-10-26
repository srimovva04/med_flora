import 'package:flutter/material.dart';

import '../specialist/availability_map.dart';

class PlantDetailsPage extends StatelessWidget {
  final Map<String, dynamic> plantData;

  const PlantDetailsPage({super.key, required this.plantData});

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;
    final Color cardBackgroundColor = Colors.green.shade50.withOpacity(0.6);

    // --- DATA EXTRACTION MAPPED TO THE NEW EXCEL STRUCTURE ---

    // Use 'Common Name' for the title, with a fallback to 'Scientific Name'
    final String plantName = plantData['Common Name']?.toString() ??
        plantData['Scientific Name']?.toString() ??
        'Plant Details';

    // Data for the 'General Info' tab
    final String scientificName = plantData['Scientific Name']?.toString() ?? 'N/A';
    final String kingdom = plantData['Kingdom']?.toString() ?? 'N/A';
    final String classificationInfo = 'Kingdom: $kingdom\nScientific Name: $scientificName';

    // Create a concise description, as the therapeutic uses are very long
    final String description = 'A plant from the $kingdom kingdom, scientifically known as $scientificName. '
        'It is widely recognized for its extensive therapeutic applications and rich phytochemical profile.';

    // Data for the 'Therapeutic Use' tab
    final String therapeuticUses = plantData['Therapeutic Uses']?.toString() ?? 'No therapeutic uses listed.';

    // Data for the 'Growing & Location' tab
    final String locations = plantData['Statewise Availability']?.toString() ?? 'No locations specified.';
    const String growingConditions = 'Detailed growing conditions for this plant are not available in the database.';

    // Data for the 'Composition' tab
    final String phytochemicals = plantData['Phytochemicals']?.toString() ?? 'Composition not available.';


    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(plantName),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          bottom: TabBar(
            isScrollable: true,
            labelColor: primaryColor,
            unselectedLabelColor: Colors.grey.shade600,
            indicatorColor: primaryColor,
            indicatorSize: TabBarIndicatorSize.label,
            indicatorWeight: 3.0,
            tabs: const [
              Tab(text: 'General Info'),
              Tab(text: 'Therapeutic Use'),
              Tab(text: 'Location'),
              Tab(text: 'Composition'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // 1. General Info Tab
            SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Repurposed this card to show classification info
                  _buildSimpleCard(
                    context: context,
                    icon: Icons.eco,
                    title: 'Classification',
                    content: classificationInfo,
                    backgroundColor: cardBackgroundColor,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: primaryColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      description, // Displaying the generated summary
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        height: 1.5,
                        fontSize: 15,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            // 2. Therapeutic Use Tab
            SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBenefitCard(
                    context: context,
                    icon: Icons.favorite_border_outlined,
                    title: 'Therapeutic Uses',
                    content: therapeuticUses, // Displaying the full list of uses
                    backgroundColor: cardBackgroundColor,
                  ),
                ],
              ),
            ),
            // 3. Location Tab
            SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLocationCard(
                    context: context,
                    icon: Icons.location_on,
                    title: 'Statewise Availability in India',
                    content: locations,
                    backgroundColor: cardBackgroundColor,
                  ),
                  const SizedBox(height: 24),
                  // ADD THIS BUTTON
                  Center(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.map_outlined),
                      label: const Text('View on Map'),
                      onPressed: () {
                        // Navigate to the new map page
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => AvailabilityMapPage(
                              plantName: plantName,
                              locations: locations,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildLocationCard(
                    context: context,
                    icon: Icons.wb_sunny,
                    title: 'Growing Conditions',
                    content: 'Detailed growing conditions are not available.', // Fallback
                    backgroundColor: cardBackgroundColor,
                  ),
                ],
              ),
            ),

            // SingleChildScrollView(
            //   padding: const EdgeInsets.all(20.0),
            //   child: Column(
            //     crossAxisAlignment: CrossAxisAlignment.start,
            //     children: [
            //       _buildLocationCard(
            //         context: context,
            //         icon: Icons.location_on,
            //         title: 'Statewise Availability in India',
            //         content: locations, // Displaying locations
            //         backgroundColor: cardBackgroundColor,
            //       ),
            //       const SizedBox(height: 16),
            //       _buildLocationCard(
            //         context: context,
            //         icon: Icons.wb_sunny,
            //         title: 'Growing Conditions',
            //         content: growingConditions, // Fallback message
            //         backgroundColor: cardBackgroundColor,
            //       ),
            //     ],
            //   ),
            // ),
            // 4. Composition Tab
            SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSimpleCard(
                    context: context,
                    icon: Icons.science_outlined,
                    title: 'Phytochemicals',
                    content: phytochemicals, // Displaying phytochemicals
                    backgroundColor: cardBackgroundColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper Widgets (No changes needed here, they are reusable) ---

  Widget _buildSimpleCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String content,
    required Color backgroundColor,
  }) {
    // ... This widget remains unchanged
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Theme.of(context).primaryColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  content,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    height: 1.5,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String content,
    required Color backgroundColor,
  }) {
    // ... This widget remains unchanged
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.green.shade600, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  content,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    height: 1.5,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String content,
    required Color backgroundColor,
  }) {
    // ... This widget remains unchanged
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.blue.shade600, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  content,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    height: 1.5,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}



// import 'package:flutter/material.dart';
// import 'package:latlong2/latlong.dart';
// import 'package:flutter_map/flutter_map.dart';
//
// class PlantDetailsPage extends StatelessWidget {
//   final Map<String, dynamic> plantData;
//
//   const PlantDetailsPage({super.key, required this.plantData});
//
//
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             colors: [Color(0xFF1E8F80), Color(0xFF16666B)],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//         ),
//         child: SafeArea(
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: [
//                 // AppBar like custom title
//                 Row(
//                   children: [
//                     IconButton(
//                       icon: const Icon(Icons.arrow_back, color: Colors.white),
//                       onPressed: () {
//                         Navigator.pop(context);
//                       },
//                     ),
//                     const SizedBox(width: 10),
//                     const Text(
//                       'Plant Details',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 25,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ],
//                 ),
//
//                 const SizedBox(height: 20),
//
//                 // Plant name
//                 Text(
//                   plantData["name"] ?? "Plant Name",
//                   style: const TextStyle(
//                     fontSize: 22,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.white,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//
//                 const SizedBox(height: 20),
//
//                 // Buttons List
//                 Expanded(
//                   child: ListView(
//                     children: [
//                       _buildButton(context, 'General Info', GeneralInfoPage(plantData: plantData)),
//                       _buildButton(context, 'View on Map', MapPage(plantData: plantData)),
//                       _buildButton(context, 'Medicinal Uses', MedicinalUsesPage(plantData: plantData)),
//                       _buildButton(context, 'Plant Characteristics', PlantCharacteristicsPage(plantData: plantData)),
//                       _buildButton(context, 'Soil & Fertilizer Info', SoilFertilizerPage(plantData: plantData)),
//                     ],
//                   ),
//                 ),
//                 const Padding(
//                   padding: EdgeInsets.symmetric(horizontal: 30),
//                   child: Text(
//                     "Discover interesting information about your plant, from its characteristics to its medicinal uses and care requirements!",
//                     style: TextStyle(
//                       color: Colors.white70,
//                       fontSize: 16,
//                       fontStyle: FontStyle.italic,
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
//                 ),
//
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildButton(BuildContext context, String title, Widget page) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8.0),
//       child: ElevatedButton.icon(
//         style: ElevatedButton.styleFrom(
//           backgroundColor: Colors.white,
//           padding: const EdgeInsets.symmetric(vertical: 18),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(20),
//           ),
//           elevation: 8,
//         ),
//         onPressed: () {
//           Navigator.push(context, MaterialPageRoute(builder: (context) => page));
//         },
//         icon: _getIconForButton(title),
//         label: Text(
//           title,
//           style: const TextStyle(
//             color: Color(0xFF16666B),
//             fontSize: 18,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//       ),
//     );
//   }
//
//   Icon _getIconForButton(String title) {
//     switch (title) {
//       case 'General Info':
//         return const Icon(Icons.info_outline, color: Color(0xFF16666B));
//       case 'View on Map':
//         return const Icon(Icons.map, color: Color(0xFF16666B));
//       case 'Medicinal Uses':
//         return const Icon(Icons.local_hospital, color: Color(0xFF16666B));
//       case 'Plant Characteristics':
//         return const Icon(Icons.grass, color: Color(0xFF16666B));
//       case 'Soil & Fertilizer Info':
//         return const Icon(Icons.nature_people, color: Color(0xFF16666B));
//       default:
//         return const Icon(Icons.help_outline, color: Color(0xFF16666B));
//     }
//   }
// }
//
// /// ---------------- General Info Page ---------------- ///
// class GeneralInfoPage extends StatelessWidget {
//   final Map<String, dynamic> plantData;
//
//   const GeneralInfoPage({super.key, required this.plantData});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("General Info"),
//         flexibleSpace: Container(
//           decoration: const BoxDecoration(
//             gradient: LinearGradient(
//               colors: [
//                 Color(0xFF0F9D58), // Green
//                 Color(0xFF0F9D58), // Blue
//               ],
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//             ),
//           ),
//         ),
//       ),
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             colors: [
//               Color(0xFF0F9D58), // Green
//               Color(0xFF4285F4), // Blue
//             ],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//         ),
//         child: ListView(
//           padding: const EdgeInsets.all(16),
//           children: [
//             _buildSectionTitle("Uses"),
//             _buildInfoCard(plantData["uses"]),
//
//             const SizedBox(height: 20),
//
//             _buildSectionTitle("Varieties"),
//             _buildInfoCard(plantData["varieties"]),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildSectionTitle(String title) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8.0),
//       child: Text(
//         title,
//         style: const TextStyle(
//           fontSize: 22,
//           fontWeight: FontWeight.bold,
//           color: Colors.white, // White title text
//         ),
//       ),
//     );
//   }
//
//   Widget _buildInfoCard(String? content) {
//     return Card(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       color: Colors.white.withOpacity(0.9), // White card with slight opacity
//       elevation: 8,
//       margin: const EdgeInsets.symmetric(vertical: 8),
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Text(
//           content ?? "Information not available.",
//           style: const TextStyle(
//             fontSize: 16,
//             color: Colors.black87,
//             height: 1.5,
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// /// ---------------- Map Page ---------------- ///
// class MapPage extends StatelessWidget {
//   final Map<String, dynamic> plantData;
//
//   const MapPage({super.key, required this.plantData});
//
//   @override
//   Widget build(BuildContext context) {
//     List<dynamic>? coordinates = plantData["coordinates"];
//
//     if (coordinates == null || coordinates.length < 2) {
//       return Scaffold(
//         appBar: AppBar(title: const Text("Map")),
//         body: const Center(child: Text("Coordinates not available.")),
//       );
//     }
//
//     double latitude = coordinates[0];
//     double longitude = coordinates[1];
//
//     return Scaffold(
//       appBar: AppBar(title: const Text("Plant Location on Map")),
//       body: FlutterMap(
//         options: MapOptions(
//           initialCenter: LatLng(latitude, longitude),
//           initialZoom: 10,
//         ),
//         children: [
//           TileLayer(
//             urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
//             subdomains: const ['a', 'b', 'c'],
//           ),
//           MarkerLayer(
//             markers: coordinates.map<Marker>((coord) {
//               double lat = coord[0];
//               double lng = coord[1];
//               return Marker(
//                 point: LatLng(lat, lng),
//                 width: 50,
//                 height: 50,
//                 child: const Icon(
//                     Icons.location_pin, color: Colors.red, size: 45),
//               );
//             }).toList(),
//           ),
//
//         ],
//       ),
//     );
//   }
// }
// /// ---------------- Medicinal Uses Page ---------------- ///
// class MedicinalUsesPage extends StatelessWidget {
//   final Map<String, dynamic> plantData;
//
//   const MedicinalUsesPage({super.key, required this.plantData});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Medicinal Uses"),
//         flexibleSpace: Container(
//           decoration: const BoxDecoration(
//             gradient: LinearGradient(
//               colors: [
//                 Color(0xFF0F9D58), // Green
//                 Color(0xFF0F9D58), // Blue
//               ],
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//             ),
//           ),
//         ),
//       ),
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             colors: [
//               Color(0xFF0F9D58), // Same green
//               Color(0xFF4285F4), // Same blue
//             ],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//         ),
//         child: ListView(
//           padding: const EdgeInsets.all(16),
//           children: [
//             _buildSectionTitle("Natural Medicinal Benefits"),
//             _buildInfoCard(plantData["natural_medicinal_benefits"]),
//
//             const SizedBox(height: 20),
//
//             _buildSectionTitle("Pharmaceutical Usage"),
//             _buildInfoCard(plantData["pharmaceutical_usage"]),
//
//             const SizedBox(height: 20),
//
//             _buildSectionTitle("Pharmaceutical Uses"),
//             _buildInfoCard(plantData["pharmaceutical_uses"]),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildSectionTitle(String title) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8.0),
//       child: Text(
//         title,
//         style: const TextStyle(
//           fontSize: 22,
//           fontWeight: FontWeight.bold,
//           color: Colors.white, // Now white to look good on gradient
//         ),
//       ),
//     );
//   }
//
//   Widget _buildInfoCard(String? content) {
//     return Card(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       color: Colors.white.withOpacity(0.9), // Light frosted effect
//       elevation: 8,
//       margin: const EdgeInsets.symmetric(vertical: 8),
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Text(
//           content ?? "Information not available.",
//           style: const TextStyle(
//             fontSize: 16,
//             color: Colors.black87,
//             height: 1.5,
//           ),
//         ),
//       ),
//     );
//   }
// }
// /// ---------------- Plant Characteristics Page ---------------- ///
// class PlantCharacteristicsPage extends StatelessWidget {
//   final Map<String, dynamic> plantData;
//
//   const PlantCharacteristicsPage({super.key, required this.plantData});
//
//   @override
//   Widget build(BuildContext context) {
//     Map<String, dynamic>? climate = plantData["climate"];
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Plant Characteristics"),
//         flexibleSpace: Container(
//           decoration: const BoxDecoration(
//             gradient: LinearGradient(
//               colors: [
//                 Color(0xFF0F9D58), // Green
//                 Color(0xFF0F9D58), // Blue
//               ],
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//             ),
//           ),
//         ),
//       ),
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             colors: [
//               Color(0xFF0F9D58), // Green
//               Color(0xFF4285F4), // Blue
//             ],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//         ),
//         child: ListView(
//           padding: const EdgeInsets.all(16),
//           children: [
//             _buildSectionTitle("Plant Height"),
//             _buildInfoCard(plantData["plant_height"]),
//
//             const SizedBox(height: 20),
//
//             _buildSectionTitle("Climate"),
//             _buildInfoCard(
//               """
//               Rainfall: ${climate?["rainfall"] ?? "N/A"}
//               Temperature: ${climate?["temperature"] ?? "N/A"}
//               """,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildSectionTitle(String title) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8.0),
//       child: Text(
//         title,
//         style: const TextStyle(
//           fontSize: 22,
//           fontWeight: FontWeight.bold,
//           color: Colors.white, // White title text
//         ),
//       ),
//     );
//   }
//
//   Widget _buildInfoCard(String? content) {
//     return Card(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       color: Colors.white.withOpacity(0.9), // White card with slight opacity
//       elevation: 8,
//       margin: const EdgeInsets.symmetric(vertical: 8),
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Text(
//           content ?? "Information not available.",
//           style: const TextStyle(
//             fontSize: 16,
//             color: Colors.black87,
//             height: 1.5,
//           ),
//         ),
//       ),
//     );
//   }
// }
// /// ---------------- Soil & Fertilizer Info Page ---------------- ///
// class SoilFertilizerPage extends StatelessWidget {
//   final Map<String, dynamic> plantData;
//
//   const SoilFertilizerPage({super.key, required this.plantData});
//
//   @override
//   Widget build(BuildContext context) {
//     Map<String, dynamic>? soilConditions = plantData["soil_conditions"];
//     Map<String, dynamic>? harvesting = plantData["harvesting"];
//     Map<String, dynamic>? irrigation = plantData["irrigation"];
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Soil & Fertilizer Info"),
//         flexibleSpace: Container(
//           decoration: const BoxDecoration(
//             gradient: LinearGradient(
//               colors: [
//                 Color(0xFF0F9D58), // Green
//                 Color(0xFF0F9D58), // Blue
//               ],
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//             ),
//           ),
//         ),
//       ),
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             colors: [
//               Color(0xFF0F9D58), // Green
//               Color(0xFF4285F4), // Blue
//             ],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//         ),
//         child: ListView(
//           padding: const EdgeInsets.all(16),
//           children: [
//             _buildSectionTitle("Soil Conditions"),
//             _buildInfoCard(
//               """
//               • Best Conditions: ${soilConditions?["best_conditions"] ?? "N/A"}
//               • pH: ${soilConditions?["pH"] ?? "N/A"}
//               • Type: ${soilConditions?["type"] ?? "N/A"}
//               """,
//             ),
//             const SizedBox(height: 20),
//
//             _buildSectionTitle("Fertilizer Requirement"),
//             _buildInfoCard(plantData["fertilizer_requirement"]),
//             const SizedBox(height: 20),
//
//             _buildSectionTitle("Harvesting"),
//             _buildInfoCard(
//               """
//               • Frequency: ${harvesting?["frequency"] ?? "N/A"}
//               • Method: ${harvesting?["method"] ?? "N/A"}
//               """,
//             ),
//             const SizedBox(height: 20),
//
//             _buildSectionTitle("Irrigation"),
//             _buildInfoCard(
//               """
//               • Rainy Season: ${irrigation?["rainy"] ?? "N/A"}
//               • Summer Season: ${irrigation?["summer"] ?? "N/A"}
//               • Winter Season: ${irrigation?["winter"] ?? "N/A"}
//               """,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildSectionTitle(String title) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8.0),
//       child: Text(
//         title,
//         style: const TextStyle(
//           fontSize: 22,
//           fontWeight: FontWeight.bold,
//           color: Colors.white, // White title text
//         ),
//       ),
//     );
//   }
//
//   Widget _buildInfoCard(String? content) {
//     return Card(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       color: Colors.white.withOpacity(0.9), // White card with slight opacity
//       elevation: 8,
//       margin: const EdgeInsets.symmetric(vertical: 8),
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Align(
//           alignment: Alignment.topLeft, // Left align the content
//           child: Text(
//             content ?? "Information not available.",
//             style: const TextStyle(
//               fontSize: 16,
//               color: Colors.black87,
//               height: 1.5,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
//
//
//
// /// ---------------- Detail Page Template ---------------- ///
// class DetailPage extends StatelessWidget {
//   final String title;
//   final List<Widget> contentWidgets;
//
//   const DetailPage({super.key, required this.title, required this.contentWidgets});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF1F8E9),
//       appBar: AppBar(
//         title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
//         backgroundColor: const Color(0xFF1E8F80),
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
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: ListView(
//           children: contentWidgets,
//         ),
//       ),
//     );
//   }
// }
//
