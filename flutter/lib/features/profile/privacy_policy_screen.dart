import 'package:flutter/material.dart';

import '../../config/app_colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const String _content = '''
This is the privacy notice of Insites. In this document, \u201cwe\u201d or \u201cus\u201d refers to Insites Platform Pty Ltd (ABN: 83 653 729 349).

Our registered office is at 11 Wilson Street, South Yarra VIC 3141 Australia.

This is a notice to tell you our policy about all information that we record about you. It covers both information that could identify you and information that could not.

We are extremely committed to protect your privacy and confidentiality. We understand that all users of our website are quite rightly concerned to know that their data will not be used for any purpose unintended by them, and will not accidentally fall into the hands of a third party. Our policy is both specific and strict. It complies with Australian law. If you think our policy falls short of your expectations or that we are failing to abide by our policy, do please tell us.

We regret that if there are one or more points below with which you are not happy, your only recourse is to leave our website immediately.

Except as set out below, we do not share, or sell, or disclose to a third party, any personally identifiable information collected at this site.

Here is a list of the information we collect from you, either through our website or because you give it to us in some other way, and why it is necessary to collect it:''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.white, size: 30),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Privacy Policy',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 20),
            const Text(
              _content,
              style: TextStyle(
                fontSize: 15,
                height: 1.6,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
