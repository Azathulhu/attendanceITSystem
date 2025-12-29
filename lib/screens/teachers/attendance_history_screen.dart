import 'package:flutter/material.dart';
import '../../supabase_client.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  final String classId;
  final String className;

  const AttendanceHistoryScreen({
    required this.classId,
    required this.className,
    super.key,
  });

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  bool isLoading = true;
  String? error;

  List<Map<String, dynamic>> history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final sessions = await SupabaseClientInstance.supabase
          .from('attendance_sessions')
          .select('id, start_time, end_time')
          .eq('class_id', widget.classId)
          .order('start_time', ascending: false);

      List<Map<String, dynamic>> temp = [];

      for (final session in sessions) {
        final records = await SupabaseClientInstance.supabase
            .from('attendance_records')
            .select('student_id, status, scanned_at')
            .eq('session_id', session['id']);

        List<Map<String, dynamic>> enriched = [];

        for (final record in records) {
          final profile = await SupabaseClientInstance.supabase
              .from('profiles')
              .select('full_name')
              .eq('id', record['student_id'])
              .maybeSingle();

          enriched.add({
            ...record,
            'profile': profile,
          });
        }

        temp.add({
          'session': session,
          'records': enriched,
        });
      }

      setState(() {
        history = temp;
      });
    } catch (e) {
      setState(() {
        error = "Failed to load attendance history: $e";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  String _format(String iso) {
    final dt = DateTime.parse(iso).toLocal();
    return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} "
        "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  Color _color(String status) {
    switch (status) {
      case 'on_time':
        return Colors.green.shade100;
      case 'late':
        return Colors.yellow.shade100;
      case 'absent':
        return Colors.red.shade100;
      default:
        return Colors.grey.shade200;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Attendance History - ${widget.className}"),
        backgroundColor: Colors.green[400],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!))
              : history.isEmpty
                  ? const Center(child: Text("No attendance history"))
                  : ListView.builder(
                      itemCount: history.length,
                      itemBuilder: (_, index) {
                        final session = history[index]['session'];
                        final records =
                            List<Map<String, dynamic>>.from(
                                history[index]['records']);

                        return Card(
                          margin: const EdgeInsets.all(12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)),
                          child: ExpansionTile(
                            title: Text(
                              "Session: ${_format(session['start_time'])}",
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle:
                                Text("Ended: ${_format(session['end_time'])}"),
                            children: records.isEmpty
                                ? const [
                                    Padding(
                                      padding: EdgeInsets.all(16),
                                      child:
                                          Text("No students scanned"),
                                    )
                                  ]
                                : records.map((r) {
                                    final profile = r['profile'];
                                    final status = r['status'];

                                    return Card(
                                      color: _color(status),
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 4),
                                      child: ListTile(
                                        title: Text(
                                          profile?['full_name'] ??
                                              r['student_id'],
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        subtitle: Text(
                                          status
                                              .replaceAll('_', ' ')
                                              .toUpperCase(),
                                        ),
                                        trailing: Text(
                                          r['scanned_at'] != null
                                              ? DateTime.parse(r['scanned_at'])
                                                  .toLocal()
                                                  .toIso8601String()
                                                  .substring(11, 19)
                                              : '',
                                          style:
                                              const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                          ),
                        );
                      },
                    ),
    );
  }
}
