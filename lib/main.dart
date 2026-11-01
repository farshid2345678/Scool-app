import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'database_helper.dart';

void main() {
  runApp(const SchoolApp());
}

class SchoolApp extends StatelessWidget {
  const SchoolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: ' مدیریت مدرسه پسرانه جعفر صادق ',
      debugShowCheckedModeBanner: false,
      locale: const Locale('fa', 'IR'),
      supportedLocales: const [Locale('fa', 'IR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        fontFamily: 'Roboto',
      ),
      home: const StudentListScreen(),
    );
  }
}

// ----------------- صفحه لیست دانش‌آموزان -----------------
class StudentListScreen extends StatefulWidget {
  const StudentListScreen({super.key});

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  List<Student> students = [];
  String searchQuery = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    refreshStudents();
  }

  Future refreshStudents() async {
    setState(() => isLoading = true);
    students = await DatabaseHelper.instance.getAllStudents(searchQuery: searchQuery);
    setState(() => isLoading = false);
  }

  void _callPhone(String phone) async {
    final Uri url = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('دفتر دانش‌آموزان مدرسه'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'جستجو با نام، نام خانوادگی یا کد ملی...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (val) {
                searchQuery = val;
                refreshStudents();
              },
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : students.isEmpty
                    ? const Center(child: Text('هیچ دانش‌آموزی یافت نشد.'))
                    : ListView.builder(
                        itemCount: students.length,
                        itemBuilder: (context, index) {
                          final s = students[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            elevation: 2,
                            child: ListTile(
                              leading: CircleAvatar(
                                radius: 26,
                                backgroundImage: s.photoPath != null && s.photoPath!.isNotEmpty
                                    ? FileImage(File(s.photoPath!))
                                    : null,
                                child: s.photoPath == null || s.photoPath!.isEmpty
                                    ? const Icon(Icons.person)
                                    : null,
                              ),
                              title: Text('${s.firstName} ${s.lastName}',
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('کلاس: ${s.className} | پایه: ${s.grade} | شیفت: ${s.shift}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.phone, color: Colors.green),
                                    onPressed: () => _callPhone(s.fatherPhone),
                                    tooltip: 'تماس با پدر',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => StudentFormScreen(student: s)),
                                      );
                                      refreshStudents();
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _confirmDelete(s.id!),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const StudentFormScreen()),
          );
          refreshStudents();
        },
        icon: const Icon(Icons.add),
        label: const Text('ثبت دانش‌آموز جدید'),
      ),
    );
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف پرونده'),
        content: const Text('آیا از حذف این دانش‌آموز اطمینان دارید؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await DatabaseHelper.instance.deleteStudent(id);
              Navigator.pop(ctx);
              refreshStudents();
            },
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ----------------- فرم ثبت و ویرایش دانش‌آموز -----------------
class StudentFormScreen extends StatefulWidget {
  final Student? student;
  const StudentFormScreen({super.key, this.student});

  @override
  State<StudentFormScreen> createState() => _StudentFormScreenState();
}

class _StudentFormScreenState extends State<StudentFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nationalCode;
  late TextEditingController _firstName;
  late TextEditingController _lastName;
  late TextEditingController _birthDate;
  late TextEditingController _fatherName;
  late TextEditingController _motherName;
  late TextEditingController _fatherPhone;
  late TextEditingController _motherPhone;
  late TextEditingController _homePhone;
  late TextEditingController _emergencyPhone;
  late TextEditingController _address;
  late TextEditingController _grade;
  late TextEditingController _className;
  late TextEditingController _teacherName;
  late TextEditingController _medicalNotes;
  late TextEditingController _counselingNotes;

  String _shift = 'صبح';
  String? _photoPath;

  @override
  void initState() {
    super.initState();
    final s = widget.student;
    _nationalCode = TextEditingController(text: s?.nationalCode ?? '');
    _firstName = TextEditingController(text: s?.firstName ?? '');
    _lastName = TextEditingController(text: s?.lastName ?? '');
    _birthDate = TextEditingController(text: s?.birthDate ?? '');
    _fatherName = TextEditingController(text: s?.fatherName ?? '');
    _motherName = TextEditingController(text: s?.motherName ?? '');
    _fatherPhone = TextEditingController(text: s?.fatherPhone ?? '');
    _motherPhone = TextEditingController(text: s?.motherPhone ?? '');
    _homePhone = TextEditingController(text: s?.homePhone ?? '');
    _emergencyPhone = TextEditingController(text: s?.emergencyPhone ?? '');
    _address = TextEditingController(text: s?.address ?? '');
    _grade = TextEditingController(text: s?.grade ?? '');
    _className = TextEditingController(text: s?.className ?? '');
    _teacherName = TextEditingController(text: s?.teacherName ?? '');
    _medicalNotes = TextEditingController(text: s?.medicalNotes ?? '');
    _counselingNotes = TextEditingController(text: s?.counselingNotes ?? '');
    _shift = s?.shift ?? 'صبح';
    _photoPath = s?.photoPath;
  }

  Future _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() => _photoPath = pickedFile.path);
    }
  }

  Future _saveStudent() async {
    if (!_formKey.currentState!.validate()) return;

    final student = Student(
      id: widget.student?.id,
      nationalCode: _nationalCode.text.trim(),
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      photoPath: _photoPath,
      birthDate: _birthDate.text.trim(),
      fatherName: _fatherName.text.trim(),
      motherName: _motherName.text.trim(),
      fatherPhone: _fatherPhone.text.trim(),
      motherPhone: _motherPhone.text.trim(),
      homePhone: _homePhone.text.trim(),
      emergencyPhone: _emergencyPhone.text.trim(),
      address: _address.text.trim(),
      grade: _grade.text.trim(),
      className: _className.text.trim(),
      teacherName: _teacherName.text.trim(),
      shift: _shift,
      medicalNotes: _medicalNotes.text.trim(),
      counselingNotes: _counselingNotes.text.trim(),
    );

    if (widget.student == null) {
      await DatabaseHelper.instance.insertStudent(student);
    } else {
      await DatabaseHelper.instance.updateStudent(student);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.student == null ? 'ثبت‌نام دانش‌آموز جدید' : 'ویرایش پرونده'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: _photoPath != null ? FileImage(File(_photoPath!)) : null,
                    child: _photoPath == null ? const Icon(Icons.person, size: 50) : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      backgroundColor: Colors.indigo,
                      radius: 18,
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                        onPressed: _pickImage,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildSectionTitle('مشخصات فردی'),
            Row(
              children: [
                Expanded(child: _buildTextField(_firstName, 'نام', true)),
                const SizedBox(width: 8),
                Expanded(child: _buildTextField(_lastName, 'نام خانوادگی', true)),
              ],
            ),
            _buildTextField(_nationalCode, 'کد ملی (۱۰ رقم)', true, keyboard: TextInputType.number),
            _buildTextField(_birthDate, 'تاریخ تولد (مثال: ۱۳۸۸/۰۵/۰۲)', false),
            
            _buildSectionTitle('اطلاعات تحصیلی و کلاسی'),
            Row(
              children: [
                Expanded(child: _buildTextField(_grade, 'پایه (مثلاً هفتم)', true)),
                const SizedBox(width: 8),
                Expanded(child: _buildTextField(_className, 'شماره/نام کلاس', true)),
              ],
            ),
            _buildTextField(_teacherName, 'نام معلم/راهنما', false),
            DropdownButtonFormField<String>(
              value: _shift,
              decoration: const InputDecoration(labelText: 'نوبت تحصیلی'),
              items: const [
                DropdownMenuItem(value: 'صبح', child: Text('صبح')),
                DropdownMenuItem(value: 'عصر', child: Text('عصر')),
              ],
              onChanged: (val) => setState(() => _shift = val!),
            ),

            _buildSectionTitle('اطلاعات خانواده و تماس'),
            Row(
              children: [
                Expanded(child: _buildTextField(_fatherName, 'نام پدر', false)),
                const SizedBox(width: 8),
                Expanded(child: _buildTextField(_motherName, 'نام مادر', false)),
              ],
            ),
            _buildTextField(_fatherPhone, 'تلفن همراه پدر', true, keyboard: TextInputType.phone),
            _buildTextField(_motherPhone, 'تلفن همراه مادر', false, keyboard: TextInputType.phone),
            Row(
              children: [
                Expanded(child: _buildTextField(_homePhone, 'تلفن منزل', false, keyboard: TextInputType.phone)),
                const SizedBox(width: 8),
                Expanded(child: _buildTextField(_emergencyPhone, 'تلفن اضطراری', false, keyboard: TextInputType.phone)),
              ],
            ),
            _buildTextField(_address, 'آدرس منزل', false, maxLines: 2),

            _buildSectionTitle('پرونده سلامت و مشاوره'),
            _buildTextField(_medicalNotes, 'سوابق بیماری یا حساسیت', false, maxLines: 2),
            _buildTextField(_counselingNotes, 'یادداشت‌های محرمانه مشاوره‌ای', false, maxLines: 2),

            const SizedBox(height: 25),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _saveStudent,
              child: const Text('ذخیره اطلاعات در پرونده', style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.indigo)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, bool isRequired,
      {TextInputType keyboard = TextInputType.text, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        validator: isRequired
            ? (value) => (value == null || value.trim().isEmpty) ? 'تکمیل این فیلد الزامی است' : null
            : null,
      ),
    );
  }
}
