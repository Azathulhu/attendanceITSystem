import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import '../../supabase_client.dart';

class StudentQRScanScreen extends StatefulWidget {
  final String classId;

  const StudentQRScanScreen({
    required this.classId,
    super.key,
  });

  @override
  State<StudentQRScanScreen> createState() => _StudentQRScanScreenState();
}

class _StudentQRScanScreenState extends State<StudentQRScanScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;

  bool scanned = false;
  String? message;

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Future<void> _onScan(Barcode result) async {
    if (scanned) return;
    scanned = true;

    final code = result.code;
    if (code == null) {
      setState(() => message = "Invalid QR code");
      scanned = false;
      return;
    }

    final parts = code.split('|');
    if (parts.length != 2) {
      setState(() => message = "Invalid QR format");
      scanned = false;
      return;
    }

    final scannedClassId = parts[0];
    if (scannedClassId != widget.classId) {
      setState(() => message = "This QR is for a different class");
      scanned = false;
      return;
    }

    final timestamp = int.tryParse(parts[1]);
    if (timestamp == null) {
      setState(() => message = "Invalid QR timestamp");
      scanned = false;
      return;
    }

    final studentId =
        SupabaseClientInstance.supabase.auth.currentUser!.id;

    final qrTime =
        DateTime.fromMillisecondsSinceEpoch(timestamp).toUtc();
    final now = DateTime.now().toUtc();

    String status;
    final diff = now.difference(qrTime).inMinutes;

    if (diff <= 15) {
      status = "on_time";
    } else if (diff <= 30) {
      status = "late";
    } else {
      status = "absent";
    }

    try {
      final session = await SupabaseClientInstance.supabase
          .from('attendance_sessions')
          .select('id, end_time')
          .eq('class_id', widget.classId)
          .order('start_time', ascending: false)
          .limit(1)
          .maybeSingle();

      if (session == null) {
        setState(() => message = "No active session");
        scanned = false;
        return;
      }

      final sessionEnd = DateTime.parse(session['end_time']).toUtc();
      if (now.isAfter(sessionEnd)) {
        status = "absent";
      }

      final insert = await SupabaseClientInstance.supabase
          .from('attendance_records')
          .insert({
            'session_id': session['id'],
            'student_id': studentId,
            'status': status,
          })
          .select()
          .maybeSingle();

      if (insert == null) {
        setState(() => message = "Already scanned");
        return;
      }

      setState(() => message = "Attendance recorded: $status");
    } catch (e) {
      setState(() => message = "Error: $e");
      scanned = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan Attendance QR")),
      body: Column(
        children: [
          Expanded(
            child: QRView(
              key: qrKey,
              onQRViewCreated: (ctrl) {
                controller = ctrl;
                controller!.scannedDataStream.listen(_onScan);
              },
            ),
          ),
          if (message != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                message!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ElevatedButton(
            onPressed: () {
              scanned = false;
              setState(() => message = null);
            },
            child: const Text("Scan Again"),
          ),
        ],
      ),
    );
  }
}
