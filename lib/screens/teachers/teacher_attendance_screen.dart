import 'dart:async';
import 'package:flutter/material.dart';
import '../../supabase_client.dart';

class TeacherAttendanceScreen extends StatefulWidget {
  final String classId;
  final String className;

  const TeacherAttendanceScreen({
    required this.classId,
    required this.className,
    super.key,
  });

  @override
  State<TeacherAttendanceScreen> createState() =>
      _TeacherAttendanceScreenState();
}

class _TeacherAttendanceScreenState extends State<TeacherAttendanceScreen> {
  String sessionId = '';
  DateTime? endTime;
  List<Map<String, dynamic>> scannedStudents = [];
  Timer? timer;

  @override
  void initState() {
    super.initState();
    _initSession();
    timer = Timer.periodic(const Duration(seconds: 1), (_) => _loadAttendance());
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> _initSession() async {
    try {
      final latest = await SupabaseClientInstance.supabase
          .from('attendance_sessions')
          .select('id, start_time, end_time')
          .eq('class_id', widget.classId)
          .order('start_time', ascending: false)
          .limit(1)
          .maybeSingle();

      DateTime now = DateTime.now().toUtc();

      if (latest == null ||
          now.isAfter(DateTime.parse(latest['end_time']))) {
        final startTime = now;
        endTime = startTime.add(const Duration(minutes: 5));

        final qrCode = "${widget.classId}|${startTime.millisecondsSinceEpoch}";

        final resp = await SupabaseClientInstance.supabase
            .from('attendance_sessions')
            .insert({
              'class_id': widget.classId,
              'teacher_id':
                  SupabaseClientInstance.supabase.auth.currentUser!.id,
              'start_time': startTime.toIso8601String(),
              'end_time': endTime!.toIso8601String(),
              'qr_code': qrCode,
            })
            .select('id')
            .maybeSingle();

        sessionId = resp?['id'] ?? '';
      } else {
        sessionId = latest['id'];
        endTime = DateTime.parse(latest['end_time']);
      }

      await _loadAttendance();
    } catch (e) {
      debugPrint("Error initializing session: $e");
    }
  }

  Future<void> _loadAttendance() async {
    if (sessionId.isEmpty) return;

    try {
      final records = await SupabaseClientInstance.supabase
          .from('attendance_records')
          .select('student_id, status, scanned_at, profiles(full_name)')
          .eq('session_id', sessionId);

      setState(() {
        scannedStudents = List<Map<String, dynamic>>.from(records);
      });
    } catch (e) {
      debugPrint("Error loading attendance: $e");
    }
  }

  Map<String, int> _summarizeAttendance() {
    int onTime = 0, late = 0, absent = 0;
    for (var s in scannedStudents) {
      switch (s['status']) {
        case 'on_time':
          onTime++;
          break;
        case 'late':
          late++;
          break;
        case 'absent':
          absent++;
          break;
      }
    }
    return {
      'on_time': onTime,
      'late': late,
      'absent': absent,
      'total': scannedStudents.length
    };
  }

  String _countdown() {
    if (endTime == null) return '';
    final diff = endTime!.difference(DateTime.now().toUtc());
    if (diff.isNegative) return "Session expired";
    final minutes = diff.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = diff.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'on_time':
        return Colors.green.shade200;
      case 'late':
        return Colors.yellow.shade200;
      case 'absent':
        return Colors.red.shade200;
      default:
        return Colors.grey.shade100;
    }
  }

  Widget _buildSummaryItem(String title, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summarizeAttendance();

    return Scaffold(
      appBar: AppBar(
        title: Text("Attendance - ${widget.className}"),
        backgroundColor: Colors.green.shade400,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              color: Colors.green.shade100,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem(
                        "On-time", summary['on_time']!, Colors.green.shade600),
                    _buildSummaryItem(
                        "Late", summary['late']!, Colors.yellow.shade700),
                    _buildSummaryItem(
                        "Absent", summary['absent']!, Colors.red.shade400),
                    _buildSummaryItem(
                        "Total", summary['total']!, Colors.green.shade800),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Countdown: ${_countdown()}",
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade900),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: scannedStudents.isEmpty
                  ? Center(
                      child: Text(
                        "No students have scanned yet",
                        style: TextStyle(
                            color: Colors.green.shade900,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      itemCount: scannedStudents.length,
                      itemBuilder: (_, index) {
                        final student = scannedStudents[index];
                        final profile = student['profiles'];
                        final status = student['status'] ?? 'unknown';

                        return Card(
                          color: _statusColor(status),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)),
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            title: Text(
                              profile?['full_name'] ?? student['student_id'],
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle:
                                Text(status.replaceAll('_', ' ').toUpperCase()),
                            trailing: Text(
                              student['scanned_at'] ?? '',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
