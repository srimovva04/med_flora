import 'package:flutter/material.dart';
import 'verification_details.dart'; // Import the detail page

class VerificationListPage extends StatelessWidget {
  const VerificationListPage({super.key});

  // --- DUMMY DATA FOR THE SUBMISSION LIST ---
  // This list creates the entries that appear on the page.
  final List<Map<String, dynamic>> submissions = const [
    {
      'id': '101',
      'submittedName': 'Tulsi',
      'date': '2025-10-17',
      'score': '92%',
      'imageUrl': 'https://plus.unsplash.com/premium_photo-1671070369255-a459b1a85a4a?q=80&w=2071&auto=format&fit=crop',
    },
    {
      'id': '102',
      'submittedName': 'Unknown Leaf',
      'date': '2025-10-16',
      'score': '88%',
      'imageUrl': 'https://images.unsplash.com/photo-1629828328229-37a5e0108502?q=80&w=2070&auto=format&fit=crop',
    },
    {
      'id': '103',
      'submittedName': 'Ashwagandha?',
      'date': '2025-10-16',
      'score': '76%',
      'imageUrl': 'https://images.unsplash.com/photo-1595152772236-4b8156157154?q=80&w=1974&auto=format&fit=crop',
    },
    {
      'id': '104',
      'submittedName': 'Mint Leaf',
      'date': '2025-10-15',
      'score': '95%',
      'imageUrl': 'https://images.unsplash.com/photo-1620075436900-a8865646f901?q=80&w=2070&auto=format&fit=crop',
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Submissions'),
      ),
      body: ListView.builder(
        // Use padding on the ListView for better spacing
        padding: const EdgeInsets.all(16.0),
        itemCount: submissions.length,
        itemBuilder: (context, index) {
          final submission = submissions[index];
          // Use Padding for spacing between cards
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Card( // This card uses the global theme from main.dart
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(submission['imageUrl']),
                  radius: 25,
                ),
                title: Text(
                  submission['submittedName'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Submitted on: ${submission['date']}'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                onTap: () {
                  // Navigate to the detail page, passing the selected submission's data
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VerificationDetailPage(submissionData: submission),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}