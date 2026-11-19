import '../core/api/api_client.dart';
import '../core/api/api_exception.dart';
import '../utils/json_utils.dart';

/// Upload file (ảnh/video) lên backend qua `POST /api/upload` (multipart).
class FileUploadService {
  FileUploadService(this._api);

  final ApiClient _api;

  /// Trả về URL công khai của tệp vừa tải lên.
  Future<String> uploadFile(String filePath) async {
    final dynamic response = await _api.postMultipart(
      '/api/upload',
      fileField: 'file',
      filePath: filePath,
    );
    final Map<String, dynamic> json = asMap(ApiClient.unwrap(response));
    final String url = (asString(json['url']) ?? '').trim();
    if (url.isEmpty) {
      throw const ApiException('Máy chủ không trả về đường dẫn tệp đã tải lên.');
    }
    return url;
  }
}

