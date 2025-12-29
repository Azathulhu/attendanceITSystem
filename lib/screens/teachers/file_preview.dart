/*import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FilePreview extends StatefulWidget {
  final String fileUrl;

  const FilePreview({super.key, required this.fileUrl});

  @override
  State<FilePreview> createState() => _FilePreviewState();
}

class _FilePreviewState extends State<FilePreview> {
  File? localFile;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _downloadTemp();
  }

  Future<void> _downloadTemp() async {
    final res = await http.get(Uri.parse(widget.fileUrl));
    final dir = await getTemporaryDirectory();
    final ext = widget.fileUrl.split('.').last.split('?').first;
    final file = File('${dir.path}/preview.$ext');

    await file.writeAsBytes(res.bodyBytes);

    setState(() {
      localFile = file;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final ext = localFile!.path.split('.').last.toLowerCase();

    /// 🖼 IMAGE
    if (['jpg', 'jpeg', 'png', 'webp'].contains(ext)) {
      return InteractiveViewer(
        child: CachedNetworkImage(imageUrl: widget.fileUrl),
      );
    }

    /// 📄 PDF
    if (ext == 'pdf') {
      return PDFView(filePath: localFile!.path);
    }

    /// 📦 EVERYTHING ELSE
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.insert_drive_file, size: 64),
          const SizedBox(height: 12),
          Text(ext.toUpperCase(), style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => OpenFilex.open(localFile!.path),
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open File'),
          )
        ],
      ),
    );
  }
}*/
