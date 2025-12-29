import 'package:flutter/material.dart';
import '../../services/class_service.dart';
import '../../supabase_client.dart';
import '../../primary_button.dart';
import '../../soft_text_field.dart';

class CreateClassScreen extends StatefulWidget {
  @override
  _CreateClassScreenState createState() => _CreateClassScreenState();
}

class _CreateClassScreenState extends State<CreateClassScreen> {
  final TextEditingController nameController = TextEditingController();
  final ClassService classService = ClassService();
  bool isLoading = false;

  void _createClass() async {
    setState(() => isLoading = true);

    final teacherId =
        SupabaseClientInstance.supabase.auth.currentUser!.id;
    final code =
        await classService.createClass(nameController.text, teacherId);

    setState(() => isLoading = false);

    if (code != null && code.length == 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Class created! Code: $code")),
      );
      nameController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(code ?? "Error creating class")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Class"),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.green.shade200,
                  child: Icon(
                    Icons.class_rounded,
                    color: Colors.green.shade800,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    "New Class",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                SoftTextField(
                  controller: nameController,
                  label: "Class Name",
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          isLoading
              ? const Center(child: CircularProgressIndicator())
              : PrimaryButton(
                  text: "Create Class",
                  onTap: _createClass,
                ),
        ],
      ),
    );
  }
}
