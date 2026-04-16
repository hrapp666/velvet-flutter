// ============================================================================
// UploadRepository · 图片上传
// ----------------------------------------------------------------------------
// 流程：
//   1. POST /api/v1/upload/presign → 拿 uploadUrl + finalUrl
//   2. PUT 文件二进制到 uploadUrl（直传 MinIO，不经后端）
//   3. 返回 finalUrl 给上层
// ============================================================================

import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../../core/api/api_client.dart';

class UploadRepository {
  final ApiClient _api;
  UploadRepository(this._api);

  /// 上传一个文件，返回最终可访问的 URL
  Future<String> uploadFile(File file, {String? mimeType}) async {
    final mime = mimeType ?? _guessMime(file.path);

    // 1. 拿 presigned URL
    final presignRes = await _api.dio.post(
      '/api/v1/upload/presign',
      data: {'mimeType': mime},
    );
    final data = presignRes.data as Map<String, dynamic>;
    final uploadUrl = data['uploadUrl'] as String;
    final finalUrl = data['finalUrl'] as String;

    // 2. 直传 MinIO（不带 Authorization header）
    final bytes = await file.readAsBytes();
    final dio = Dio();
    await dio.put(
      uploadUrl,
      data: Stream.fromIterable([bytes]),
      options: Options(
        headers: {
          'Content-Type': mime,
          'Content-Length': bytes.length.toString(),
        },
        sendTimeout: const Duration(minutes: 5),
        receiveTimeout: const Duration(seconds: 60),
      ),
    );

    return finalUrl;
  }

  /// 上传 bytes（Web 平台用）
  Future<String> uploadBytes(Uint8List bytes, String mimeType) async {
    final presignRes = await _api.dio.post(
      '/api/v1/upload/presign',
      data: {'mimeType': mimeType},
    );
    final data = presignRes.data as Map<String, dynamic>;
    final uploadUrl = data['uploadUrl'] as String;
    final finalUrl = data['finalUrl'] as String;

    final dio = Dio();
    await dio.put(
      uploadUrl,
      data: Stream.fromIterable([bytes]),
      options: Options(
        headers: {
          'Content-Type': mimeType,
          'Content-Length': bytes.length.toString(),
        },
      ),
    );
    return finalUrl;
  }

  /// 并发上传多个文件
  Future<List<String>> uploadMultiple(List<File> files) async {
    final futures = files.map((f) => uploadFile(f)).toList();
    return Future.wait(futures);
  }

  String _guessMime(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.mp4')) return 'video/mp4';
    if (lower.endsWith('.mov')) return 'video/quicktime';
    return 'image/jpeg';
  }
}
