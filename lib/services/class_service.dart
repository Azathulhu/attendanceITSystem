import 'package:supabase_flutter/supabase_flutter.dart';

class ClassService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<String?> createClass(String name, String teacherId) async {
    try {
      final code = _generateClassCode();

      await _supabase.from('classes').insert({
        'name': name,
        'code': code,
        'teacher_id': teacherId,
      });

      return code;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> joinClass(String code, String studentId) async {
    try {
      final cls = await _supabase
          .from('classes')
          .select('id')
          .eq('code', code)
          .maybeSingle();

      if (cls == null) return "Class not found";

      await _supabase.from('class_students').insert({
        'class_id': cls['id'],
        'student_id': studentId,
      });

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<List<Map<String, dynamic>>> getStudents(String classId) async {
    final response = await _supabase
        .from('class_students')
        .select('student_id')
        .eq('class_id', classId);

    List<Map<String, dynamic>> students =
        List<Map<String, dynamic>>.from(response);

    for (var i = 0; i < students.length; i++) {
      final studentId = students[i]['student_id'];

      final profile = await _supabase
          .from('profiles')
          .select('full_name, role')
          .eq('id', studentId)
          .maybeSingle();

      students[i]['profiles'] = profile;
    }

    return students;
  }

  Future<List<Map<String, dynamic>>> getTeacherClasses(
      String teacherId) async {
    final response = await _supabase
        .from('classes')
        .select('id, name, code')
        .eq('teacher_id', teacherId);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getStudentClasses(
      String studentId) async {
    final response = await _supabase
        .from('class_students')
        .select('class_id, classes(name, code)')
        .eq('student_id', studentId);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getClassStudents(
      String classId) async {
    final res = await Supabase.instance.client
        .from('class_students')
        .select('student_id, profiles(full_name, participation_points)')
        .eq('class_id', classId);

    return List<Map<String, dynamic>>.from(res);
  }

  String _generateClassCode() {
    final random =
        DateTime.now().millisecondsSinceEpoch.remainder(1000000);
    return random.toString().padLeft(6, '0');
  }
}
