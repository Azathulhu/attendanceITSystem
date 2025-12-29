import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../services/assignment_service.dart';
import 'create_assignment_screen.dart';
import 'assignment_submissions_screen.dart';
import '../../primary_button.dart';
import '../../soft_text_field.dart';

class TeacherAssignmentsScreen extends StatefulWidget {
  final String classId;

  const TeacherAssignmentsScreen({
    required this.classId,
    super.key,
  });

  @override
  State<TeacherAssignmentsScreen> createState() =>
      _TeacherAssignmentsScreenState();
}

class _TeacherAssignmentsScreenState
    extends State<TeacherAssignmentsScreen> {
  final AssignmentService service = AssignmentService();
  List<Map<String, dynamic>> assignments = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    assignments = await service.getAssignments(widget.classId);
    setState(() => loading = false);
  }

  void _editAssignment(Map<String, dynamic> a) {
    final maxPointsCtrl =
        TextEditingController(text: a['max_points'].toString());
    final titleCtrl = TextEditingController(text: a['title']);
    final descCtrl = TextEditingController(text: a['description']);
    DateTime? dueDate =
        a['due_date'] != null ? DateTime.parse(a['due_date']).toLocal() : null;

    Uint8List? newBytes;
    String? newName;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
        ),
        title: const Text(
          "Edit Assignment",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            children: [
              SoftTextField(
                controller: titleCtrl,
                label: "Title",
              ),
              SoftTextField(
                controller: descCtrl,
                label: "Description",
              ),
              SoftTextField(
                controller: maxPointsCtrl,
                label: "Max Points",
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (d == null) return;

                  final t = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (t == null) return;

                  setState(() {
                    dueDate = DateTime(
                            d.year, d.month, d.day, t.hour, t.minute)
                        .toUtc();
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Colors.green.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today,
                          color: Colors.green.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          dueDate == null
                              ? "Pick Due Date & Time"
                              : dueDate.toString(),
                          style: const TextStyle(
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              PrimaryButton(
                text: "Replace Instruction File",
                onTap: () async {
                  final res =
                      await FilePicker.platform.pickFiles(
                    withData: true,
                  );
                  if (res != null &&
                      res.files.single.bytes != null) {
                    newBytes = res.files.single.bytes;
                    newName = res.files.single.name;
                  }
                },
              ),
            ],
          ),
        ),
        actionsPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          PrimaryButton(
            text: "Save",
            onTap: () async {
              await service.updateAssignment(
                assignmentId: a['id'],
                title: titleCtrl.text,
                description: descCtrl.text,
                dueDate: dueDate,
              );

              await service.updateAssignmentMaxPoints(
                assignmentId: a['id'],
                maxPoints: int.parse(maxPointsCtrl.text),
              );

              if (newBytes != null && newName != null) {
                await service.updateInstructionFile(
                  assignmentId: a['id'],
                  bytes: newBytes!,
                  fileName: newName!,
                );
              }

              Navigator.pop(context);
              _load();
            },
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String assignmentId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Delete Assignment"),
        content: const Text("This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          PrimaryButton(
            text: "Delete",
            onTap: () async {
              await service.deleteAssignment(assignmentId);
              Navigator.pop(context);
              _load();
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
        title: const Text("Assignments"),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.green,
        icon: const Icon(Icons.add),
        label: const Text("New"),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  CreateAssignmentScreen(classId: widget.classId),
            ),
          );
          _load();
        },
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: assignments.length,
              itemBuilder: (_, i) {
                final a = assignments[i];
                final bool locked = a['is_locked'] == true;

                return Container(
                  margin: const EdgeInsets.only(bottom: 18),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.12),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor:
                                Colors.green.shade100,
                            child: Icon(
                              Icons.assignment_rounded,
                              color: Colors.green.shade700,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              a['title'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              locked
                                  ? Icons.lock_rounded
                                  : Icons.lock_open_rounded,
                              color:
                                  locked ? Colors.red : Colors.green,
                            ),
                            onPressed: () async {
                              await service.setAssignmentLock(
                                  a['id'], !locked);
                              _load();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (a['description'] != null)
                        Text(
                          a['description'],
                          style:
                              TextStyle(color: Colors.grey.shade600),
                        ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _editAssignment(a),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () =>
                                _confirmDelete(a['id']),
                          ),
                          const Spacer(),
                          PrimaryButton(
                            text: "Submissions",
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      AssignmentSubmissionsScreen(
                                    assignmentId: a['id'],
                                    title: a['title'],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
