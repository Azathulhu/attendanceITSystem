import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../services/assignment_service.dart';

class SubmitAssignmentScreen extends StatefulWidget {
  final String assignmentId;
  final String title;

  const SubmitAssignmentScreen({
    required this.assignmentId,
    required this.title,
    super.key,
  });

  @override
  State<SubmitAssignmentScreen> createState() =>
      _SubmitAssignmentScreenState();
}

class _SubmitAssignmentScreenState extends State<SubmitAssignmentScreen> {
  final AssignmentService service = AssignmentService();

  Uint8List? bytes;
  String? fileName;
  bool loading = false;

  Future<void> _pickFile() async {
    final res = await FilePicker.platform.pickFiles(withData: true);

    if (res != null && res.files.single.bytes != null) {
      setState(() {
        bytes = res.files.single.bytes;
        fileName = res.files.single.name;
      });
    }
  }

  Future<void> _submit() async {
    if (bytes == null || fileName == null) return;

    setState(() => loading = true);

    final err = await service.submitAssignment(
      assignmentId: widget.assignmentId,
      fileBytes: bytes!,
      fileName: fileName!,
    );

    setState(() => loading = false);

    if (err == null) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(err)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final green = Colors.green.shade600;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: green,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_upload, size: 72, color: green),
                const SizedBox(height: 16),
                Text(
                  "Upload your assignment",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: green,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.attach_file),
                    label: const Text("Pick File"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: _pickFile,
                  ),
                ),
                if (fileName != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.insert_drive_file, color: green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            fileName!,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                loading
                    ? CircularProgressIndicator(color: green)
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text(
                            "Submit Assignment",
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
