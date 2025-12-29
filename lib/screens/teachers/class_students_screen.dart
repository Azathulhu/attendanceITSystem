/*import 'package:flutter/material.dart';
import '../../services/class_service.dart';
import '../../services/participation_service.dart';

class ClassStudentsScreen extends StatefulWidget {
  final String classId;
  const ClassStudentsScreen({super.key, required this.classId});

  @override
  State<ClassStudentsScreen> createState() => _ClassStudentsScreenState();
}

class _ClassStudentsScreenState extends State<ClassStudentsScreen> {
  final classService = ClassService();
  final participationService = ParticipationService();

  List<Map<String, dynamic>> students = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    students = await classService.getClassStudents(widget.classId);
    setState(() => loading = false);
  }

  Future<void> _add(String studentId, int delta) async {
    await participationService.addPoints(
      studentId: studentId,
      delta: delta,
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Class Students")),
      body: ListView.builder(
        itemCount: students.length,
        itemBuilder: (_, i) {
          final s = students[i]['profiles'];
          final id = students[i]['student_id'];

          return Card(
            child: ListTile(
              title: Text(s['full_name'] ?? 'Student'),
              subtitle: Text(
                'Points: ${s['participation_points']}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: () => _add(id, -1),
                  ),
                  IconButton(
                    icon: const Icon(Icons.exposure_plus_1),
                    onPressed: () => _add(id, 1),
                  ),
                  IconButton(
                    icon: const Icon(Icons.exposure_plus_2),
                    onPressed: () => _add(id, 2),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}*/
