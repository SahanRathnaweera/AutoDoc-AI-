import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AutoDoc AI Privacy Policy',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Last updated: November 2026'),
            SizedBox(height: 16),
            Text(
              '1. Information We Collect',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 6),
            Text(
              'We collect account details used for sign-in and vehicle inspection data or images that you choose to submit within AutoDoc AI.',
            ),
            SizedBox(height: 14),
            Text(
              '2. How We Use Your Data',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 6),
            Text(
              'Your data is used to generate inspection reports, maintain app preferences (such as theme, reminders, and biometric lock), and improve service reliability.',
            ),
            SizedBox(height: 14),
            Text(
              '3. Security & Storage',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 6),
            Text(
              'We apply reasonable safeguards to protect your inspection history and account session data.',
            ),
            SizedBox(height: 14),
            Text(
              '4. Contact Us',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 6),
            Text(
              'For questions about this privacy policy or your data, contact the AutoDoc AI support team.',
            ),
          ],
        ),
      ),
    );
  }
}
