import 'package:yabnet/components/CustomProject.dart';
import 'package:yabnet/db_references/AppFile.dart';

class AppFileServiceData {
  final String appFileId;
  final String? localIdentity;
  final String? onlineDirectory;
  final String? onlineIndex;
  final String? iosData;
  final String? androidData;
  final String? fileType;
  final Map? collectionData;

  AppFileServiceData(
      this.appFileId,
      this.localIdentity,
      this.onlineDirectory,
      this.onlineIndex,
      this.iosData,
      this.androidData,
      this.fileType,
      this.collectionData);

  // toJson method to convert object to JSON
  Map<dynamic, dynamic> toJson() {
    return {
      'appFileId': appFileId,
      'localIdentity': localIdentity,
      'onlineDirectory': onlineDirectory,
      'onlineIndex': onlineIndex,
      'iosData': iosData,
      'androidData': androidData,
      'fileType': fileType,
      'collectionData': collectionData,
    };
  }

  // fromJson method to create an object from JSON
  factory AppFileServiceData.fromJson(Map<dynamic, dynamic> json) {
    return AppFileServiceData(
      json['appFileId'],
      json['localIdentity'],
      json['onlineDirectory'],
      json['onlineIndex'],
      json['iosData'],
      json['androidData'],
      json['fileType'],
      json['collectionData'],
    );
  }

  factory AppFileServiceData.fromOnline(Map<dynamic, dynamic> json) {
    return AppFileServiceData(
      json[dbReference(AppFile.id)],
      json[dbReference(AppFile.local_identity)],
      json[dbReference(AppFile.directory)],
      json[dbReference(AppFile.index_name)],
      json[dbReference(AppFile.ios_data)],
      json[dbReference(AppFile.android_data)],
      json[dbReference(AppFile.type)],
      json[dbReference(AppFile.collection_data)],
    );
  }

  // copyWith method to create a copy of the object with new values
  AppFileServiceData copyWith({
    String? appFileId,
    String? localIdentity,
    String? onlineDirectory,
    String? onlineIndex,
    String? iosData,
    String? androidData,
    String? fileType,
    Map? collectionData,
  }) {
    return AppFileServiceData(
      appFileId ?? this.appFileId,
      localIdentity ?? this.localIdentity,
      onlineDirectory ?? this.onlineDirectory,
      onlineIndex ?? this.onlineIndex,
      iosData ?? this.iosData,
      androidData ?? this.androidData,
      fileType ?? this.fileType,
      collectionData ?? this.collectionData,
    );
  }
}
