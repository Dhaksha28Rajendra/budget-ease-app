class StudentModel {
  final String studentId;
  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final String gender;
  final String activationStatus;
  final String? verificationCode;
  final DateTime registrationDate;

  StudentModel({
    required this.studentId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    required this.gender,
    required this.activationStatus,
    required this.registrationDate,
    this.verificationCode,
  });

  factory StudentModel.fromMap(Map<String, dynamic> map) {
    return StudentModel(
      studentId: map['Student_id'] as String,
      firstName: map['First_name'] as String,
      lastName: map['Last_name'] as String,
      email: map['Email'] as String,
      password: map['Password'] as String,
      gender: map['Gender'] as String,
      activationStatus: map['Activation_status'] as String,
      verificationCode: map['Verification_code'] as String?,

      // ✅ SAFE REGISTRATION DATE PARSING
      registrationDate: map['Registration_date'] != null
          ? DateTime.parse(map['Registration_date'])
          : DateTime.now(),
    );
  }
}
