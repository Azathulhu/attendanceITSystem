import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../supabase_client.dart';
import 'teachers/teacher_dashboard.dart';
import 'students/student_dashboard.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService authService = AuthService();
  String role = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  void _loadUserRole() async {
    final userId = SupabaseClientInstance.supabase.auth.currentUser!.id;
    final response = await SupabaseClientInstance.supabase
        .from('profiles')
        .select('role')
        .eq('id', userId)
        .maybeSingle();

    setState(() {
      role = response?['role'] ?? 'student';
      isLoading = false;
    });
  }

  void _logout() async {
    await authService.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      body: role == 'teacher'
          ? TeacherDashboard()
          : StudentDashboard(),
    );
  }
}
