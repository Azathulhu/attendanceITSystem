import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../../services/assignment_service.dart';
import '../../primary_button.dart';

class AssignmentSubmissionsScreen extends StatefulWidget {
  final String assignmentId;
  final String title;

  const AssignmentSubmissionsScreen({
    required this.assignmentId,
    required this.title,
    super.key,
  });

  @override
  State<AssignmentSubmissionsScreen> createState() =>
      _AssignmentSubmissionsScreenState();
}

class _AssignmentSubmissionsScreenState
    extends State<AssignmentSubmissionsScreen> {
  final AssignmentService service = AssignmentService();
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = service.getSubmissions(widget.assignmentId);
  }

  void _reload() {
    setState(() {
      _future = service.getSubmissions(widget.assignmentId);
    });
  }

  bool _isImage(String path) {
    final p = path.toLowerCase();
    return p.endsWith('.png') ||
        p.endsWith('.jpg') ||
        p.endsWith('.jpeg') ||
        p.endsWith('.gif') ||
        p.endsWith('.webp');
  }

  Future<File> _download(String signedUrl) async {
    final uri = Uri.parse(signedUrl);
    final client = HttpClient();
    final req = await client.getUrl(uri);
    final res = await req.close();

    final bytes =
        await consolidateHttpClientResponseBytes(res);

    final dir = await getApplicationDocumentsDirectory();
    final name = uri.pathSegments.last.split('?').first;
    final file = File('${dir.path}/$name');

    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  void _gradeDialog(
    BuildContext context,
    Map<String, dynamic> s,
  ) {
    final gradeCtrl =
        TextEditingController(text: s['grade']?.toString());
    final feedbackCtrl =
        TextEditingController(text: s['feedback']);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Text(
          "Grade Submission",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.green.shade700,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Max points: ${s['max_points']}",
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: gradeCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Grade",
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: feedbackCtrl,
              decoration: const InputDecoration(
                labelText: "Feedback (optional)",
              ),
            ),
          ],
        ),
        actionsPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          PrimaryButton(
            text: "Save Grade",
            onTap: () async {
              final grade = int.parse(gradeCtrl.text);

              if (grade < 0 || grade > s['max_points']) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        "Grade must be between 0 and ${s['max_points']}"),
                  ),
                );
                return;
              }

              await service.gradeSubmission(
                submissionId: s['id'],
                grade: grade,
                feedback: feedbackCtrl.text.isEmpty
                    ? null
                    : feedbackCtrl.text,
              );

              Navigator.pop(context);
              _reload();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (_, snap) {
          if (!snap.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final data = snap.data!;

          if (data.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inbox_rounded,
                      size: 72, color: Colors.green.shade200),
                  const SizedBox(height: 16),
                  const Text(
                    "No submissions yet",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: data.length,
            itemBuilder: (_, i) {
              final s = data[i];
              final path = s['file_url'];
              final signed = s['signed_url'];

              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.12),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor:
                                Colors.green.shade100,
                            child: Icon(Icons.person,
                                color: Colors.green.shade700),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              s['student_name'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (s['grade'] != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                "${s['grade']} / ${s['max_points']}",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade800,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (path != null &&
                          signed != null &&
                          _isImage(path))
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.network(
                            signed,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: PrimaryButton(
                              text: "Open File",
                              onTap: () async {
                                final f = await _download(signed);
                                await OpenFilex.open(f.path);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: PrimaryButton(
                              text: "Grade",
                              onTap: () =>
                                  _gradeDialog(context, s),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
