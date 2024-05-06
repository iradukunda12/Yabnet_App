import 'package:flutter/material.dart';

import '../../components/CustomClickableCard.dart';

class LanguageSettingCollection extends StatefulWidget {
  const LanguageSettingCollection({super.key});

  @override
  State<LanguageSettingCollection> createState() =>
      _LanguageSettingCollectionState();
}

class _LanguageSettingCollectionState extends State<LanguageSettingCollection> {
  String currentLanguage = "English (US)";

  void changeLanguage() {}

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Language
        Expanded(
          child: CustomClickableCard(
            showClickable: false,
            onTap: changeLanguage,
            defaultColor: Colors.white,
            clickedColor: Colors.grey.shade200,
            text: currentLanguage,
            textStyle:
                const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
