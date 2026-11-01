import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class Student {
  int? id;
  String nationalCode;
  String firstName;
  String lastName;
  String? photoPath;
  String birthDate;
  String fatherName;
  String motherName;
  String fatherPhone;
  String motherPhone;
  String homePhone;
  String emergencyPhone;
  String address;
  String grade;
  String className;
  String teacherName;
  String shift;
  String medicalNotes;
  String counselingNotes;

  Student({
    this.id,
    required this.nationalCode,
    required this.firstName,
    required this.lastName,
    this.photoPath,
    required this.birthDate,
    required this.fatherName,
    required this.motherName,
    required this.fatherPhone,
    required this.motherPhone,
    required this.homePhone,
    required this.emergencyPhone,
    required this.address,
    required this.grade,
    required this.className,
    required this.teacherName,
    required this.shift,
    this.medicalNotes = '',
    this.counselingNotes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'national_code': nationalCode,
      'first_name': firstName,
      'last_name': lastName,
      'photo_path': photoPath,
      'birth_date': birthDate,
      'father_name': fatherName,
      'mother_name': motherName,
      'father_phone': fatherPhone,
      'mother_phone': motherPhone,
      'home_phone': homePhone,
      'emergency_phone': emergencyPhone,
      'address': address,
      'grade': grade,
      'class_name': className,
      'teacher_name': teacherName,
      'shift': shift,
      'medical_notes': medicalNotes,
      'counseling_notes': counselingNotes,
    };
  }

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'],
      nationalCode: map['national_code'],
      firstName: map['first_name'],
      lastName: map['last_name'],
      photoPath: map['photo_path'],
      birthDate: map['birth_date'],
      fatherName: map['father_name'],
      motherName: map['mother_name'],
      fatherPhone: map['father_phone'],
      motherPhone: map['mother_phone'],
      homePhone: map['home_phone'],
      emergencyPhone: map['emergency_phone'],
      address: map['address'],
      grade: map['grade'],
      className: map['class_name'],
      teacherName: map['teacher_name'],
      shift: map['shift'],
      medicalNotes: map['medical_notes'] ?? '',
      counselingNotes: map['counseling_notes'] ?? '',
    );
  }
}

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('school_database.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE students (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        national_code TEXT UNIQUE NOT NULL,
        first_name TEXT NOT NULL,
        last_name TEXT NOT NULL,
        photo_path TEXT,
        birth_date TEXT,
        father_name TEXT,
        mother_name TEXT,
        father_phone TEXT,
        mother_phone TEXT,
        home_phone TEXT,
        emergency_phone TEXT,
        address TEXT,
        grade TEXT,
        class_name TEXT,
        teacher_name TEXT,
        shift TEXT,
        medical_notes TEXT,
        counseling_notes TEXT
      )
    ''');
  }

  Future<int> insertStudent(Student student) async {
    final db = await instance.database;
    return await db.insert('students', student.toMap());
  }

  Future<int> updateStudent(Student student) async {
    final db = await instance.database;
    return await db.update(
      'students',
      student.toMap(),
      where: 'id = ?',
      whereArgs: [student.id],
    );
  }

  Future<int> deleteStudent(int id) async {
    final db = await instance.database;
    return await db.delete('students', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Student>> getAllStudents({String searchQuery = '', String filterClass = ''}) async {
    final db = await instance.database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (searchQuery.isNotEmpty) {
      whereClause += '(first_name LIKE ? OR last_name LIKE ? OR national_code LIKE ?)';
      whereArgs.addAll(['%$searchQuery%', '%$searchQuery%', '%$searchQuery%']);
    }

    if (filterClass.isNotEmpty) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'class_name = ?';
      whereArgs.add(filterClass);
    }

    final result = await db.query(
      'students',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'last_name ASC',
    );

    return result.map((json) => Student.fromMap(json)).toList();
  }
}
