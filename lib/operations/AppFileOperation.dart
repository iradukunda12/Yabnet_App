import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart';
import 'package:path_provider/path_provider.dart';
import 'package:postgrest/src/postgrest_builder.dart';
import 'package:postgrest/src/types.dart';
import 'package:supabase/src/supabase_stream_builder.dart';
import 'package:yabnet/components/CustomProject.dart';
import 'package:yabnet/supabase/SupabaseConfig.dart';

import '../data_notifiers/AppFileServiceData.dart';
import '../db_references/AppFile.dart';

class AppFileOperation {
  static String fileFolder = "APP_FILE";
  static Future<Directory> directory = getApplicationDocumentsDirectory();

  String getAppFileBucketPath(AppFileServiceData appFileServiceData) {
    if (appFileServiceData.onlineDirectory == null ||
        appFileServiceData.onlineIndex == null ||
        appFileServiceData.fileType == null) return '';
    final filePath =
        "${appFileServiceData.onlineDirectory}/${appFileServiceData.onlineIndex}";
    return SupabaseConfig.client.storage
        .from(dbReference(AppFile.bucket))
        .getPublicUrl(filePath);
  }

  PostgrestTransformBuilder<PostgrestMap?> fetchParticularAppFile(
      AppFile appFile) {
    return SupabaseConfig.client
        .from(dbReference(AppFile.table))
        .select()
        .eq(dbReference(AppFile.local_identity), dbReference(appFile))
        .maybeSingle();
  }

  SupabaseStreamFilterBuilder fetchAppDataStream() {
    return SupabaseConfig.client
        .from(dbReference(AppFile.table))
        .stream(primaryKey: [dbReference(AppFile.id)]);
  }

  PostgrestFilterBuilder<PostgrestList> fetchAppData() {
    return SupabaseConfig.client.from(dbReference(AppFile.table)).select();
  }

  Future<Uint8List?> downloadAppFile(
      AppFileServiceData appFileServiceData) async {
    if (appFileServiceData.onlineDirectory == null ||
        appFileServiceData.onlineIndex == null ||
        appFileServiceData.fileType == null) return null;
    final filePath =
        "${appFileServiceData.onlineDirectory}/${appFileServiceData.onlineIndex}.${appFileServiceData.fileType}";

    try {
      // Convert the response body to a Uint8List
      final response = await get(Uri.parse(SupabaseConfig.client.storage
          .from(dbReference(AppFile.bucket))
          .getPublicUrl(filePath)));
      Uint8List byteList = response.bodyBytes;
      return byteList;
    } catch (e, s) {
      // If an error occurred during the download, throw an error
      throw Exception('Failed to download file: $e $s');
    }
  }

  Future<File> saveFile(String baseFileName, String folderName, String fileType,
      Uint8List byteList) async {
    final output = await directory;

    final thisDirectory = Directory("${output.path}/$folderName");

    if (await thisDirectory.exists() == false) {
      await thisDirectory.create(recursive: true);
    }

    String fileName = baseFileName;

    var file = File('${thisDirectory.path}/$fileName.$fileType');

    // Check if the file already exists
    if (await file.exists()) {
      await file.delete(); // Delete existing file
    }
    await file.writeAsBytes(byteList);
    return file;
  }

  Future<File?> getFile(
    String fileName,
    String fileType,
    String folderName,
  ) async {
    Directory documentServiceDirectory = await directory;

    File fileDirectory = File(
        "${documentServiceDirectory.path}/$folderName/$fileName.${fileType}");
    if (!fileDirectory.existsSync()) {
      return null;
    }
    return fileDirectory;
  }
}
