import 'dart:convert';
import 'dart:io';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

import 'config.dart';
import 'jwt_service.dart';
import 'postgres_student_store.dart';

Future<HttpServer> serveStudentCabinetApi(ServerConfig config) async {
  final store = await PostgresStudentStore.connect(config);
  final jwtService = JwtService(config.jwtSecret);
  final router = Router();

  router.get('/health', (Request request) async {
    final databaseReady = await store.ping();

    return _jsonResponse(
      HttpStatus.ok,
      <String, dynamic>{
        'status': 'ok',
        'service': 'student-cabinet-backend',
        'database': databaseReady ? 'up' : 'down',
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      },
      allowedOrigin: config.allowedOrigin,
    );
  });

  Future<Response> handleLogin(Request request) async {
    final body = await request.readAsString();
    late final Map<String, dynamic> payload;
    try {
      payload = _decodeBody(body);
    } on FormatException {
      return _jsonResponse(
        HttpStatus.badRequest,
        <String, dynamic>{
          'message': 'Request body must be valid JSON.',
        },
        allowedOrigin: config.allowedOrigin,
      );
    }
    final email = payload['email']?.toString() ?? '';
    final password = payload['password']?.toString() ?? '';

    if (email.trim().isEmpty || password.isEmpty) {
      return _jsonResponse(
        HttpStatus.badRequest,
        <String, dynamic>{
          'message': 'Email and password are required.',
        },
        allowedOrigin: config.allowedOrigin,
      );
    }

    final authRecord = await store.authenticate(
      email: email,
      password: password,
    );

    if (authRecord == null) {
      return _jsonResponse(
        HttpStatus.unauthorized,
        <String, dynamic>{
          'message': 'Invalid credentials.',
        },
        allowedOrigin: config.allowedOrigin,
      );
    }

    final cabinet = await store.getCabinetById(authRecord.id);
    if (cabinet == null) {
      return _jsonResponse(
        HttpStatus.notFound,
        <String, dynamic>{
          'message': 'Student not found.',
        },
        allowedOrigin: config.allowedOrigin,
      );
    }

    final token = jwtService.issueToken(
      email: authRecord.email,
      studentId: authRecord.id,
    );

    return _jsonResponse(
      HttpStatus.ok,
      <String, dynamic>{
        'token': token,
        'cabinet': cabinet,
      },
      allowedOrigin: config.allowedOrigin,
    );
  }

  Future<Response> handleRegister(Request request) async {
    final body = await request.readAsString();
    late final Map<String, dynamic> payload;
    try {
      payload = _decodeBody(body);
    } on FormatException {
      return _jsonResponse(
        HttpStatus.badRequest,
        <String, dynamic>{
          'message': 'Request body must be valid JSON.',
        },
        allowedOrigin: config.allowedOrigin,
      );
    }
    final fullName = payload['fullName']?.toString() ?? '';
    final groupName = payload['group']?.toString() ?? '';
    final email = payload['email']?.toString() ?? '';
    final password = payload['password']?.toString() ?? '';
    final phone = payload['phone']?.toString() ?? '';

    if (fullName.trim().isEmpty ||
        groupName.trim().isEmpty ||
        email.trim().isEmpty ||
        password.isEmpty) {
      return _jsonResponse(
        HttpStatus.badRequest,
        <String, dynamic>{
          'message': 'Full name, group, email and password are required.',
        },
        allowedOrigin: config.allowedOrigin,
      );
    }

    if (password.length < 6) {
      return _jsonResponse(
        HttpStatus.badRequest,
        <String, dynamic>{
          'message': 'Password must contain at least 6 characters.',
        },
        allowedOrigin: config.allowedOrigin,
      );
    }

    try {
      final authRecord = await store.registerStudent(
        fullName: fullName,
        groupName: groupName,
        email: email,
        password: password,
        phone: phone,
      );
      final cabinet = await store.getCabinetById(authRecord.id);
      if (cabinet == null) {
        return _jsonResponse(
          HttpStatus.internalServerError,
          <String, dynamic>{
            'message': 'Registered user was not found after creation.',
          },
          allowedOrigin: config.allowedOrigin,
        );
      }

      final token = jwtService.issueToken(
        email: authRecord.email,
        studentId: authRecord.id,
      );

      return _jsonResponse(
        HttpStatus.created,
        <String, dynamic>{
          'token': token,
          'cabinet': cabinet,
        },
        allowedOrigin: config.allowedOrigin,
      );
    } on StudentConflictException catch (error) {
      return _jsonResponse(
        HttpStatus.conflict,
        <String, dynamic>{
          'message': error.message,
        },
        allowedOrigin: config.allowedOrigin,
      );
    }
  }

  Future<Response> handleAdminLogin(Request request) async {
    final body = await request.readAsString();
    late final Map<String, dynamic> payload;
    try {
      payload = _decodeBody(body);
    } on FormatException {
      return _jsonResponse(
        HttpStatus.badRequest,
        <String, dynamic>{
          'message': 'Request body must be valid JSON.',
        },
        allowedOrigin: config.allowedOrigin,
      );
    }

    final email = payload['email']?.toString().trim() ?? '';
    final password = payload['password']?.toString() ?? '';
    if (email.isEmpty || password.isEmpty) {
      return _jsonResponse(
        HttpStatus.badRequest,
        <String, dynamic>{
          'message': 'Email and password are required.',
        },
        allowedOrigin: config.allowedOrigin,
      );
    }

    final isValidAdmin =
        email.toLowerCase() == config.adminEmail.toLowerCase() &&
            password == config.adminPassword;
    if (!isValidAdmin) {
      return _jsonResponse(
        HttpStatus.unauthorized,
        <String, dynamic>{
          'message': 'Invalid admin credentials.',
        },
        allowedOrigin: config.allowedOrigin,
      );
    }

    final token = jwtService.issueAdminToken(email: config.adminEmail);
    return _jsonResponse(
      HttpStatus.ok,
      <String, dynamic>{
        'token': token,
        'role': 'admin',
      },
      allowedOrigin: config.allowedOrigin,
    );
  }

  Future<Response> handleTeacherLogin(Request request) async {
    final body = await request.readAsString();
    late final Map<String, dynamic> payload;
    try {
      payload = _decodeBody(body);
    } on FormatException {
      return _jsonResponse(
        HttpStatus.badRequest,
        <String, dynamic>{
          'message': 'Request body must be valid JSON.',
        },
        allowedOrigin: config.allowedOrigin,
      );
    }

    final email = payload['email']?.toString().trim() ?? '';
    final password = payload['password']?.toString() ?? '';
    if (email.isEmpty || password.isEmpty) {
      return _jsonResponse(
        HttpStatus.badRequest,
        <String, dynamic>{
          'message': 'Email and password are required.',
        },
        allowedOrigin: config.allowedOrigin,
      );
    }

    final teacher = await store.authenticateTeacher(
      email: email,
      password: password,
    );
    if (teacher == null) {
      return _jsonResponse(
        HttpStatus.unauthorized,
        <String, dynamic>{
          'message': 'Invalid teacher credentials.',
        },
        allowedOrigin: config.allowedOrigin,
      );
    }

    final token = jwtService.issueTeacherToken(
      teacherId: teacher.id,
      email: teacher.email,
      teacherName: teacher.fullName,
    );

    return _jsonResponse(
      HttpStatus.ok,
      <String, dynamic>{
        'token': token,
        'role': 'teacher',
        'teacherName': teacher.fullName,
      },
      allowedOrigin: config.allowedOrigin,
    );
  }

  Future<Response> handleTeacherRegister(Request request) async {
    final body = await request.readAsString();
    late final Map<String, dynamic> payload;
    try {
      payload = _decodeBody(body);
    } on FormatException {
      return _jsonResponse(
        HttpStatus.badRequest,
        <String, dynamic>{
          'message': 'Request body must be valid JSON.',
        },
        allowedOrigin: config.allowedOrigin,
      );
    }

    final fullName = payload['fullName']?.toString().trim() ?? '';
    final email = payload['email']?.toString().trim() ?? '';
    final password = payload['password']?.toString() ?? '';
    if (fullName.isEmpty || email.isEmpty || password.isEmpty) {
      return _jsonResponse(
        HttpStatus.badRequest,
        <String, dynamic>{
          'message': 'Full name, email and password are required.',
        },
        allowedOrigin: config.allowedOrigin,
      );
    }
    if (password.length < 6) {
      return _jsonResponse(
        HttpStatus.badRequest,
        <String, dynamic>{
          'message': 'Password must contain at least 6 characters.',
        },
        allowedOrigin: config.allowedOrigin,
      );
    }

    try {
      final teacher = await store.registerTeacher(
        fullName: fullName,
        email: email,
        password: password,
      );

      final token = jwtService.issueTeacherToken(
        teacherId: teacher.id,
        email: teacher.email,
        teacherName: teacher.fullName,
      );

      return _jsonResponse(
        HttpStatus.created,
        <String, dynamic>{
          'token': token,
          'role': 'teacher',
          'teacherName': teacher.fullName,
        },
        allowedOrigin: config.allowedOrigin,
      );
    } on TeacherConflictException catch (error) {
      return _jsonResponse(
        HttpStatus.conflict,
        <String, dynamic>{
          'message': error.message,
        },
        allowedOrigin: config.allowedOrigin,
      );
    }
  }

  Response? ensureAdmin(Request request) {
    final token = _extractBearerToken(request);
    if (token == null) {
      return _jsonResponse(
        HttpStatus.unauthorized,
        <String, dynamic>{
          'message': 'Missing bearer token.',
        },
        allowedOrigin: config.allowedOrigin,
      );
    }

    try {
      final payload = jwtService.verify(token);
      final role = payload['role']?.toString() ?? '';
      if (role != 'admin') {
        return _jsonResponse(
          HttpStatus.forbidden,
          <String, dynamic>{
            'message': 'Admin role is required.',
          },
          allowedOrigin: config.allowedOrigin,
        );
      }
    } on JWTExpiredException {
      return _jsonResponse(
        HttpStatus.unauthorized,
        <String, dynamic>{
          'message': 'Token expired.',
        },
        allowedOrigin: config.allowedOrigin,
      );
    } on JWTException {
      return _jsonResponse(
        HttpStatus.unauthorized,
        <String, dynamic>{
          'message': 'Invalid token.',
        },
        allowedOrigin: config.allowedOrigin,
      );
    }

    return null;
  }

  Future<Response> withStudentAuth(
    Request request,
    Future<Response> Function(String studentId) action,
  ) async {
    final token = _extractBearerToken(request);
    if (token == null) {
      return _jsonResponse(
        HttpStatus.unauthorized,
        <String, dynamic>{
          'message': 'Missing bearer token.',
        },
        allowedOrigin: config.allowedOrigin,
      );
    }

    try {
      final payload = jwtService.verify(token);
      final role = payload['role']?.toString() ?? '';
      if (role != 'student') {
        return _jsonResponse(
          HttpStatus.forbidden,
          <String, dynamic>{
            'message': 'Student role is required.',
          },
          allowedOrigin: config.allowedOrigin,
        );
      }

      final studentId = payload['sub']?.toString().trim() ?? '';
      if (studentId.isEmpty) {
        return _jsonResponse(
          HttpStatus.unauthorized,
          <String, dynamic>{
            'message': 'Invalid token payload.',
          },
          allowedOrigin: config.allowedOrigin,
        );
      }

      return action(studentId);
    } on JWTExpiredException {
      return _jsonResponse(
        HttpStatus.unauthorized,
        <String, dynamic>{
          'message': 'Token expired.',
        },
        allowedOrigin: config.allowedOrigin,
      );
    } on JWTException {
      return _jsonResponse(
        HttpStatus.unauthorized,
        <String, dynamic>{
          'message': 'Invalid token.',
        },
        allowedOrigin: config.allowedOrigin,
      );
    }
  }

  Future<Response> withTeacherAuth(
    Request request,
    Future<Response> Function(String teacherId) action,
  ) async {
    final token = _extractBearerToken(request);
    if (token == null) {
      return _jsonResponse(
        HttpStatus.unauthorized,
        <String, dynamic>{
          'message': 'Missing bearer token.',
        },
        allowedOrigin: config.allowedOrigin,
      );
    }

    try {
      final payload = jwtService.verify(token);
      final role = payload['role']?.toString() ?? '';
      if (role != 'teacher') {
        return _jsonResponse(
          HttpStatus.forbidden,
          <String, dynamic>{
            'message': 'Teacher role is required.',
          },
          allowedOrigin: config.allowedOrigin,
        );
      }

      final teacherId = payload['sub']?.toString().trim() ?? '';
      if (teacherId.isEmpty) {
        return _jsonResponse(
          HttpStatus.unauthorized,
          <String, dynamic>{
            'message': 'Invalid token payload.',
          },
          allowedOrigin: config.allowedOrigin,
        );
      }

      return action(teacherId);
    } on JWTExpiredException {
      return _jsonResponse(
        HttpStatus.unauthorized,
        <String, dynamic>{
          'message': 'Token expired.',
        },
        allowedOrigin: config.allowedOrigin,
      );
    } on JWTException {
      return _jsonResponse(
        HttpStatus.unauthorized,
        <String, dynamic>{
          'message': 'Invalid token.',
        },
        allowedOrigin: config.allowedOrigin,
      );
    }
  }

  router.post('/auth/login', handleLogin);
  router.post('/auth/register', handleRegister);
  router.post('/admin/login', handleAdminLogin);
  router.post('/teacher/register', handleTeacherRegister);
  router.post('/teacher/login', handleTeacherLogin);

  router.get('/admin/students', (Request request) async {
    final authError = ensureAdmin(request);
    if (authError != null) {
      return authError;
    }

    final students = await store.listStudentsForAdmin();
    return _jsonResponse(
      HttpStatus.ok,
      <String, dynamic>{
        'students': students,
      },
      allowedOrigin: config.allowedOrigin,
    );
  });

  router.get('/admin/students/<id>', (Request request, String id) async {
    final authError = ensureAdmin(request);
    if (authError != null) {
      return authError;
    }

    final cabinet = await store.getCabinetById(id);
    if (cabinet == null) {
      return _jsonResponse(
        HttpStatus.notFound,
        <String, dynamic>{
          'message': 'Student not found.',
        },
        allowedOrigin: config.allowedOrigin,
      );
    }

    return _jsonResponse(
      HttpStatus.ok,
      <String, dynamic>{
        'id': id,
        ...cabinet,
      },
      allowedOrigin: config.allowedOrigin,
    );
  });

  router.put('/admin/students/<id>/profile',
      (Request request, String id) async {
    final authError = ensureAdmin(request);
    if (authError != null) {
      return authError;
    }

    final body = await request.readAsString();
    late final Map<String, dynamic> payload;
    try {
      payload = _decodeBody(body);
    } on FormatException {
      return _jsonResponse(
        HttpStatus.badRequest,
        <String, dynamic>{
          'message': 'Request body must be valid JSON.',
        },
        allowedOrigin: config.allowedOrigin,
      );
    }

    final fullName = payload['fullName']?.toString().trim() ?? '';
    final groupName = payload['group']?.toString().trim() ?? '';
    final email = payload['email']?.toString().trim() ?? '';
    final phone = payload['phone']?.toString() ?? '';
    final curator = payload['curator']?.toString() ?? '';
    final attendance = _readDouble(payload['attendance']) ?? 0;
    final completedAssignments = _readInt(payload['completedAssignments']) ?? 0;
    final totalAssignments = _readInt(payload['totalAssignments']) ?? 0;

    if (fullName.isEmpty || groupName.isEmpty || email.isEmpty) {
      return _jsonResponse(
        HttpStatus.badRequest,
        <String, dynamic>{
          'message': 'Full name, group and email are required.',
        },
        allowedOrigin: config.allowedOrigin,
      );
    }

    try {
      final updated = await store.updateStudentProfile(
        id: id,
        fullName: fullName,
        groupName: groupName,
        email: email,
        phone: phone,
        curator: curator,
        attendance: attendance,
        completedAssignments: completedAssignments,
        totalAssignments: totalAssignments < completedAssignments
            ? completedAssignments
            : totalAssignments,
      );

      if (!updated) {
        return _jsonResponse(
          HttpStatus.notFound,
          <String, dynamic>{
            'message': 'Student not found.',
          },
          allowedOrigin: config.allowedOrigin,
        );
      }

      final cabinet = await store.getCabinetById(id);
      if (cabinet == null) {
        return _jsonResponse(
          HttpStatus.notFound,
          <String, dynamic>{
            'message': 'Student not found.',
          },
          allowedOrigin: config.allowedOrigin,
        );
      }

      return _jsonResponse(
        HttpStatus.ok,
        <String, dynamic>{
          'id': id,
          ...cabinet,
        },
        allowedOrigin: config.allowedOrigin,
      );
    } on StudentConflictException catch (error) {
      return _jsonResponse(
        HttpStatus.conflict,
        <String, dynamic>{
          'message': error.message,
        },
        allowedOrigin: config.allowedOrigin,
      );
    }
  });

  router.put('/admin/students/<id>/schedule',
      (Request request, String id) async {
    final authError = ensureAdmin(request);
    if (authError != null) {
      return authError;
    }

    final body = await request.readAsString();
    late final Map<String, dynamic> payload;
    try {
      payload = _decodeBody(body);
    } on FormatException {
      return _jsonResponse(
        HttpStatus.badRequest,
        <String, dynamic>{
          'message': 'Request body must be valid JSON.',
        },
        allowedOrigin: config.allowedOrigin,
      );
    }

    final rawSchedule = payload['schedule'];
    if (rawSchedule is! List) {
      return _jsonResponse(
        HttpStatus.badRequest,
        <String, dynamic>{
          'message': 'Field "schedule" must be an array.',
        },
        allowedOrigin: config.allowedOrigin,
      );
    }

    final schedule = <Map<String, dynamic>>[];
    for (final item in rawSchedule) {
      final lesson = _asMap(item);
      if (lesson == null) {
        return _jsonResponse(
          HttpStatus.badRequest,
          <String, dynamic>{
            'message': 'Each schedule entry must be an object.',
          },
          allowedOrigin: config.allowedOrigin,
        );
      }

      final weekday = _readInt(lesson['weekday']);
      final time = lesson['time']?.toString().trim() ?? '';
      final subject = lesson['subject']?.toString().trim() ?? '';
      final room = lesson['room']?.toString().trim() ?? '';
      final teacher = lesson['teacher']?.toString().trim() ?? '';
      final type = lesson['type']?.toString().trim() ?? '';

      final hasInvalidWeekday = weekday == null || weekday < 1 || weekday > 7;
      if (hasInvalidWeekday ||
          time.isEmpty ||
          subject.isEmpty ||
          room.isEmpty ||
          teacher.isEmpty ||
          type.isEmpty) {
        return _jsonResponse(
          HttpStatus.badRequest,
          <String, dynamic>{
            'message':
                'Each lesson must contain weekday (1-7), time, subject, room, teacher and type.',
          },
          allowedOrigin: config.allowedOrigin,
        );
      }

      schedule.add(
        <String, dynamic>{
          'weekday': weekday,
          'time': time,
          'subject': subject,
          'room': room,
          'teacher': teacher,
          'type': type,
        },
      );
    }

    final updated = await store.replaceStudentSchedule(
      id: id,
      schedule: schedule,
    );
    if (!updated) {
      return _jsonResponse(
        HttpStatus.notFound,
        <String, dynamic>{
          'message': 'Student not found.',
        },
        allowedOrigin: config.allowedOrigin,
      );
    }

    final cabinet = await store.getCabinetById(id);
    if (cabinet == null) {
      return _jsonResponse(
        HttpStatus.notFound,
        <String, dynamic>{
          'message': 'Student not found.',
        },
        allowedOrigin: config.allowedOrigin,
      );
    }

    return _jsonResponse(
      HttpStatus.ok,
      <String, dynamic>{
        'id': id,
        ...cabinet,
      },
      allowedOrigin: config.allowedOrigin,
    );
  });

  router.post('/student/certificate-request', (Request request) async {
    return withStudentAuth(request, (studentId) async {
      final body = await request.readAsString();
      late final Map<String, dynamic> payload;
      try {
        payload = _decodeBody(body);
      } on FormatException {
        return _jsonResponse(
          HttpStatus.badRequest,
          <String, dynamic>{
            'message': 'Request body must be valid JSON.',
          },
          allowedOrigin: config.allowedOrigin,
        );
      }

      final certificateType =
          payload['type']?.toString().trim() ?? 'Справка об обучении';
      final comment = payload['comment']?.toString().trim() ??
          payload['purpose']?.toString().trim() ??
          '';
      if (comment.length > 500) {
        return _jsonResponse(
          HttpStatus.badRequest,
          <String, dynamic>{
            'message': 'Comment should be at most 500 characters.',
          },
          allowedOrigin: config.allowedOrigin,
        );
      }

      final cabinet = await store.createCertificateRequest(
        id: studentId,
        certificateType: certificateType,
        comment: comment,
      );
      if (cabinet == null) {
        return _jsonResponse(
          HttpStatus.notFound,
          <String, dynamic>{
            'message': 'Student not found.',
          },
          allowedOrigin: config.allowedOrigin,
        );
      }

      return _jsonResponse(
        HttpStatus.created,
        <String, dynamic>{
          'message': 'Certificate request submitted.',
          'cabinet': cabinet,
        },
        allowedOrigin: config.allowedOrigin,
      );
    });
  });

  router.post('/student/curator/contact', (Request request) async {
    return withStudentAuth(request, (studentId) async {
      final body = await request.readAsString();
      late final Map<String, dynamic> payload;
      try {
        payload = _decodeBody(body);
      } on FormatException {
        return _jsonResponse(
          HttpStatus.badRequest,
          <String, dynamic>{
            'message': 'Request body must be valid JSON.',
          },
          allowedOrigin: config.allowedOrigin,
        );
      }

      final message = payload['message']?.toString().trim() ?? '';
      if (message.isEmpty) {
        return _jsonResponse(
          HttpStatus.badRequest,
          <String, dynamic>{
            'message': 'Message is required.',
          },
          allowedOrigin: config.allowedOrigin,
        );
      }
      if (message.length > 1000) {
        return _jsonResponse(
          HttpStatus.badRequest,
          <String, dynamic>{
            'message': 'Message should be at most 1000 characters.',
          },
          allowedOrigin: config.allowedOrigin,
        );
      }

      final cabinet = await store.sendMessageToCurator(
        id: studentId,
        message: message,
      );
      if (cabinet == null) {
        return _jsonResponse(
          HttpStatus.notFound,
          <String, dynamic>{
            'message': 'Student not found.',
          },
          allowedOrigin: config.allowedOrigin,
        );
      }

      return _jsonResponse(
        HttpStatus.ok,
        <String, dynamic>{
          'message': 'Message sent to curator.',
          'cabinet': cabinet,
        },
        allowedOrigin: config.allowedOrigin,
      );
    });
  });

  router.get('/teacher/dashboard', (Request request) async {
    return withTeacherAuth(request, (teacherId) async {
      final dashboard = await store.getTeacherDashboard(
        teacherId: teacherId,
      );

      return _jsonResponse(
        HttpStatus.ok,
        dashboard,
        allowedOrigin: config.allowedOrigin,
      );
    });
  });

  router.get('/student/cabinet', (Request request) async {
    return withStudentAuth(request, (studentId) async {
      final cabinet = await store.getCabinetById(studentId);
      if (cabinet == null) {
        return _jsonResponse(
          HttpStatus.notFound,
          <String, dynamic>{
            'message': 'Student not found.',
          },
          allowedOrigin: config.allowedOrigin,
        );
      }

      return _jsonResponse(
        HttpStatus.ok,
        cabinet,
        allowedOrigin: config.allowedOrigin,
      );
    });
  });

  router.all('/<ignored|.*>', (Request request) {
    if (request.method == 'OPTIONS') {
      return Response(
        HttpStatus.noContent,
        headers: _corsHeaders(
          config.allowedOrigin,
          requestOrigin: request.headers['origin'],
        ),
      );
    }

    return _jsonResponse(
      HttpStatus.notFound,
      <String, dynamic>{
        'message': 'Route not found.',
      },
      allowedOrigin: config.allowedOrigin,
    );
  });

  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(_corsMiddleware(config.allowedOrigin))
      .addMiddleware(_jsonContentTypeMiddleware())
      .addMiddleware(_errorMiddleware(config.allowedOrigin))
      .addHandler(router.call);

  final server = await shelf_io.serve(
    handler,
    config.host,
    config.port,
  );

  _registerShutdown(server, store);
  return server;
}

void _registerShutdown(
  HttpServer server,
  PostgresStudentStore store,
) {
  Future<void> shutdown() async {
    await server.close(force: true);
    await store.close();
    exit(0);
  }

  ProcessSignal.sigint.watch().listen((_) => shutdown());
  if (!Platform.isWindows) {
    ProcessSignal.sigterm.watch().listen((_) => shutdown());
  }
}

Middleware _corsMiddleware(String allowedOrigin) {
  return (Handler innerHandler) {
    return (Request request) async {
      final corsHeaders = _corsHeaders(
        allowedOrigin,
        requestOrigin: request.headers['origin'],
      );
      if (request.method == 'OPTIONS') {
        return Response(
          HttpStatus.noContent,
          headers: corsHeaders,
        );
      }

      final response = await innerHandler(request);
      return response.change(
        headers: <String, String>{
          ...response.headers,
          ...corsHeaders,
        },
      );
    };
  };
}

Middleware _jsonContentTypeMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      final response = await innerHandler(request);
      if (response.headers.containsKey(HttpHeaders.contentTypeHeader)) {
        return response;
      }

      return response.change(
        headers: <String, String>{
          ...response.headers,
          HttpHeaders.contentTypeHeader: 'application/json; charset=utf-8',
        },
      );
    };
  };
}

Middleware _errorMiddleware(String allowedOrigin) {
  return (Handler innerHandler) {
    return (Request request) async {
      try {
        return await innerHandler(request);
      } catch (error, stackTrace) {
        stderr.writeln(
            'Unhandled error for ${request.method} ${request.requestedUri}: $error');
        stderr.writeln(stackTrace);
        return _jsonResponse(
          HttpStatus.internalServerError,
          <String, dynamic>{
            'message': 'Internal server error.',
          },
          allowedOrigin: allowedOrigin,
        );
      }
    };
  };
}

Response _jsonResponse(
  int statusCode,
  Map<String, dynamic> body, {
  required String allowedOrigin,
}) {
  return Response(
    statusCode,
    body: jsonEncode(body),
    headers: <String, String>{
      HttpHeaders.contentTypeHeader: 'application/json; charset=utf-8',
    },
  );
}

Map<String, dynamic> _decodeBody(String body) {
  if (body.trim().isEmpty) {
    return <String, dynamic>{};
  }

  final decoded = jsonDecode(body);
  if (decoded is Map<String, dynamic>) {
    return decoded;
  }
  if (decoded is Map) {
    return decoded.cast<String, dynamic>();
  }

  return <String, dynamic>{};
}

Map<String, dynamic>? _asMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.cast<String, dynamic>();
  }
  return null;
}

int? _readInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value.trim());
  }

  return null;
}

double? _readDouble(Object? value) {
  if (value is double) {
    return value;
  }
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value.trim().replaceAll(',', '.'));
  }

  return null;
}

String? _extractBearerToken(Request request) {
  final header = request.headers[HttpHeaders.authorizationHeader];
  if (header == null || !header.startsWith('Bearer ')) {
    return null;
  }

  return header.substring('Bearer '.length).trim();
}

Map<String, String> _corsHeaders(
  String allowedOrigin, {
  String? requestOrigin,
}) {
  final allowedOrigins = allowedOrigin
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();
  final allowsAnyOrigin =
      allowedOrigins.isEmpty || allowedOrigins.contains('*');
  final normalizedRequestOrigin = requestOrigin?.trim();

  String? resolvedOrigin;
  if (allowsAnyOrigin) {
    resolvedOrigin = '*';
  } else if (normalizedRequestOrigin != null &&
      normalizedRequestOrigin.isNotEmpty) {
    final isExplicitlyAllowed = allowedOrigins.any(
      (origin) => origin.toLowerCase() == normalizedRequestOrigin.toLowerCase(),
    );
    if (isExplicitlyAllowed) {
      resolvedOrigin = normalizedRequestOrigin;
    }
  } else {
    resolvedOrigin = allowedOrigins.first;
  }

  final headers = <String, String>{
    'Access-Control-Allow-Headers':
        'Origin, Content-Type, Accept, Authorization',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, OPTIONS',
  };
  if (resolvedOrigin != null) {
    headers['Access-Control-Allow-Origin'] = resolvedOrigin;
  }
  if (!allowsAnyOrigin) {
    headers['Vary'] = 'Origin';
  }

  return headers;
}
