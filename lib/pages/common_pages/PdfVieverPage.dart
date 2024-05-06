import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:widget_state_notifier/widget_state_notifier.dart';

import '../../components/CustomCircularButton.dart';
import '../../components/CustomProject.dart';
import '../../data_notifiers/AppFileServiceData.dart';
import '../../db_references/AppFile.dart';
import '../../operations/AppFileOperation.dart';
import '../../operations/CacheOperation.dart';

class PdfViewerPage extends StatefulWidget {
  final String localIdentity;
  final String pdfTitle;
  final WidgetStateNotifier<AppFileServiceData> appFileNotifier;

  PdfViewerPage(
      {required this.localIdentity,
      required this.pdfTitle,
      required this.appFileNotifier});

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  WidgetStateNotifier<Uint8List> pathNotifier = WidgetStateNotifier();

  StreamSubscription? streamSubscription;

  @override
  void initState() {
    super.initState();
    setLightUiViewOverlay();
    fetchPath(widget.appFileNotifier.currentValue);
    streamSubscription ??= widget.appFileNotifier.stream.listen((event) {
      fetchPath(event);
    });
  }

  @override
  void dispose() {
    super.dispose();
    streamSubscription?.cancel();
    streamSubscription = null;
  }

  void performBackPressed() {
    Navigator.pop(context);
  }

  void fetchPath(AppFileServiceData? appFileServiceData) async {
    try {
      final savedData = await CacheOperation()
          .getCacheData(dbReference(AppFile.database), widget.localIdentity);

      if (savedData is Map) {
        final savedAppFileServiceData = AppFileServiceData.fromJson(savedData);

        if (appFileServiceData == null) {
          downloadFile(savedAppFileServiceData);
        } else if (savedAppFileServiceData.onlineDirectory !=
                appFileServiceData.onlineDirectory &&
            savedAppFileServiceData.onlineIndex !=
                appFileServiceData.onlineIndex &&
            savedAppFileServiceData.fileType != appFileServiceData.fileType) {
          downloadFile(appFileServiceData);
        } else {
          downloadFile(appFileServiceData);
        }
      } else if (appFileServiceData != null) {
        downloadFile(appFileServiceData);
      } else {
        downloadFile(null);
      }
    } catch (e) {
      if (appFileServiceData != null) {
        downloadFile(appFileServiceData);
      } else {
        downloadFile(null);
      }
    }
  }

  void downloadFile(AppFileServiceData? appFileServiceData) async {
    if (appFileServiceData != null) {
      try {
        // final file = await AppFileOperation().getFile(savedAppFileServiceData.localIdentity!,savedAppFileServiceData.fileType!, AppFileOperation.fileFolder);
        pathNotifier.sendNewState(null);
        final file =
            await AppFileOperation().downloadAppFile(appFileServiceData);
        if (file != null) {
          pathNotifier.sendNewState(file);
        } else {
          pathNotifier.sendNewState(Uint8List.fromList([]));
        }
      } catch (e, s) {
        pathNotifier.sendNewState(Uint8List.fromList([]));
        showDebug(msg: "$e $s");
      }
    } else {
      pathNotifier.sendNewState(Uint8List.fromList([]));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Back Button
            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
              ),
              child: Row(children: [
                CustomCircularButton(
                  imagePath: null,
                  iconColor: Colors.black,
                  onPressed: performBackPressed,
                  icon: Icons.arrow_back,
                  width: 40,
                  height: 40,
                  iconSize: 30,
                  mainAlignment: Alignment.center,
                  defaultBackgroundColor: Colors.transparent,
                  clickedBackgroundColor: Colors.white,
                ),
                const SizedBox(
                  width: 8,
                ),
                Expanded(
                  child: Text(
                    widget.pdfTitle,
                    textScaleFactor: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ]),
            ),

            Expanded(
              child: WidgetStateConsumer(
                  widgetStateNotifier: pathNotifier,
                  widgetStateBuilder: (context, pdfData) {
                    if (pdfData == null)
                      return Center(
                        child: progressBarWidget(),
                      );
                    if (pdfData.isEmpty)
                      return Center(
                          child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          "An error has occurred!!!",
                          style: TextStyle(
                              color: Colors.black.withOpacity(0.8),
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                      ));
                    return PDFView(
                      // filePath: pdfData,
                      pdfData: pdfData,
                      fitPolicy: FitPolicy.BOTH,
                      enableSwipe: true,
                      swipeHorizontal: false,
                      autoSpacing: false,
                      pageSnap: false,
                      pageFling: false,
                      onRender: (pages) {
                        // Do something when PDF is rendered
                      },
                      onError: (error) {
                        pathNotifier.sendNewState(Uint8List.fromList([]));
                      },
                      onPageChanged: (int? page, int? total) {
                        // Do something when page changes
                      },
                    );
                  }),
            ),
            // Add more widgets here if needed
          ],
        ),
      ),
    );
  }
}
