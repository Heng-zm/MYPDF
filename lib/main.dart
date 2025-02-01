import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker_web/image_picker_web.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:universal_html/html.dart' as html;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      debugShowCheckedModeBanner: false,
      title: 'Image to PDF',
      theme: CupertinoThemeData(brightness: Brightness.light),
      home: ImageToPdfScreen(),
    );
  }
}

class ImageToPdfScreen extends StatefulWidget {
  @override
  _ImageToPdfScreenState createState() => _ImageToPdfScreenState();
}

class _ImageToPdfScreenState extends State<ImageToPdfScreen> {
  List<Uint8List> _images = [];
  Uint8List? _pdfBytes;
  bool _isLoading = false;

  // Pick multiple images
  Future<void> pickImages() async {
    List<Uint8List>? bytesList = await ImagePickerWeb.getMultiImagesAsBytes();
    if (bytesList != null && bytesList.isNotEmpty) {
      setState(() {
        _images.addAll(bytesList);
      });
    }
  }

  // Generate PDF from images
  Future<void> generatePdf() async {
    setState(() => _isLoading = true);

    final pdf = pw.Document();
    for (Uint8List imageBytes in _images) {
      final image = pw.MemoryImage(imageBytes);
      pdf.addPage(
        pw.Page(
            build: (pw.Context context) => pw.Center(child: pw.Image(image))),
      );
    }

    _pdfBytes = await pdf.save();
    setState(() => _isLoading = false);
  }

  // Download the generated PDF (For Web)
  void downloadPdf() {
    if (_pdfBytes == null) return;

    setState(() => _isLoading = true);

    Future.delayed(Duration(seconds: 2), () {
      final blob = html.Blob([_pdfBytes!], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", "images.pdf")
        ..click();
      html.Url.revokeObjectUrl(url);

      setState(() => _isLoading = false);
    });
  }

  // Save PDF to device storage (iOS & Mobile)
  Future<void> saveToDevice() async {
    if (_pdfBytes == null) return;

    setState(() => _isLoading = true);

    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/images.pdf';
      final file = File(filePath);
      await file.writeAsBytes(_pdfBytes!);

      setState(() => _isLoading = false);

      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text('Success'),
          content: Text('PDF saved to: $filePath'),
          actions: [
            CupertinoDialogAction(
              child: Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);

      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text('Error'),
          content: Text('Failed to save PDF'),
          actions: [
            CupertinoDialogAction(
              child: Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Image to PDF Converter'),
      ),
      child: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 20),
            CupertinoButton.filled(
              onPressed: pickImages,
              child: Text("Pick Images"),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _images.length,
                itemBuilder: (context, index) => Padding(
                  padding: EdgeInsets.all(8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(_images[index], height: 120),
                  ),
                ),
              ),
            ),
            CupertinoButton.filled(
              onPressed: generatePdf,
              child: Text("Generate PDF"),
            ),
            if (_isLoading)
              Padding(
                padding: EdgeInsets.all(20),
                child: CupertinoActivityIndicator(radius: 15),
              ),
            if (_pdfBytes != null && !_isLoading) ...[
              SizedBox(height: 10),
              CupertinoButton(
                color: CupertinoColors.activeGreen,
                onPressed: downloadPdf,
                child: Text("Download PDF"),
              ),
              SizedBox(height: 10),
              CupertinoButton(
                color: CupertinoColors.activeBlue,
                onPressed: saveToDevice,
                child: Text("Save to Device"),
              ),
            ],
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
