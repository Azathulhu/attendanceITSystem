import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class AttendanceService {
  final SupabaseClient _supabase = Supabase.instance.client;

  
  Future<String?> startSession(String classId, String teacherId, int durationMinutes) async {
    try {
      final qrCode = Uuid().v4();
      final startTime = DateTime.now().toUtc();
      final endTime = startTime.add(Duration(minutes: durationMinutes));

      await _supabase.from('attendance_sessions').insert({
        'class_id': classId,
        'teacher_id': teacherId,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
        'qr_code': qrCode,
      });

      return qrCode;
    } catch (e) {
      return e.toString();
    }
  }

  Future<List<Map<String, dynamic>>> getActiveSessions(String classId) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final response = await _supabase
        .from('attendance_sessions')
        .select('*')
        .eq('class_id', classId)
        .gte('end_time', now);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<String?> scanQR(String qrCode, String studentId) async {
    try {
      final session = await _supabase
          .from('attendance_sessions')
          .select('*')
          .eq('qr_code', qrCode)
          .maybeSingle();

      if (session == null) return "Invalid QR code";

      final now = DateTime.now().toUtc();
      final start = DateTime.parse(session['start_time']);
      final end = DateTime.parse(session['end_time']);

      String status;
      if (now.isBefore(start.add(Duration(minutes: 15)))) {
        status = "on_time";
      } else if (now.isBefore(start.add(Duration(minutes: 30)))) {
        status = "late";
      } else {
        status = "absent";
      }

      final existing = await _supabase
          .from('attendance_records')
          .select('*')
          .eq('session_id', session['id'])
          .eq('student_id', studentId)
          .maybeSingle();

      if (existing != null) return "Already scanned";

      await _supabase.from('attendance_records').insert({
        'session_id': session['id'],
        'student_id': studentId,
        'status': status,
      });

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<List<Map<String, dynamic>>> getSessionAttendance(String sessionId) async {
    final response = await _supabase
        .from('attendance_records')
        .select('student_id, status, scanned_at, profiles(full_name)')
        .eq('session_id', sessionId);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getAttendanceHistory(String classId) async {
    final sessions = await _supabase
        .from('attendance_sessions')
        .select('id, start_time')
        .eq('class_id', classId)
        .order('start_time', ascending: false);

    List<Map<String, dynamic>> history = [];

    for (var session in sessions) {
      final records = await _supabase
          .from('attendance_records')
          .select('student_id, status, scanned_at, profiles(full_name)')
          .eq('session_id', session['id']);

      history.add({
        'session_date': session['start_time'],
        'records': records,
      });
    }

    return history;
  }
}
