import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/class_service.dart';
import '../../services/auth_service.dart';
import '../../services/participation_service.dart';
import '../../supabase_client.dart';
import 'join_class_screen.dart';
import '../login_screen.dart';
import 'student_qr_scan_screen.dart';
import 'student_assignments_screen.dart';
import '../../primary_button.dart';

class StudentDashboard extends StatefulWidget {
  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final ClassService classService = ClassService();
  final AuthService authService = AuthService();
  final ParticipationService participationService = ParticipationService();

  List<Map<String, dynamic>> classes = [];
  bool isLoading = true;

  int participationPoints = 0;
  String fullName = '';

  RealtimeChannel? _pointsChannel;

  @override
  void initState() {
    super.initState();
    _loadStudentProfile();
    _loadClasses();
    _initParticipationRealtime();
  }

  @override
  void dispose() {
    if (_pointsChannel != null) {
      Supabase.instance.client.removeChannel(_pointsChannel!);
    }
    super.dispose();
  }

  Future<void> _loadStudentProfile() async {
    final userId =
        SupabaseClientInstance.supabase.auth.currentUser!.id;

    final profile = await SupabaseClientInstance.supabase
        .from('profiles')
        .select('full_name')
        .eq('id', userId)
        .maybeSingle();

    if (!mounted) return;

    setState(() {
      fullName = profile?['full_name'] ?? '';
    });
  }

  Future<void> _loadClasses() async {
    final studentId =
        SupabaseClientInstance.supabase.auth.currentUser!.id;
    final result = await classService.getStudentClasses(studentId);

    setState(() {
      classes = result;
      isLoading = false;
    });
  }

  Future<void> _loadParticipationPoints() async {
    final studentId =
        SupabaseClientInstance.supabase.auth.currentUser!.id;

    final pts =
        await participationService.getStudentPoints(studentId);

    if (!mounted) return;

    setState(() {
      participationPoints = pts;
    });
  }

  void _initParticipationRealtime() async {
    final studentId =
        SupabaseClientInstance.supabase.auth.currentUser!.id;

    await _loadParticipationPoints();

    if (_pointsChannel != null) {
      Supabase.instance.client.removeChannel(_pointsChannel!);
    }

    _pointsChannel = Supabase.instance.client
        .channel('student-points-$studentId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'profiles',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: studentId,
          ),
          callback: (payload) {
            if (!mounted) return;

            final newPoints =
                payload.newRecord['participation_points'];
            if (newPoints == null) return;

            setState(() {
              participationPoints = (newPoints as num).toInt();
            });
          },
        )
        .subscribe();
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        title: const Text("Log Out"),
        content: const Text("Do you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Yes"),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await authService.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.green.shade600,
                    Colors.green.shade400,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.25),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Welcome back",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        fullName.isEmpty ? 'Student' : fullName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "Points",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          participationPoints.toString(),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            PrimaryButton(
              text: "Join Class",
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => JoinClassScreen()),
                );
                _loadClasses();
              },
            ),

            const SizedBox(height: 28),

            const Text(
              "Your Classes",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 14),

            classes.isEmpty
                ? Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Column(
                      children: const [
                        Icon(
                          Icons.school_outlined,
                          size: 60,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 12),
                        Text(
                          "No classes joined",
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: List.generate(classes.length, (index) {
                      final cls = classes[index]['classes'];
                      final classId = classes[index]['class_id'];

                      return AnimatedContainer(
                        duration:
                            const Duration(milliseconds: 250),
                        margin:
                            const EdgeInsets.symmetric(vertical: 10),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(26),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green
                                  .withOpacity(0.12),
                              blurRadius: 14,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.green
                                        .withOpacity(0.15),
                                    borderRadius:
                                        BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    Icons.class_,
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        cls['name'],
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight:
                                              FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Code: ${cls['code']}",
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.end,
                              children: [
                                _ActionIcon(
                                  icon: Icons.assignment,
                                  label: "Assignments",
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            StudentAssignmentsScreen(
                                          classId: classId,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 12),
                                _ActionIcon(
                                  icon: Icons.qr_code_scanner,
                                  label: "Attendance",
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            StudentQRScanScreen(
                                          classId: classId,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
          ],
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionIcon({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.green, size: 20),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
