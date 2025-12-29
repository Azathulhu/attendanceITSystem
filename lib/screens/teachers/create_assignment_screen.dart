import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../services/assignment_service.dart';
import '../../primary_button.dart';
import '../../soft_text_field.dart';

class CreateAssignmentScreen extends StatefulWidget {
  final String classId;
  const CreateAssignmentScreen({required this.classId, super.key});

  @override
  State<CreateAssignmentScreen> createState() =>
      _CreateAssignmentScreenState();
}

class _CreateAssignmentScreenState extends State<CreateAssignmentScreen> {
  final service = AssignmentService();

  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();

  DateTime? dueDate;
  Uint8List? instructionBytes;
  String? instructionName;

  Future<void> _pickDueDateTime() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;

    setState(() {
      dueDate = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      ).toUtc();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Assignment"),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.green.shade200,
                  child: Icon(
                    Icons.assignment_rounded,
                    color: Colors.green.shade800,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    "New Assignment",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(20),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SoftTextField(
                  controller: titleCtrl,
                  label: "Assignment Title",
                ),
                SoftTextField(
                  controller: descCtrl,
                  label: "Description",
                ),

                const SizedBox(height: 16),

                GestureDetector(
                  onTap: () async {
                    final res =
                        await FilePicker.platform.pickFiles(
                      withData: true,
                    );

                    if (res != null &&
                        res.files.single.bytes != null) {
                      setState(() {
                        instructionBytes =
                            res.files.single.bytes;
                        instructionName =
                            res.files.single.name;
                      });
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: Colors.green.shade200,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.attach_file_rounded,
                          color: Colors.green.shade700,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            instructionName ??
                                "Attach instruction file",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: instructionName == null
                                  ? Colors.green.shade700
                                  : Colors.black87,
                            ),
                          ),
                        ),
                        if (instructionName != null)
                          Icon(
                            Icons.check_circle,
                            color: Colors.green.shade600,
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                GestureDetector(
                  onTap: _pickDueDateTime,
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: Colors.green.shade200,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_month_rounded,
                          color: Colors.green.shade700,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            dueDate == null
                                ? "Pick due date & time"
                                : dueDate.toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: Colors.green.shade600,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          PrimaryButton(
            text: "Create Assignment",
            onTap: () async {
              await service.createAssignment(
                classId: widget.classId,
                title: titleCtrl.text,
                description: descCtrl.text,
                dueDate: dueDate,
                assignmentType: 'activity',
                instructionBytes: instructionBytes,
                instructionName: instructionName,
              );
              Navigator.pop(context);
            },
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
