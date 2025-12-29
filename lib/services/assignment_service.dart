import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class AssignmentService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> createAssignment({
    required String classId,
    required String title,
    String? description,
    DateTime? dueDate,
    required String assignmentType,
    Uint8List? instructionBytes,
    String? instructionName,
  }) async {
    String? instructionPath;

    if (instructionBytes != null && instructionName != null) {
      instructionPath =
          'instructions/$classId/${DateTime.now().millisecondsSinceEpoch}_$instructionName';

      await _supabase.storage
          .from('assignment_instructions')
          .uploadBinary(
            instructionPath,
            instructionBytes,
            fileOptions: const FileOptions(upsert: true),
          );
    }

    await _supabase.from('assignments').insert({
      'class_id': classId,
      'teacher_id': _supabase.auth.currentUser!.id,
      'title': title,
      'description': description,
      'due_date': dueDate?.toIso8601String(),
      'assignment_type': assignmentType,
      'instruction_file_url': instructionPath,
      'is_locked': false,
    });
  }

  Future<void> updateAssignment({
    required String assignmentId,
    required String title,
    String? description,
    DateTime? dueDate,
  }) async {
    await _supabase.from('assignments').update({
      'title': title,
      'description': description,
      'due_date': dueDate?.toIso8601String(),
    }).eq('id', assignmentId);
  }

  Future<void> setAssignmentLock(
    String assignmentId,
    bool locked,
  ) async {
    await _supabase
        .from('assignments')
        .update({'is_locked': locked})
        .eq('id', assignmentId);
  }

  Future<void> deleteAssignment(String assignmentId) async {
    await _supabase
        .from('assignments')
        .delete()
        .eq('id', assignmentId);
  }

  Future<void> updateInstructionFile({
    required String assignmentId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final assignment = await _supabase
        .from('assignments')
        .select('class_id')
        .eq('id', assignmentId)
        .single();

    final path =
        'instructions/${assignment['class_id']}/${DateTime.now().millisecondsSinceEpoch}_$fileName';

    await _supabase.storage
        .from('assignment_instructions')
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );

    await _supabase
        .from('assignments')
        .update({'instruction_file_url': path})
        .eq('id', assignmentId);
  }

  Future<List<Map<String, dynamic>>> getAssignments(String classId) async {
    await lockExpiredAssignments();
    final res = await _supabase
        .from('assignments')
        .select()
        .eq('class_id', classId)
        .order('created_at');

    final list = List<Map<String, dynamic>>.from(res);

    for (final a in list) {
      if (a['instruction_file_url'] != null) {
        a['instruction_signed_url'] =
            await _supabase.storage
                .from('assignment_instructions')
                .createSignedUrl(a['instruction_file_url'], 900);
      }
    }

    return list;
  }

  Future<String?> submitAssignment({
    required String assignmentId,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    final userId = _supabase.auth.currentUser!.id;

    final assignment = await _supabase
        .from('assignments')
        .select('is_locked, due_date')
        .eq('id', assignmentId)
        .single();

    if (assignment['is_locked'] == true) { 
      return "Submissions are closed";
    }

    final due = assignment['due_date'];
    if (due != null &&
        DateTime.now().isAfter(DateTime.parse(due))) {
      return "Submission is past due";
    }

    final path =
        'submissions/$assignmentId/$userId/${DateTime.now().millisecondsSinceEpoch}_$fileName';

    await _supabase.storage
        .from('assignment_uploads')
        .uploadBinary(
          path,
          fileBytes,
          fileOptions: const FileOptions(upsert: true),
        );

    await _supabase.from('assignment_submissions').upsert({
      'assignment_id': assignmentId,
      'student_id': userId,
      'file_url': path,
    });

    return null;
  }

  Future<void> unsubmit(String assignmentId, String studentId) async {
    final submission = await _supabase
        .from('assignment_submissions')
        .select('file_url')
        .eq('assignment_id', assignmentId)
        .eq('student_id', studentId)
        .maybeSingle();

    if (submission == null) return;

    final filePath = submission['file_url'];

    if (filePath != null) {
      await _supabase.storage
          .from('assignment_uploads')
          .remove([filePath]);
    }

    await _supabase
        .from('assignment_submissions')
        .delete()
        .eq('assignment_id', assignmentId)
        .eq('student_id', studentId);
  }

  Future<Map<String, dynamic>?> getMySubmission(String assignmentId) async {
    final userId = _supabase.auth.currentUser!.id;

    final res = await _supabase
        .from('assignment_submissions')
        .select('id, file_url, grade, feedback')
        .eq('assignment_id', assignmentId)
        .eq('student_id', userId)
        .maybeSingle();

    if (res == null) return null;

    res['signed_url'] = await _supabase.storage
        .from('assignment_uploads')
        .createSignedUrl(res['file_url'], 900);

    return res;
  }

  Future<List<Map<String, dynamic>>> getSubmissions(String assignmentId) async {
    final subs = await _supabase
        .from('assignment_submissions')
        .select('id, file_url, submitted_at, student_id, grade, feedback')
        .eq('assignment_id', assignmentId);
  
    final submissions = List<Map<String, dynamic>>.from(subs);
  
    if (submissions.isEmpty) return submissions;
  
    final studentIds =
        submissions.map((s) => s['student_id']).toSet().toList();
  
    final profilesRes = await _supabase
        .from('profiles')
        .select('id, full_name')
        .inFilter('id', studentIds);
  
    final profiles = {
      for (final p in profilesRes) p['id']: p['full_name']
    };
  
    final assignment = await _supabase
        .from('assignments')
        .select('max_points')
        .eq('id', assignmentId)
        .single();
  
    for (final s in submissions) {
      s['signed_url'] = await _supabase.storage
          .from('assignment_uploads')
          .createSignedUrl(s['file_url'], 900);
  
      s['student_name'] =
          profiles[s['student_id']] ?? 'Unknown Student';
  
      s['max_points'] = assignment['max_points'];
    }
  
    return submissions;
  }

  Future<void> gradeSubmission({
    required String submissionId,
    required int grade,
    String? feedback,
  }) async {
    await _supabase.from('assignment_submissions').update({
      'grade': grade,
      'feedback': feedback,
    }).eq('id', submissionId);
  }
  Future<void> lockExpiredAssignments() async {
    await _supabase.rpc('lock_expired_assignments');
  }

  Future<void> updateAssignmentMaxPoints({
    required String assignmentId,
    required int maxPoints,
  }) async {
    await _supabase
        .from('assignments')
        .update({'max_points': maxPoints})
        .eq('id', assignmentId);
  }
}
