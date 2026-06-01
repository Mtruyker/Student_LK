import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

class JwtService {
  JwtService(this._secret);

  final String _secret;

  String issueToken({
    required String email,
    required String studentId,
  }) {
    return _issueToken(
      email: email,
      subject: studentId,
      role: 'student',
    );
  }

  String issueAdminToken({
    required String email,
  }) {
    return _issueToken(
      email: email,
      subject: 'admin',
      role: 'admin',
    );
  }

  String issueTeacherToken({
    required String teacherId,
    required String email,
    required String teacherName,
  }) {
    return _issueToken(
      email: email,
      subject: teacherId,
      role: 'teacher',
      additionalClaims: <String, dynamic>{
        'teacherName': teacherName,
      },
    );
  }

  String _issueToken({
    required String email,
    required String subject,
    required String role,
    Map<String, dynamic> additionalClaims = const <String, dynamic>{},
  }) {
    final jwt = JWT(<String, dynamic>{
      'sub': subject,
      'email': email,
      'role': role,
      ...additionalClaims,
    });

    return jwt.sign(
      SecretKey(_secret),
      expiresIn: const Duration(hours: 12),
    );
  }

  Map<String, dynamic> verify(String token) {
    final verified = JWT.verify(token, SecretKey(_secret));
    final payload = verified.payload;
    if (payload is Map<String, dynamic>) {
      return payload;
    }
    if (payload is Map) {
      return payload.cast<String, dynamic>();
    }

    return <String, dynamic>{};
  }
}
