import 'package:flutter/material.dart';

class FeatureComingSoon extends StatefulWidget {
  final IconData icon;
  final String featureTitle;
  final String featureName;
  final String description;
  final bool showOkayButton;
  final VoidCallback? onOkayPressed;

  const FeatureComingSoon({
    required this.icon,
    required this.featureName,
    required this.description,
    this.showOkayButton = true,
    this.onOkayPressed,
    this.featureTitle = 'Coming Soon!!!',
  });

  @override
  State<FeatureComingSoon> createState() => _FeatureComingSoonState();
}

class _FeatureComingSoonState extends State<FeatureComingSoon> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      elevation: 0.0,
      backgroundColor: Colors.transparent,
      child: contentBox(context),
    );
  }

  Widget contentBox(BuildContext context) {
    return Stack(
      children: <Widget>[
        Container(
          padding: EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            color: Colors.white,
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(widget.icon, size: 50, color: Colors.green),
              SizedBox(height: 20),
              Text(
                widget.featureTitle,
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Text(
                widget.featureName,
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Text(
                widget.description,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14.0),
              ),
              SizedBox(height: 20),
              if (widget.showOkayButton)
                ElevatedButton(
                  onPressed:
                      widget.onOkayPressed ?? () => Navigator.of(context).pop(),
                  child: Text('Okay'),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
