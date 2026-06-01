import 'dart:io';

class ServerConfig {
  final String host;
  final int port;
  final String jwtSecret;
  final String allowedOrigin;
  final String databaseUrl;
  final bool seedDemoData;
  final String demoStudentEmail;
  final String demoStudentPassword;
  final String adminEmail;
  final String adminPassword;
  final String teacherEmail;
  final String teacherPassword;
  final String teacherName;

  const ServerConfig({
    required this.host,
    required this.port,
    required this.jwtSecret,
    required this.allowedOrigin,
    required this.databaseUrl,
    required this.seedDemoData,
    required this.demoStudentEmail,
    required this.demoStudentPassword,
    required this.adminEmail,
    required this.adminPassword,
    required this.teacherEmail,
    required this.teacherPassword,
    required this.teacherName,
  });

  factory ServerConfig.fromEnvironment() {
    return ServerConfig(
      host: _readEnv('HOST', fallback: '0.0.0.0'),
      port: int.tryParse(_readEnv('PORT', fallback: '8080')) ?? 8080,
      jwtSecret: _readEnv(
        'JWT_SECRET',
        fallback: 'change-me-in-production-student-cabinet',
      ),
      allowedOrigin: _readEnv('ALLOWED_ORIGIN', fallback: '*'),
      databaseUrl: _readEnv(
        'DATABASE_URL',
        fallback:
            'postgresql://student_cabinet:student_cabinet@localhost:5432/student_cabinet?sslmode=disable',
      ),
      seedDemoData: _readEnv('SEED_DEMO_DATA', fallback: 'true') == 'true',
      demoStudentEmail: _readEnv(
        'DEMO_STUDENT_EMAIL',
        fallback: 'ivan@example.com',
      ),
      demoStudentPassword: _readEnv(
        'DEMO_STUDENT_PASSWORD',
        fallback: 'student123',
      ),
      adminEmail: _readEnv(
        'ADMIN_EMAIL',
        fallback: 'admin@example.com',
      ),
      adminPassword: _readEnv(
        'ADMIN_PASSWORD',
        fallback: 'admin123',
      ),
      teacherEmail: _readEnv(
        'TEACHER_EMAIL',
        fallback: 'teacher@example.com',
      ),
      teacherPassword: _readEnv(
        'TEACHER_PASSWORD',
        fallback: 'teacher123',
      ),
      teacherName: _readEnv(
        'TEACHER_NAME',
        fallback: 'А. Н. Сергеев',
      ),
    );
  }
}

String _readEnv(String key, {required String fallback}) {
  final value = Platform.environment[key];
  if (value == null || value.trim().isEmpty) {
    return fallback;
  }

  return value.trim();
}
