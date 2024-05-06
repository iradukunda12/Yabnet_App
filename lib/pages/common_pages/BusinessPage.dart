import 'package:flutter/material.dart';

import '../../components/FeatureComingSoonWidget.dart';

class BusinessPage extends StatefulWidget {
  const BusinessPage({super.key});

  @override
  State<BusinessPage> createState() => _BusinessPageState();
}

class _BusinessPageState extends State<BusinessPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SafeArea(
          child: FeatureComingSoon(
            showOkayButton: false,
            icon: Icons.business_outlined,
            featureName: 'Business Connect',
            description:
                'Ultimate networking solution designed to elevate your professional connections to new heights.',
          ),
        ),
      ),
    );
  }
}
