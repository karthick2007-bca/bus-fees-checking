import 'package:flutter/material.dart';
import 'views/landing_view.dart';
import 'views/admin_login_view.dart';
import 'views/student_login_view.dart';
import 'views/student_register_view.dart';
import 'views/student_report.dart';
import 'views/admin_dashboard.dart';
import 'views/error_view.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TransitPayApp());
}

enum AppView {
  landing,
  adminLogin,
  studentLogin,
  admin,
  studentRegister,
  studentReport
}

class TransitPayApp extends StatelessWidget {
  const TransitPayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TransitPay',
      theme: ThemeData(
        primaryColor: const Color(0xFF4F46E5),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        fontFamily: 'Inter',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),
      ),
      home: const AppController(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AppController extends StatefulWidget {
  const AppController({super.key});

  @override
  State<AppController> createState() => _AppControllerState();
}

class _AppControllerState extends State<AppController> {
  AppView _currentView = AppView.landing;
  String? _loggedInPhone;
  String? _loggedInDob;
  Map<String, dynamic>? _reportInitialData;

  Future<void> _checkStudentRegistration(String phone, String dob) async {
    try {
      final students = await ApiService.getStudents();
      final student = students.firstWhere(
        (s) => s['phone'] == phone && s['dob']?.toString().split('T')[0] == dob,
        orElse: () => {},
      );

      setState(() {
        _loggedInPhone = phone;
        _loggedInDob = dob;
        _reportInitialData = null;

        bool hasRegistered = student.isNotEmpty &&
            student['name'] != null &&
            student['name'].toString().trim().isNotEmpty;

        bool hasPaid = student['status'] == 'succeed';

        if (hasRegistered && hasPaid) {
          _currentView = AppView.studentReport;
        } else {
          _currentView = AppView.studentRegister;
        }
      });
    } catch (e) {
      setState(() => _currentView = AppView.studentRegister);
    }
  }

  // Fetch latest report for student from reports collection
  Future<void> _checkMyReport(String phone, String dob) async {
    try {
      // First try reports collection
      final reports = await ApiService.getReports();
      final studentReports = reports.where((r) {
        final rPhone = r['phone']?.toString();
        final rDob = r['dob']?.toString().split('T')[0];
        return rPhone == phone && rDob == dob;
      }).toList();

      Map<String, dynamic>? reportData;

      if (studentReports.isNotEmpty) {
        // Sort by latest
        studentReports.sort((a, b) {
          final aDate = DateTime.tryParse(a['generatedAt']?.toString() ?? '') ?? DateTime(0);
          final bDate = DateTime.tryParse(b['generatedAt']?.toString() ?? '') ?? DateTime(0);
          return bDate.compareTo(aDate);
        });
        reportData = Map<String, dynamic>.from(studentReports.first);
      } else {
        // Fallback: get from students collection
        final students = await ApiService.getStudents();
        final student = students.firstWhere(
          (s) => s['phone']?.toString() == phone &&
              s['dob']?.toString().split('T')[0] == dob,
          orElse: () => {},
        );
        if (student.isNotEmpty) {
          reportData = Map<String, dynamic>.from(student);
        }
      }

      setState(() {
        _loggedInPhone = phone;
        _loggedInDob = dob;
        _reportInitialData = reportData;
        _currentView = AppView.studentReport;
      });
    } catch (e) {
      setState(() {
        _loggedInPhone = phone;
        _loggedInDob = dob;
        _reportInitialData = null;
        _currentView = AppView.studentReport;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_currentView) {
      case AppView.landing:
        return LandingView(
          onAdminLogin: () => setState(() => _currentView = AppView.adminLogin),
          onStudentLogin: () => setState(() => _currentView = AppView.studentLogin),
        );
      case AppView.adminLogin:
        return AdminLoginView(
          onBack: () => setState(() => _currentView = AppView.landing),
          onLoginSuccess: () => setState(() => _currentView = AppView.admin),
        );
      case AppView.studentLogin:
        return StudentLoginView(
          onBack: () => setState(() => _currentView = AppView.landing),
          onLoginSuccess: (phone, dob) async {
            await _checkStudentRegistration(phone, dob);
          },
          onRegister: () {},
          onCheckReport: (phone, dob) async {
            await _checkMyReport(phone, dob);
          },
        );
      case AppView.studentRegister:
        return StudentRegisterView(
          onBack: () => setState(() => _currentView = AppView.studentLogin),
          onRegisterSuccess: () {
            setState(() => _currentView = AppView.studentReport);
          },
          onSuccess: () {},
        );
      case AppView.admin:
        return AdminDashboard(
          onLogout: () => setState(() => _currentView = AppView.landing),
        );
      case AppView.studentReport:
        return StudentReport(
          phone: _loggedInPhone ?? '',
          dob: _loggedInDob ?? '',
          initialData: _reportInitialData,
          onLogout: () => setState(() => _currentView = AppView.landing),
        );
      default:
        return const ErrorView();
    }
  }
}
