import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../supabase_client.dart';

class TeacherQRScreen extends StatefulWidget {
  final String classId;
  final String className;

  const TeacherQRScreen({required this.classId, required this.className, super.key});

  @override
  State<TeacherQRScreen> createState() => _TeacherQRScreenState();
}

class _TeacherQRScreenState extends State<TeacherQRScreen> {
  String? qrCodeString;
  String sessionId = '';
  DateTime? startTime;
  DateTime? endTime;
  List<Map<String, dynamic>> scannedStudents = [];
  Timer? timer;

  @override
  void initState() {
    super.initState();
    _createSession();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> _createSession() async {
    startTime = DateTime.now().toUtc();
    endTime = startTime!.add(const Duration(minutes: 5));

    qrCodeString = "${widget.classId}|${startTime!.millisecondsSinceEpoch}";

    final response = await SupabaseClientInstance.supabase
        .from('attendance_sessions')
        .insert({
          'class_id': widget.classId,
          'teacher_id': SupabaseClientInstance.supabase.auth.currentUser!.id,
          'start_time': startTime!.toIso8601String(),
          'end_time': endTime!.toIso8601String(),
          'qr_code': qrCodeString,
        })
        .select('id')
        .maybeSingle();

    sessionId = response?['id'] ?? '';

    timer = Timer.periodic(const Duration(seconds: 1), (_) => _loadScannedStudents());

    setState(() {});
  }

  Future<void> _loadScannedStudents() async {
    if (sessionId.isEmpty) return;

    final records = await SupabaseClientInstance.supabase
        .from('attendance_records')
        .select('student_id, status, scanned_at')
        .eq('session_id', sessionId);

    final List<Map<String, dynamic>> tempList = [];

    for (var record in records) {
      final profile = await SupabaseClientInstance.supabase
          .from('profiles')
          .select('full_name')
          .eq('id', record['student_id'])
          .maybeSingle();

      tempList.add({
        ...record,
        'profiles': profile,
      });
    }

    setState(() {
      scannedStudents = tempList;
    });
  }

  String _countdown() {
    if (endTime == null) return '';
    final diff = endTime!.difference(DateTime.now().toUtc());
    if (diff.isNegative) return "Session expired";
    final minutes = diff.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = diff.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50],
      appBar: AppBar(
        title: Text("Attendance - ${widget.className}"),
        backgroundColor: Colors.green[400],
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (qrCodeString != null)
              Column(
                children: [
                  Card(
                    color: Colors.green[100],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 5,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          QrImageView(
                            data: qrCodeString!,
                            version: QrVersions.auto,
                            size: 200,
                            gapless: false,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "Scan this QR code to mark attendance",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Countdown: ${_countdown()}",
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              )
            else
              const CircularProgressIndicator(),

            Expanded(
              child: scannedStudents.isEmpty
                  ? const Center(child: Text("No students scanned yet"))
                  : ListView.builder(
                      itemCount: scannedStudents.length,
                      itemBuilder: (_, index) {
                        final student = scannedStudents[index];
                        final profile = student['profiles'];
                        return Card(
                          color: Colors.green[200],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            title: Text(profile?['full_name'] ?? 'Unknown'),
                            subtitle: Text(student['status'] ?? 'unknown'),
                            trailing: Text(
                              student['scanned_at'] != null
                                  ? DateTime.parse(student['scanned_at']).toLocal().toIso8601String().substring(11, 19)
                                  : '',
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
