import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Student Database',

      theme: ThemeData(
        useMaterial3: true,

        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
        ),

        scaffoldBackgroundColor: const Color(0xFFF5F0FF),

        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF673AB7),
          foregroundColor: Colors.white,
          centerTitle: true,
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(
              color: Color(0xFFB39DDB),
            ),
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(
              color: Color(0xFF673AB7),
              width: 2,
            ),
          ),

          labelStyle: const TextStyle(
            color: Color(0xFF673AB7),
          ),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF673AB7),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              vertical: 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),
      ),

      home: const StudentPage(),
    );
  }
}

class StudentPage extends StatefulWidget {
  const StudentPage({super.key});

  @override
  State<StudentPage> createState() => _StudentPageState();
}

class _StudentPageState extends State<StudentPage> {
  final DatabaseHelper dbHelper = DatabaseHelper();

  final TextEditingController nameController =
      TextEditingController();

  final TextEditingController courseController =
      TextEditingController();

  List<Map<String, dynamic>> students = [];

  @override
  void initState() {
    super.initState();
    loadStudents();
  }

  // ==========================
  // SQLITE READ
  // ==========================

  Future<void> loadStudents() async {
    try {
      final data = await dbHelper.getStudents();

      setState(() {
        students = data;
      });
    } catch (e) {
      debugPrint("SQLite Error: $e");
    }
  }

  // ==========================
  // FIREBASE CREATE
  // ==========================

  Future<void> addStudentToFirebase(
      String name, String course) async {
    await FirebaseFirestore.instance
        .collection('students')
        .add({
      'name': name,
      'course': course,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ==========================
  // CREATE - SQLITE + FIREBASE
  // ==========================

  Future<void> addStudent() async {
    final name = nameController.text.trim();
    final course = courseController.text.trim();

    if (name.isEmpty || course.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter name and course',
          ),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    try {
      // Save to SQLite
      await dbHelper.insertStudent(
        name,
        course,
      );

      // Save to Firebase Firestore
      await addStudentToFirebase(
        name,
        course,
      );

      // Clear fields
      nameController.clear();
      courseController.clear();

      // Refresh SQLite list
      await loadStudents();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Student added to SQLite and Firebase!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint("Add Student Error: $e");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ==========================
  // SQLITE UPDATE
  // ==========================

  Future<void> editStudent(
    int id,
    String oldName,
    String oldCourse,
  ) async {
    final nameEditController =
        TextEditingController(text: oldName);

    final courseEditController =
        TextEditingController(text: oldCourse);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            '✏️ Update Student',
          ),

          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameEditController,
                decoration: const InputDecoration(
                  labelText: 'Student Name',
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller: courseEditController,
                decoration: const InputDecoration(
                  labelText: 'Course',
                ),
              ),
            ],
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),

            ElevatedButton(
              onPressed: () async {
                await dbHelper.updateStudent(
                  id,
                  nameEditController.text.trim(),
                  courseEditController.text.trim(),
                );

                Navigator.pop(context);

                await loadStudents();
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  // ==========================
  // SQLITE DELETE
  // ==========================

  Future<void> deleteStudent(int id) async {
    await dbHelper.deleteStudent(id);

    await loadStudents();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Student deleted from SQLite!',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    courseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        title: const Text(
          '📚 Student Database',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [

            // ==========================
            // STUDENT NAME
            // ==========================

            TextField(
              controller: nameController,

              decoration: const InputDecoration(
                labelText: 'Student Name',
                prefixIcon: Icon(Icons.person),
              ),
            ),

            const SizedBox(height: 15),

            // ==========================
            // COURSE
            // ==========================

            TextField(
              controller: courseController,

              decoration: const InputDecoration(
                labelText: 'Course',
                prefixIcon: Icon(Icons.school),
              ),
            ),

            const SizedBox(height: 20),

            // ==========================
            // ADD BUTTON
            // ==========================

            SizedBox(
              width: double.infinity,

              child: ElevatedButton.icon(
                onPressed: addStudent,

                icon: const Icon(
                  Icons.person_add,
                ),

                label: const Text(
                  'ADD STUDENT',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 25),

            // ==========================
            // SQLITE TITLE
            // ==========================

            Container(
              width: double.infinity,

              padding: const EdgeInsets.all(15),

              decoration: BoxDecoration(
                color: const Color(0xFF673AB7),
                borderRadius: BorderRadius.circular(15),
              ),

              child: const Text(
                '👨‍🎓 SQLite Student Records',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 10),

            // ==========================
            // SQLITE STUDENT LIST
            // ==========================

            Expanded(
              child: students.isEmpty

                  ? const Center(
                      child: Text(
                        'No students found',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 17,
                        ),
                      ),
                    )

                  : ListView.builder(
                      itemCount: students.length,

                      itemBuilder: (context, index) {
                        final student = students[index];

                        return Card(
                          elevation: 4,

                          margin: const EdgeInsets.symmetric(
                            vertical: 6,
                          ),

                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(15),
                          ),

                          child: ListTile(

                            leading: CircleAvatar(
                              backgroundColor:
                                  const Color(0xFF673AB7),

                              child: Text(
                                '${student['id']}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ),

                            title: Text(
                              student['name'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                              ),
                            ),

                            subtitle: Text(
                              '📖 ${student['course'] ?? ''}',
                            ),

                            trailing: Row(
                              mainAxisSize:
                                  MainAxisSize.min,

                              children: [

                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                  ),

                                  onPressed: () {
                                    editStudent(
                                      student['id'],
                                      student['name'],
                                      student['course'],
                                    );
                                  },
                                ),

                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),

                                  onPressed: () {
                                    deleteStudent(
                                      student['id'],
                                    );
                                  },
                                ),
                              ],
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