import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

import '../data/database/student_dao.dart';
import '../data/models/student_model.dart';

class AuthService {
  final StudentDAO _dao = StudentDAO();

  /// ===============================
  /// REGISTER STUDENT (SEND OTP TO REAL EMAIL)
  /// ===============================
  Future<String?> registerStudent({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String gender,
  }) async {
    final exists = await _dao.isEmailExists(email);
    if (exists) return null;

    final String studentId = _generateStudentId();
    final String otp = _generateOtp();

    await _dao.insertStudentWithOtp(
      studentId: studentId,
      firstName: firstName,
      lastName: lastName,
      email: email,
      password: password,
      gender: gender,
      otp: otp,
    );

    // ✅ Send OTP via PHP backend
    await _sendOtpToEmail(email, otp);

    return studentId;
  }

  /// ===============================
  /// RESEND OTP (REGISTRATION)
  /// ===============================
  Future<bool> resendRegisterOtp(String email) async {
    final exists = await _dao.isEmailExists(email);
    if (!exists) return false;

    final String otp = _generateOtp();
    await _dao.updateOtpByEmail(email, otp);

    await _sendOtpToEmail(email, otp);

    return true;
  }

  /// ===============================
  /// VERIFY OTP (REGISTRATION)
  /// ===============================
  Future<bool> verifyOtp({
    required String email,
    required String enteredOtp,
  }) async {
    final Map<String, dynamic>? data = await _dao.getStudentByEmail(email);

    if (data == null) return false;

    final String? storedOtp = data['Verification_code'];
    if (storedOtp == null || storedOtp != enteredOtp) return false;

    await _dao.activateStudent(data['Student_id']);
    await _dao.clearOtpByEmail(email);

    return true;
  }

  /// ===============================
  /// LOGIN (ONLY ACTIVE USERS)
  /// ===============================
  Future<StudentModel?> loginStudent({
    required String email,
    required String password,
  }) async {
    final Map<String, dynamic>? data = await _dao.loginStudent(email, password);
    if (data == null) return null;
    return StudentModel.fromMap(data);
  }

  /// ===============================
  /// GET STUDENT BY EMAIL
  /// ===============================
  Future<StudentModel?> getStudentByEmail(String email) async {
    final Map<String, dynamic>? data = await _dao.getStudentByEmail(email);
    if (data == null) return null;
    return StudentModel.fromMap(data);
  }

  /// ===============================
  /// FORGOT PASSWORD – SEND OTP
  /// ===============================
  Future<bool> sendResetOtp(String email) async {
    final canUseForgot = await _dao.isActiveNonDeletedEmail(email);
    if (!canUseForgot) return false;

    final String otp = _generateOtp();
    await _dao.updateOtpByEmail(email, otp);

    await _sendOtpToEmail(email, otp);
    return true;
  }

  /// ===============================
  /// VERIFY OTP (FORGOT PASSWORD)
  /// ===============================
  Future<bool> verifyResetOtp({
    required String email,
    required String enteredOtp,
  }) async {
    final Map<String, dynamic>? data = await _dao
        .getActiveNonDeletedStudentByEmail(email);

    if (data == null) return false;

    final String? storedOtp = data['Verification_code'];
    if (storedOtp == null || storedOtp != enteredOtp) return false;

    await _dao.clearOtpByEmail(email);
    return true;
  }

  /// ===============================
  /// RESET PASSWORD
  /// ===============================
  Future<void> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    await _dao.updatePasswordByEmail(email, newPassword);
  }

  static const baseUrl = "http://192.168.8.101/budget_ease_api";

  /// ===============================
  /// 🔐 SEND OTP TO EMAIL (PHP API)
  /// ===============================
  Future<void> _sendOtpToEmail(String email, String otp) async {
    final url = Uri.parse('$baseUrl/send_otp.php');

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/x-www-form-urlencoded"},
      body: {"email": email, "otp": otp},
    );

    print("OTP URL: $url");
    print("OTP STATUS: ${response.statusCode}");
    print("OTP LEN: ${response.body.length}");
    print("OTP BODY: '${response.body}'");

    if (response.statusCode != 200) {
      throw Exception('Failed to send OTP email (HTTP ${response.statusCode})');
    }

    if (response.body.trim().isEmpty) {
      throw Exception(
        'OTP API returned empty response. Check send_otp.php / XAMPP.',
      );
    }

    Map<String, dynamic> data;
    try {
      data = jsonDecode(response.body);
    } catch (e) {
      throw Exception('OTP API returned non-JSON: ${response.body}');
    }

    if (data['status'] != 'success') {
      throw Exception('OTP email failed: ${data['msg']}');
    }
  }

  /// ===============================
  /// HELPERS
  /// ===============================
  String _generateStudentId() {
    final random = Random();
    return 'STD${DateTime.now().millisecondsSinceEpoch}${random.nextInt(1000)}';
  }

  String _generateOtp() => (1000 + Random().nextInt(9000)).toString();
}
