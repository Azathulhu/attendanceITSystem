import 'package:flutter/material.dart';
import '../../services/class_service.dart';
import '../../supabase_client.dart';

class JoinClassScreen extends StatefulWidget {
  @override
  _JoinClassScreenState createState() => _JoinClassScreenState();
}

class _JoinClassScreenState extends State<JoinClassScreen> {
  final TextEditingController codeController = TextEditingController();
  final ClassService classService = ClassService();
  bool isLoading = false;

  void _joinClass() async {
    setState(() => isLoading = true);

    final studentId = SupabaseClientInstance.supabase.auth.currentUser!.id;
    final error = await classService.joinClass(codeController.text, studentId);

    setState(() => isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? "Successfully joined the class!")),
    );

    if (error == null) codeController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Join Class")),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: codeController,
              decoration: InputDecoration(labelText: "Enter Class Code"),
            ),
            SizedBox(height: 20),
            isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(onPressed: _joinClass, child: Text("Join Class")),
          ],
        ),
      ),
    );
  }
}
