import 'package:flutter/material.dart';

// --- THEME COLORS ---
const Color kScaffoldBackground = Color(0xFFF7F9F5);
const Color kPrimaryTextColor = Color(0xFF3D5245);
const Color kCardBackground = Color(0xFFEBF1E8);
const Color kIconBackground = Color(0xFFDDE6D9);
const Color kTextFieldBackground = Color(0xFFF0F0F0);

class VerificationDetailPage extends StatefulWidget {
  final Map<String, dynamic> submissionData;

  const VerificationDetailPage({super.key, required this.submissionData});

  @override
  State<VerificationDetailPage> createState() => _VerificationDetailPageState();
}

class _VerificationDetailPageState extends State<VerificationDetailPage> {
  final TextEditingController _nameController = TextEditingController();

  // --- UPDATED DUMMY DATA WITH DIRECT WIKIMEDIA LINKS ---
  final List<Map<String, String>> similarSuggestions = const [
    {
      'name': 'Ocimum Tenuiflorum',
      'score': '85%',
      'imageUrl': 'https://upload.wikimedia.org/wikipedia/commons/e/e0/Gc31_tagetes_erecta_and_patula.jpg',
    },
    {
      'name': 'Mentha Spicata',
      'score': '79%',
      'imageUrl': 'https://upload.wikimedia.org/wikipedia/commons/e/e0/Gc31_tagetes_erecta_and_patula.jpg',
    },
    {
      'name': 'Azadirachta Indica',
      'score': '75%',
      'imageUrl': 'https://upload.wikimedia.org/wikipedia/commons/e/e0/Gc31_tagetes_erecta_and_patula.jpg',
    },
    {
      'name': 'Centella Asiatica',
      'score': '72%',
      'imageUrl': 'https://upload.wikimedia.org/wikipedia/commons/e/e0/Gc31_tagetes_erecta_and_patula.jpg',
    },
    {
      'name': 'Withania Somnifera',
      'score': '68%',
      'imageUrl': 'https://upload.wikimedia.org/wikipedia/commons/e/e0/Gc31_tagetes_erecta_and_patula.jpg',
    },
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kScaffoldBackground,
      appBar: AppBar(
        title: Text(
          'Verify #${widget.submissionData['id']}',
          style: const TextStyle(color: kPrimaryTextColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: kScaffoldBackground,
        foregroundColor: kPrimaryTextColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: Image.network(
                widget.submissionData['imageUrl'],
                height: 250,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 250,
                  color: Colors.grey[200],
                  child: const Icon(Icons.image_not_supported_outlined, size: 50, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ADD THIS NEW CODE:
            Row(
              children: [
                Expanded(
                  child: _buildInfoBlock(
                    icon: Icons.label_important_outline,
                    title: 'Predicted Name',
                    description: widget.submissionData['submittedName'],
                  ),
                ),
                const SizedBox(width: 12), // Use width for horizontal spacing
                Expanded(
                  child: _buildInfoBlock(
                    icon: Icons.star_border_rounded,
                    title: 'Score',
                    description: widget.submissionData['score'],
                  ),
                ),
              ],
            ),

            _buildSuggestionsSection(),
            const SizedBox(height: 32),

            TextField(
              controller: _nameController,
              cursorColor: kPrimaryTextColor,
              decoration: InputDecoration(
                labelText: 'Enter Correct Plant Name',
                labelStyle: const TextStyle(color: kPrimaryTextColor),
                filled: true,
                fillColor: kTextFieldBackground,
                prefixIcon: const Icon(Icons.eco_outlined, color: kPrimaryTextColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: const BorderSide(color: kPrimaryTextColor),
                ),
              ),
            ),
            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: () {
                final enteredName = _nameController.text;
                if (enteredName.isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Verification submitted for: $enteredName')),
                  );
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryTextColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              child: const Text('Submit Verification', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBlock({required IconData icon, required String title, required String description}) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: kCardBackground,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: kIconBackground,
            foregroundColor: kPrimaryTextColor,
            child: Icon(icon),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: kPrimaryTextColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(color: kPrimaryTextColor, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildSuggestionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'AI Suggestions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimaryTextColor),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: ListView.separated(
            clipBehavior: Clip.none,
            scrollDirection: Axis.horizontal,
            itemCount: similarSuggestions.length,
            itemBuilder: (context, index) {
              final suggestion = similarSuggestions[index];
              return _buildSuggestionItem(
                imageUrl: suggestion['imageUrl']!,
                name: suggestion['name']!,
                score: suggestion['score']!,
              );
            },
            separatorBuilder: (context, index) => const SizedBox(width: 12),
          ),
        ),
      ],
    );
  }

  // --- WIDGET WITH CLICKABLE FUNCTIONALITY ---
  Widget _buildSuggestionItem({required String imageUrl, required String name, required String score}) {
    return SizedBox(
      width: 130,
      child: Card(
        color: kCardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            setState(() {
              _nameController.text = name;
            });
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(Icons.image_not_supported_outlined, color: Colors.grey),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimaryTextColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Match: $score',
                      style: TextStyle(color: kPrimaryTextColor.withOpacity(0.7), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
  // Widget _buildSuggestionsSection() {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       const Text(
  //         'Similar Suggestions',
  //         style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimaryTextColor),
  //       ),
  //       const SizedBox(height: 12),
  //       SizedBox(
  //         height: 180,
  //         child: ListView.separated(
  //           clipBehavior: Clip.none,
  //           scrollDirection: Axis.horizontal,
  //           itemCount: similarSuggestions.length,
  //           itemBuilder: (context, index) {
  //             final suggestion = similarSuggestions[index];
  //             return _buildSuggestionItem(
  //               imageUrl: suggestion['imageUrl']!,
  //               name: suggestion['name']!,
  //               score: suggestion['score']!,
  //             );
  //           },
  //           separatorBuilder: (context, index) => const SizedBox(width: 12),
  //         ),
  //       ),
  //     ],
  //   );
  // }
  //
  // Widget _buildSuggestionItem({required String imageUrl, required String name, required String score}) {
  //   return SizedBox(
  //     width: 130,
  //     child: Container(
  //       decoration: BoxDecoration(
  //         color: kCardBackground,
  //         borderRadius: BorderRadius.circular(12.0),
  //       ),
  //       clipBehavior: Clip.antiAlias,
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Expanded(
  //             child: Image.network(
  //               imageUrl,
  //               fit: BoxFit.cover,
  //               width: double.infinity,
  //               errorBuilder: (context, error, stackTrace) => const Center(
  //                 child: Icon(Icons.image_not_supported_outlined, color: Colors.grey),
  //               ),
  //             ),
  //           ),
  //           Padding(
  //             padding: const EdgeInsets.all(8.0),
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 Text(
  //                   name,
  //                   style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimaryTextColor),
  //                   maxLines: 1,
  //                   overflow: TextOverflow.ellipsis,
  //                 ),
  //                 const SizedBox(height: 2),
  //                 Text(
  //                   'Match: $score',
  //                   style: TextStyle(color: kPrimaryTextColor.withOpacity(0.7), fontSize: 12),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }


