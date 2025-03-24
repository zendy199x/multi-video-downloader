import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:multi_video_downloader/core/api/video_api_client.dart';
import 'package:multi_video_downloader/core/utils/app_constants.dart';
import 'package:multi_video_downloader/features/common/models/video_model.dart'
    as app_models;
import 'package:flutter/foundation.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

/// Exception khi tải xuống video
class VideoDownloadException implements Exception {
  final String message;
  final int? statusCode;

  VideoDownloadException({required this.message, this.statusCode});

  @override
  String toString() => 'VideoDownloadException: $message (status: $statusCode)';
}

/// Repository để xử lý tải xuống video
class VideoDownloadRepository {
  /// API client factory
  final VideoApiClientFactory apiClientFactory;

  /// Internet connection checker
  final InternetConnectionChecker connectionChecker;

  /// Constructor
  VideoDownloadRepository({
    required this.apiClientFactory,
    required this.connectionChecker,
  });

  /// Kiểm tra kết nối internet
  Future<bool> hasInternetConnection() async {
    return await connectionChecker.hasConnection;
  }

  /// Lấy thông tin video từ URL
  Future<app_models.VideoModel> getVideoInfo(String url,
      {app_models.VideoSource? source}) async {
    // Kiểm tra kết nối internet
    final hasConnection = await hasInternetConnection();
    if (!hasConnection) {
      throw VideoDownloadException(message: 'Không có kết nối internet');
    }

    // Tạo API client phù hợp và gọi
    try {
      final apiClient = apiClientFactory.createClient(url, source: source);
      return await apiClient.getVideoInfo(url);
    } catch (e) {
      if (e is VideoApiException) {
        throw VideoDownloadException(
          message: e.message,
          statusCode: e.statusCode,
        );
      }
      throw VideoDownloadException(
        message: 'Không thể lấy thông tin video: ${e.toString()}',
      );
    }
  }

  /// Tải xuống video
  Future<String> downloadVideo({
    required app_models.VideoModel video,
    required app_models.VideoQuality quality,
    required Function(int, int) onProgress,
    required Function(DownloadStatus, String?) onStatusChanged,
    VoidCallback? onCancelled,
  }) async {
    // Kiểm tra kết nối internet
    final hasConnection = await hasInternetConnection();
    if (!hasConnection) {
      onStatusChanged(DownloadStatus.failed, 'Không có kết nối internet');
      return '';
    }

    // Tạo API client phù hợp và gọi
    try {
      final apiClient = apiClientFactory.createClient(video.originalUrl,
          source: video.source);
      return await apiClient.downloadVideo(
        video: video,
        quality: quality,
        onProgress: onProgress,
        onStatusChanged: onStatusChanged,
        onCancelled: onCancelled,
      );
    } catch (e) {
      if (e is VideoApiException) {
        onStatusChanged(DownloadStatus.failed, e.message);
      } else {
        onStatusChanged(DownloadStatus.failed, e.toString());
      }
      return '';
    }
  }

  /// Hủy tải xuống video hiện tại nếu có
  void cancelCurrentDownload() {
    // Lấy client hiện tại và gọi phương thức hủy tải xuống
    try {
      final activeClients = apiClientFactory.getActiveClients();
      for (final client in activeClients) {
        client.cancelCurrentDownload();
      }
    } catch (e) {
      debugPrint('Lỗi khi hủy tải xuống: ${e.toString()}');
    }
  }
}
