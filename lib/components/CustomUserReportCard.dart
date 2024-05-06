import 'package:flutter/material.dart';

import '../../components/CustomOnClickContainer.dart';

class CustomUserReportCard extends StatelessWidget {
  final Color defaultColor;
  final Color onClickedColor;
  final double borderRadius;
  final Function()? onTap;
  final String reportPurpose;
  final String reportCreatedAt;
  final String reportCreatedBy;
  final String reportClosedBy;
  final String reportClosedAt;
  final bool reportStatus;

  const CustomUserReportCard({
    super.key,
    required this.defaultColor,
    required this.onClickedColor,
    this.borderRadius = 15,
    this.onTap,
    required this.reportPurpose,
    required this.reportCreatedAt,
    required this.reportCreatedBy,
    required this.reportClosedBy,
    required this.reportClosedAt,
    required this.reportStatus,
  });

  @override
  Widget build(BuildContext context) {
    String getStatusText() {
      return reportStatus ? "Active" : "Closed";
    }

    return CustomOnClickContainer(
      onTap: onTap,
      defaultColor: defaultColor,
      clickedColor: onClickedColor,
      borderRadius: BorderRadius.circular(borderRadius),
      padding: const EdgeInsets.all(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Stock Report for",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            reportPurpose,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text(
                "Status:",
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                getStatusText(),
                style: TextStyle(
                  color: !reportStatus ? Colors.red : Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildInfoRow("Opened", reportCreatedAt, reportCreatedBy),
          const SizedBox(height: 16),
          _buildInfoRow(
              "Closed",
              reportClosedAt.isNotEmpty ? reportClosedAt : "N/A",
              reportClosedBy.isNotEmpty ? reportClosedBy : "N/A"),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String title, String date, String createdBy) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Divider(
          thickness: 2,
          color: Colors.white,
        ),
        Text(
          "By: $createdBy\n",
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
        Text(
          "At: $date",
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
