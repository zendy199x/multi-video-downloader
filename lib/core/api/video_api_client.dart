import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;
import 'package:multi_video_downloader/features/common/models/video_model.dart'
    as app_models;
import 'package:multi_video_downloader/core/utils/app_constants.dart';

/// Lỗi API video
class VideoApiException implements Exception {
  final String message;
  final int? statusCode;

  VideoApiException({required this.message, this.statusCode});

  @override
  String toString() => 'VideoApiException: $message (status: $statusCode)';
}

/// Trạng thái tải xuống video
enum DownloadStatus {
  /// Chưa bắt đầu
  notStarted,

  /// Đang tải xuống
  inProgress,

  /// Đã hoàn thành
  completed,

  /// Đã bị hủy
  cancelled,

  /// Có lỗi
  failed,
}

/// API Client cơ sở cho tất cả các nền tảng video
abstract class VideoApiClient {
  /// Dio client cho các network requests
  final Dio dio;

  /// Constructor
  VideoApiClient(this.dio) {
    dio.options.connectTimeout =
        Duration(seconds: AppConstants.apiTimeoutSeconds);
    dio.options.receiveTimeout =
        Duration(seconds: AppConstants.apiTimeoutSeconds);
  }

  /// Lấy thông tin video từ URL
  Future<app_models.VideoModel> getVideoInfo(String url);

  /// Tải xuống video với URL và chất lượng đã chọn
  Future<String> downloadVideo({
    required app_models.VideoModel video,
    required app_models.VideoQuality quality,
    required Function(int, int) onProgress,
    required Function(DownloadStatus, String?) onStatusChanged,
    VoidCallback? onCancelled,
  }) async {
    try {
      // Đảm bảo thư mục tải xuống tồn tại
      final directory = await _getDownloadDirectory();

      // Tạo tên tệp dựa trên tiêu đề video và chất lượng
      final fileName = _generateFileName(video, quality);
      final filePath = '$directory/$fileName';

      // Đảm bảo chúng ta có thư mục tải xuống
      await Directory(directory).create(recursive: true);

      // Kiểm tra xem tệp đã tồn tại chưa
      final file = File(filePath);
      if (await file.exists()) {
        // Nếu tệp đã tồn tại, trả về đường dẫn
        onStatusChanged(DownloadStatus.completed, filePath);
        return filePath;
      }

      // Tạo CancelToken để có thể hủy tải xuống
      final cancelToken = CancelToken();

      // Bắt đầu tải xuống
      onStatusChanged(DownloadStatus.inProgress, null);

      // Định nghĩa hàm callback để hủy tải xuống
      if (onCancelled != null) {
        onCancelled = () {
          if (!cancelToken.isCancelled) {
            cancelToken.cancel('Download cancelled by user');
          }
        };
      }

      // Bắt đầu tải xuống
      await dio.download(
        quality.url,
        filePath,
        cancelToken: cancelToken,
        onReceiveProgress: onProgress,
      );

      // Đảm bảo tệp tồn tại và có kích thước > 0
      if (await file.exists() && await file.length() > 0) {
        onStatusChanged(DownloadStatus.completed, filePath);
        return filePath;
      } else {
        // Xóa tệp nếu tải xuống không hoàn chỉnh
        if (await file.exists()) {
          await file.delete();
        }
        throw VideoApiException(
          message: 'Tải xuống video không thành công',
        );
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        onStatusChanged(DownloadStatus.cancelled, null);
        return '';
      }
      onStatusChanged(DownloadStatus.failed, e.message);
      throw VideoApiException(
        message: 'Lỗi tải xuống: ${e.message}',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      onStatusChanged(DownloadStatus.failed, e.toString());
      throw VideoApiException(message: 'Lỗi tải xuống: ${e.toString()}');
    }
  }

  /// Lấy thư mục tải xuống
  Future<String> _getDownloadDirectory() async {
    if (Platform.isAndroid) {
      final dir = await getExternalStorageDirectory();
      return '${dir!.path}/${AppConstants.downloadDirectory}';
    } else if (Platform.isIOS) {
      final dir = await getApplicationDocumentsDirectory();
      return '${dir.path}/${AppConstants.downloadDirectory}';
    } else {
      final dir = await getDownloadsDirectory();
      return '${dir!.path}/${AppConstants.downloadDirectory}';
    }
  }

  /// Tạo tên tệp dựa trên tiêu đề video và chất lượng
  String _generateFileName(
      app_models.VideoModel video, app_models.VideoQuality quality) {
    // Làm sạch tiêu đề video cho tên tệp
    final sanitizedTitle = video.title
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '') // Xóa ký tự không hợp lệ
        .replaceAll(
            RegExp(r'\s+'), '_'); // Thay thế khoảng trắng bằng gạch dưới

    // Tạo tên tệp theo định dạng: TenVideo_ChieuCao_Platform.mp4
    final platform = video.sourceName.toLowerCase();
    final height =
        quality.height != null ? '${quality.height}p' : quality.label;

    return '${sanitizedTitle}_${height}_$platform.mp4';
  }

  /// Nền tảng được hỗ trợ bởi client này
  app_models.VideoSource get supportedPlatform;
}

/// Client API YouTube
class YoutubeApiClient extends VideoApiClient {
  final yt.YoutubeExplode _yt = yt.YoutubeExplode();

  YoutubeApiClient(Dio dio) : super(dio);

  /// Lấy YouTube ID từ URL
  String? _getYoutubeVideoId(String url) {
    // Kiểm tra trực tiếp nếu là video ID
    if (RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(url)) {
      return url;
    }

    // Regex để lấy ID từ các định dạng URL khác nhau
    for (var exp in [
      RegExp(
          r"^https:\/\/(?:www\.|m\.)?youtube\.com\/watch\?v=([_\-a-zA-Z0-9]{11}).*$"),
      RegExp(
          r"^https:\/\/(?:www\.|m\.)?youtube(?:-nocookie)?\.com\/embed\/([_\-a-zA-Z0-9]{11}).*$"),
      RegExp(r"^https:\/\/youtu\.be\/([_\-a-zA-Z0-9]{11}).*$")
    ]) {
      final match = exp.firstMatch(url);
      if (match != null && match.groupCount >= 1) {
        return match.group(1);
      }
    }

    return null;
  }

  @override
  Future<app_models.VideoModel> getVideoInfo(String url) async {
    try {
      // Xử lý đầu vào URL/ID
      final videoId = _getYoutubeVideoId(url);

      if (videoId == null) {
        throw VideoApiException(
          message: 'URL YouTube không hợp lệ',
        );
      }

      // Lấy metadata từ YouTube
      final video = await _yt.videos.get(videoId);

      // Lấy stream manifest
      final manifest = await _yt.videos.streamsClient.getManifest(videoId);

      final qualities = <app_models.VideoQuality>[];

      // Thêm video streams chỉ
      for (final streamInfo in manifest.videoOnly) {
        qualities.add(
          app_models.VideoQuality(
            label: '${streamInfo.videoResolution.height}p (Video Only)',
            url: streamInfo.url.toString(),
            height: streamInfo.videoResolution.height,
            width: streamInfo.videoResolution.width,
            fileSize: streamInfo.size.totalBytes,
          ),
        );
      }

      // Thêm video+audio streams
      for (final streamInfo in manifest.muxed) {
        qualities.add(
          app_models.VideoQuality(
            label: '${streamInfo.videoResolution.height}p',
            url: streamInfo.url.toString(),
            height: streamInfo.videoResolution.height,
            width: streamInfo.videoResolution.width,
            fileSize: streamInfo.size.totalBytes,
          ),
        );
      }

      // Thêm audio streams
      for (final streamInfo in manifest.audioOnly) {
        qualities.add(
          app_models.VideoQuality(
            label:
                'Audio ${streamInfo.audioCodec} ${streamInfo.bitrate.kiloBitsPerSecond.round()} kbps',
            url: streamInfo.url.toString(),
            fileSize: streamInfo.size.totalBytes,
          ),
        );
      }

      // Sắp xếp chất lượng theo chiều cao giảm dần
      qualities.sort((a, b) {
        if (a.height != null && b.height != null) {
          return b.height!.compareTo(a.height!);
        }
        // Đặt audio vào cuối
        if (a.height == null) return 1;
        if (b.height == null) return -1;
        return 0;
      });

      return app_models.VideoModel(
        id: video.id.value,
        title: video.title,
        author: video.author,
        thumbnailUrl: video.thumbnails.highResUrl,
        originalUrl: url,
        source: app_models.VideoSource.youtube,
        duration: video.duration,
        publishedAt: video.uploadDate,
        availableQualities: qualities,
      );
    } on VideoApiException catch (e) {
      rethrow;
    } catch (e) {
      throw VideoApiException(
        message: 'Lỗi lấy thông tin video: ${e.toString()}',
      );
    }
  }

  @override
  app_models.VideoSource get supportedPlatform =>
      app_models.VideoSource.youtube;
}

/// Client API TikTok
class TiktokApiClient extends VideoApiClient {
  TiktokApiClient(Dio dio) : super(dio);

  @override
  Future<app_models.VideoModel> getVideoInfo(String url) async {
    try {
      // Trích xuất ID video từ URL
      final videoId = AppConstants.getTiktokVideoId(url);
      if (videoId == null) {
        throw VideoApiException(
          message: 'URL TikTok không hợp lệ',
        );
      }

      // Gọi API không watermark để lấy thông tin video
      final response = await dio.get(
        'https://api16-normal-c-useast1a.tiktokv.com/aweme/v1/feed/?aweme_id=$videoId',
        options: Options(
          headers: {
            'User-Agent':
                'TikTok 26.2.0 rv:262018 (iPhone; iOS 14.4.2; en_US) Cronet'
          },
        ),
      );

      if (response.statusCode != 200) {
        throw VideoApiException(
          message: 'Lỗi API TikTok: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }

      final data = response.data;
      if (data == null ||
          data['aweme_list'] == null ||
          data['aweme_list'].isEmpty) {
        throw VideoApiException(
          message: 'Không tìm thấy thông tin video TikTok',
        );
      }

      final videoData = data['aweme_list'][0];
      final authorData = videoData['author'] ?? {};
      final videoUrlData = videoData['video'] ?? {};

      // URL không watermark
      String downloadUrl = '';
      if (videoUrlData['play_addr'] != null &&
          videoUrlData['play_addr']['url_list'] != null &&
          videoUrlData['play_addr']['url_list'].isNotEmpty) {
        downloadUrl = videoUrlData['play_addr']['url_list'][0];
      }

      // URL có watermark
      String downloadUrlWithWatermark = '';
      if (videoUrlData['download_addr'] != null &&
          videoUrlData['download_addr']['url_list'] != null &&
          videoUrlData['download_addr']['url_list'].isNotEmpty) {
        downloadUrlWithWatermark = videoUrlData['download_addr']['url_list'][0];
      }

      // Nếu không có URL không watermark, sử dụng URL có watermark
      if (downloadUrl.isEmpty) {
        downloadUrl = downloadUrlWithWatermark;
      }

      if (downloadUrl.isEmpty) {
        throw VideoApiException(
          message: 'Không tìm thấy URL tải xuống cho video TikTok',
        );
      }

      final qualities = [
        app_models.VideoQuality(
          label: 'Không watermark',
          url: downloadUrl,
          fileSize: 0,
        ),
      ];

      // Thêm phiên bản có watermark nếu khác với URL không watermark
      if (downloadUrlWithWatermark.isNotEmpty &&
          downloadUrlWithWatermark != downloadUrl) {
        qualities.add(
          app_models.VideoQuality(
            label: 'Có watermark',
            url: downloadUrlWithWatermark,
            fileSize: 0,
          ),
        );
      }

      // Trích xuất thông tin thêm
      final title = videoData['desc'] ?? 'TikTok Video #$videoId';
      final author = authorData['nickname'] ?? 'TikTok Creator';
      final authorAvatar = authorData['avatar_larger']?['url_list']?[0] ?? '';
      final cover = videoData['cover']?['url_list']?[0] ??
          videoData['origin_cover']?['url_list']?[0] ??
          '';

      // Tính thời lượng từ số khung hình và tốc độ khung hình
      final duration = videoUrlData['duration'] != null
          ? Duration(milliseconds: videoUrlData['duration'])
          : const Duration(seconds: 15); // Mặc định 15s cho TikTok

      return app_models.VideoModel(
        id: videoId,
        title: title,
        author: author,
        authorAvatarUrl: authorAvatar,
        thumbnailUrl: cover,
        originalUrl: url,
        source: app_models.VideoSource.tiktok,
        duration: duration,
        publishedAt: DateTime.now(),
        availableQualities: qualities,
      );
    } catch (e) {
      if (e is VideoApiException) rethrow;
      throw VideoApiException(
        message: 'Lỗi lấy thông tin video TikTok: ${e.toString()}',
      );
    }
  }

  @override
  app_models.VideoSource get supportedPlatform => app_models.VideoSource.tiktok;
}

/// Factory để tạo API client phù hợp với nguồn video
class VideoApiClientFactory {
  final Dio _dio;

  VideoApiClientFactory(this._dio);

  /// Tạo API client dựa trên URL hoặc nguồn được chỉ định
  VideoApiClient createClient(String url, {app_models.VideoSource? source}) {
    // Xác định nguồn từ URL nếu không được chỉ định
    source ??= _determineSourceFromUrl(url);

    switch (source) {
      case app_models.VideoSource.youtube:
        return YoutubeApiClient(_dio);
      case app_models.VideoSource.tiktok:
        return TiktokApiClient(_dio);
      case app_models.VideoSource.instagram:
      case app_models.VideoSource.facebook:
      case app_models.VideoSource.twitter:
      case app_models.VideoSource.other:
      default:
        throw Exception('Nền tảng ${source.toString()} chưa được hỗ trợ');
    }
  }

  /// Xác định nền tảng từ URL
  app_models.VideoSource _determineSourceFromUrl(String url) {
    if (AppConstants.youtubeUrlPattern.hasMatch(url)) {
      return app_models.VideoSource.youtube;
    } else if (AppConstants.tiktokUrlPattern.hasMatch(url)) {
      return app_models.VideoSource.tiktok;
    } else if (AppConstants.instagramUrlPattern.hasMatch(url)) {
      return app_models.VideoSource.instagram;
    } else if (AppConstants.facebookUrlPattern.hasMatch(url)) {
      return app_models.VideoSource.facebook;
    } else if (AppConstants.twitterUrlPattern.hasMatch(url)) {
      return app_models.VideoSource.twitter;
    } else {
      return app_models.VideoSource.other;
    }
  }
}
