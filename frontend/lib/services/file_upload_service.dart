import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../state/session_controller.dart';

/// Upload file (ảnh/video) lên backend qua `POST /api/upload` (multipart).
class FileUploadService {
  FileUploadService(this._session);

  final SessionController _session;

  Future<String> uploadFile(String filePath) async {
    final Uri uri = Uri.parse('${ApiConfig.normalizedBaseUrl}/api/upload');
    final http.MultipartRequest request = http.MultipartRequest('POST', uri);
    request.headers.addAll(_session.authHeaders);
    request.files.add(await http.MultipartFile.fromPath('file', filePath));
    final http.StreamedResponse streamed = await request.send();
    final http.Response response = await http.Response.fromStream(streamed);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Upload thất bại (HTTP ${response.statusCode})');
    }
    final Map<String, dynamic> json =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return (json['url'] ?? '').toString();
  }
}
