import 'package:flutter/material.dart';

import '../../config/app_colors.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final headlineStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        );
    final subheadStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        );
    const bodyStyle = TextStyle(
      fontSize: 15,
      height: 1.6,
      color: AppColors.textSecondary,
    );
    final legalHeadStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          fontStyle: FontStyle.italic,
          color: AppColors.textPrimary,
        );
    const legalBodyStyle = TextStyle(
      fontSize: 15,
      height: 1.6,
      fontStyle: FontStyle.italic,
      color: AppColors.textSecondary,
    );

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
          'Terms & Conditions',
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
            Text('Terms & Conditions', style: headlineStyle),
            const SizedBox(height: 24),
            Text('Welcome to Insites', style: subheadStyle),
            const SizedBox(height: 12),
            const Text(
              'Terms and Conditions are effective from 1st September 2016.',
              style: bodyStyle,
            ),
            const SizedBox(height: 12),
            const Text(
              'Our Terms & Conditions are in easy to understand \u2018Plain English\u2019 in standard black font and \u2018Legalese\u2019 in black indented italics.',
              style: bodyStyle,
            ),
            const SizedBox(height: 28),
            Text('Plain-English Terms & Conditions', style: subheadStyle),
            const SizedBox(height: 12),
            const Text(
              'Please review our terms as you must agree to them in order to use Insites Websites, Products and Services. If you are using Insites on behalf of your business or company, make sure you are allowed to agree to our Terms and Conditions.',
              style: bodyStyle,
            ),
            const SizedBox(height: 12),
            const Text(
              'We may change our Terms and Conditions from time to time. If we do, we will post a note on our website or email you.',
              style: bodyStyle,
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Legal Terms & Conditions', style: subheadStyle),
                  const SizedBox(height: 12),
                  const Text(
                    'Please Read Carefully Before Using This Website: The following Terms and Conditions (\u201cTerms and Conditions\u201d) govern your use of the Insites Website (the \u201cSite\u201d) and the Insites web-based products (\u201cProduct\u201d), application integration and data linking service accessed through the Site (\u201cService\u201d), each of which are operated by Insites (\u201cInsites\u201d). By using the Site and/or Product and/or the Service, you irrevocably agree that such use is subject to these Terms and Conditions. If you do not agree to these Terms and Conditions, you may not use the Site, the Product or the Service. If you are entering into these Terms and Conditions on behalf of an entity, you represent that you have the actual authority to bind such entity to these Terms and Conditions.',
                    style: legalBodyStyle,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Insites expressly reserves the right to modify the Terms and Conditions at any time in its sole discretion and without prior notice to you, by including such alteration and/or modification in these Terms and Conditions, along with a notice of the effective date of such modified Terms and Conditions. Any continued use by you of the Site or the Service after the posting of such modified Terms and Conditions shall be deemed to indicate your irrevocable agreement to such modified Terms and Conditions. Accordingly, if at any time you do not agree to be subject to any modified Terms and Conditions, you may no longer use the Site, Product or Service.',
                    style: legalBodyStyle,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
