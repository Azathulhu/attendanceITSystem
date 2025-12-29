import 'package:flutter/material.dart';
import '../../services/participation_service.dart';

class ParticipationScreen extends StatefulWidget {
  final String classId;
  final String className;

  const ParticipationScreen({
    required this.classId,
    required this.className,
    super.key,
  });

  @override
  State<ParticipationScreen> createState() => _ParticipationScreenState();
}

class _ParticipationScreenState extends State<ParticipationScreen> {
  final ParticipationService service = ParticipationService();
  List<Map<String, dynamic>> students = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    students = await service.getClassStudents(widget.classId);
    setState(() {});
  }

  Future<void> _apply(String studentId, int points) async {
    await service.addPoints(
      classId: widget.classId,
      studentId: studentId,
      points: points,
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Participation - ${widget.className}"),
      ),
      body: Column(
        children: [

          Expanded(
            child: ListView.builder(
              itemCount: students.length,
              itemBuilder: (_, i) {
                final s = students[i];
                final profile = s['profiles'];

                return ListTile(
                  title: Text(profile['full_name']),
                  subtitle: Text(
                    "Points: ${profile['participation_points']}",
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () =>
                            _apply(s['student_id'], -1),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () =>
                            _apply(s['student_id'], 1),
                      ),
                      IconButton(
                        icon: const Icon(Icons.exposure_plus_2),
                        onPressed: () =>
                            _apply(s['student_id'], 2),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
