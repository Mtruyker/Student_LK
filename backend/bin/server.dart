import 'package:student_cabinet_backend/student_cabinet_backend.dart';

Future<void> main() async {
  final config = ServerConfig.fromEnvironment();
  final server = await serveStudentCabinetApi(config);

  print(
    'Student cabinet backend running on '
    'http://${server.address.host}:${server.port}',
  );
}
