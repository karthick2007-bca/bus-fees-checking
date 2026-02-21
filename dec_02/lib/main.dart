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

  Future<void> _checkStudentRegistration(String phone, String dob) async {
    try {
      final students = await ApiService.getStudents();
      print('All students: $students');
      
      final student = students.firstWhere(
        (s) => s['phone'] == phone && s['dob']?.toString().split('T')[0] == dob,
        orElse: () => {},
      );

      print('Found student: $student');
      print('Student name: ${student['name']}');
      print('Amount paid: ${student['amountPaid']}');
      print('Total due: ${student['totalDue']}');

      setState(() {
        _loggedInPhone = phone;
        _loggedInDob = dob;
        
        // Check if student has registered (name filled) AND paid
        bool hasRegistered = student.isNotEmpty && 
                            student['name'] != null && 
                            student['name'].toString().trim().isNotEmpty;
        
        bool hasPaid = student['amountPaid'] != null && 
                      student['totalDue'] != null && 
                      student['amountPaid'] >= student['totalDue'];
        
        if (hasRegistered && hasPaid) {
          print('Showing REPORT - Registered and Paid');
          _currentView = AppView.studentReport;
        } else {
          print('Showing REGISTRATION - Not registered or not paid');
          _currentView = AppView.studentRegister;
        }
      });
    } catch (e) {
      print('Error: $e');
      setState(() => _currentView = AppView.studentRegister);
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
            setState(() {
              _loggedInPhone = phone;
              _loggedInDob = dob;
              _currentView = AppView.studentReport;
            });
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
          onLogout: () => setState(() => _currentView = AppView.landing),
        );
      default:
        return const ErrorView();
    }
  }
}