import 'package:supabase_flutter/supabase_flutter.dart';

class ParticipationService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  Future<int> getStudentPoints(String studentId) async {
    final res = await _supabase
        .from('profiles')
        .select('participation_points')
        .eq('id', studentId)
        .maybeSingle();

    return res?['participation_points'] ?? 0;
  }

  RealtimeChannel listenToStudentPoints({
    required String studentId,
    required void Function(int points) onUpdate,
  }) {
    final channel = _supabase.channel('student-points-$studentId');

    channel.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'profiles',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'id',
        value: studentId,
      ),
      callback: (payload) {
        final newPoints =
            payload.newRecord['participation_points'] ?? 0;
        onUpdate(newPoints);
      },
    );

    channel.subscribe();
    return channel;
  }

  Future<List<Map<String, dynamic>>> getClassStudents(
      String classId) async {
    final res = await _supabase
        .from('class_students')
        .select('student_id')
        .eq('class_id', classId);

    final students = List<Map<String, dynamic>>.from(res);

    for (int i = 0; i < students.length; i++) {
      final studentId = students[i]['student_id'];

      final profile = await _supabase
          .from('profiles')
          .select('id, full_name, participation_points')
          .eq('id', studentId)
          .maybeSingle();

      students[i]['profiles'] = profile;
    }

    return students;
  }

  Future<void> addPoints({
    required String classId,
    required String studentId,
    required int points,
  }) async {
    final teacherId = _supabase.auth.currentUser!.id;

    final profile = await _supabase
        .from('profiles')
        .select('participation_points')
        .eq('id', studentId)
        .maybeSingle();

    final currentPoints = profile?['participation_points'] ?? 0;
    final newPoints = currentPoints + points;

    await _supabase
        .from('profiles')
        .update({'participation_points': newPoints})
        .eq('id', studentId)
        .select();

    await _supabase.from('participation_logs').insert({
      'class_id': classId,
      'student_id': studentId,
      'teacher_id': teacherId,
      'points': points,
    });
  }
}
