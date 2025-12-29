import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../../services/assignment_service.dart';
import 'submit_assignment_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudentAssignmentsScreen extends StatefulWidget {
  final String classId;

  const StudentAssignmentsScreen({
    super.key,
    required this.classId,
  });

  @override
  State<StudentAssignmentsScreen> createState() =>
      _StudentAssignmentsScreenState();
}

class _StudentAssignmentsScreenState
    extends State<StudentAssignmentsScreen> {
  final AssignmentService _service = AssignmentService();

  bool loading = true;
  List<Map<String, dynamic>> assignments = [];
  Map<String, Map<String, dynamic>> mySubmissions = {};

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => loading = true);

    assignments = await _service.getAssignments(widget.classId);

    mySubmissions.clear();
    for (final a in assignments) {
      final sub = await _service.getMySubmission(a['id']);
      if (sub != null) {
        mySubmissions[a['id']] = sub;
      }
    }

    setState(() => loading = false);
  }

  bool _isPastDue(String? due) {
    if (due == null) return false;
    return DateTime.parse(due).isBefore(DateTime.now());
  }

  bool _isImage(String path) {
    final p = path.toLowerCase();
    return p.endsWith('.png') ||
        p.endsWith('.jpg') ||
        p.endsWith('.jpeg') ||
        p.endsWith('.gif') ||
        p.endsWith('.webp');
  }

  Future<void> _downloadAndOpen(
    BuildContext context,
    String signedUrl,
  ) async {
    try {
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
      await OpenFilex.open(file.path);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to open file')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assignments')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : assignments.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.assignment_outlined,
                          size: 64, color: Colors.grey),
                      SizedBox(height: 12),
                      Text(
                        "No assignments yet",
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: assignments.length,
                  itemBuilder: (_, i) {
                    final a = assignments[i];
                    final locked =
                        a['is_locked'] == true ||
                        _isPastDue(a['due_date']);

                    final submission = mySubmissions[a['id']];
                    final isSubmitted = submission != null;

                    Color statusColor;
                    String statusText;

                    if (locked && !isSubmitted) {
                      statusColor = Colors.red;
                      statusText = "Locked";
                    } else if (submission != null &&
                        submission['grade'] != null) {
                      statusColor = Colors.green;
                      statusText = "Graded";
                    } else if (isSubmitted) {
                      statusColor = Colors.orange;
                      statusText = "Submitted";
                    } else {
                      statusColor = Colors.blue;
                      statusText = "Open";
                    }

                    return AnimatedContainer(
                      duration:
                          const Duration(milliseconds: 250),
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color:
                                statusColor.withOpacity(0.18),
                            blurRadius: 14,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  a['title'],
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6),
                                decoration: BoxDecoration(
                                  color: statusColor
                                      .withOpacity(0.15),
                                  borderRadius:
                                      BorderRadius.circular(20),
                                ),
                                child: Text(
                                  statusText,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          if (a['description'] != null &&
                              a['description']
                                  .toString()
                                  .isNotEmpty)
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: 8),
                              child: Text(
                                a['description'],
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),

                          const SizedBox(height: 14),

                          if (a['instruction_signed_url'] != null)
                            ElevatedButton.icon(
                              icon: const Icon(Icons.download),
                              label: const Text(
                                  "Download Instructions"),
                              onPressed: () =>
                                  _downloadAndOpen(
                                context,
                                a['instruction_signed_url'],
                              ),
                            ),

                          if (isSubmitted &&
                              submission?['signed_url'] !=
                                  null)
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: 12),
                              child: ElevatedButton.icon(
                                icon: const Icon(
                                    Icons.open_in_new),
                                label: const Text(
                                    "Open Submission"),
                                onPressed: () =>
                                    _downloadAndOpen(
                                  context,
                                  submission!['signed_url'],
                                ),
                              ),
                            ),

                          if (isSubmitted &&
                              submission != null &&
                              submission['grade'] != null)
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: 14),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const Divider(),
                                  Text(
                                    "Grade: ${submission['grade']} / ${a['max_points']}",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight:
                                          FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                  if (submission['feedback'] !=
                                          null &&
                                      submission['feedback']
                                          .toString()
                                          .isNotEmpty)
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(
                                              top: 6),
                                      child: Text(
                                        submission['feedback'],
                                        style: const TextStyle(
                                          fontStyle:
                                              FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 12),

                          if (!isSubmitted)
                            ElevatedButton(
                              onPressed: locked
                                  ? null
                                  : () async {
                                      final res =
                                          await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              SubmitAssignmentScreen(
                                            assignmentId:
                                                a['id'],
                                            title: a['title'],
                                          ),
                                        ),
                                      );
                                      if (res == true) {
                                        await _loadAll();
                                      }
                                    },
                              child: Text(
                                  locked ? "Locked" : "Submit"),
                            ),

                          if (isSubmitted)
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Colors.orange,
                              ),
                              onPressed: locked
                                  ? null
                                  : () async {
                                      await _service.unsubmit(
                                        a['id'],
                                        Supabase.instance
                                            .client
                                            .auth
                                            .currentUser!
                                            .id,
                                      );
                                      mySubmissions
                                          .remove(a['id']);
                                      setState(() {});
                                    },
                              child: const Text("Unsubmit"),
                            ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
