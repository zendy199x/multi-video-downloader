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

  /// Callback để hủy tải xuống hiện tại
  VoidCallback? _currentCancelCallback;

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

      // Tạo hàm hủy tải xuống và gán vào callback
      void cancelDownload() {
        if (!cancelToken.isCancelled) {
          cancelToken.cancel('Download cancelled by user');
        }
      }

      // Gán hàm hủy vào callback được cung cấp
      if (onCancelled != null) {
        // Sử dụng biến từ tham số như một function pointer
        VoidCallback originalCallback = onCancelled;
        // Định nghĩa lại callback bên ngoài
        _currentCancelCallback = () {
          cancelDownload();
          originalCallback();
        };
      } else {
        _currentCancelCallback = cancelDownload;
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
    } on FileSystemException catch (e) {
      // Xử lý đặc biệt cho lỗi hệ thống tệp
      String errorMessage = 'Lỗi hệ thống tệp';

      // Kiểm tra lỗi tên file quá dài
      if (e.osError != null && e.osError!.errorCode == 63) {
        errorMessage =
            'Tên tệp quá dài. Hãy thử với video có tiêu đề ngắn hơn.';
      }
      // Kiểm tra lỗi không đủ quyền
      else if (e.osError != null &&
          (e.osError!.errorCode == 13 ||
              e.osError!.message.contains('Permission denied'))) {
        errorMessage = 'Không có quyền truy cập thư mục lưu trữ.';
      }
      // Kiểm tra lỗi không đủ dung lượng
      else if (e.osError != null && e.osError!.errorCode == 28) {
        errorMessage = 'Không đủ dung lượng lưu trữ.';
      }
      // Thông báo lỗi gốc nếu không thuộc các trường hợp trên
      else {
        errorMessage = 'Lỗi hệ thống tệp: ${e.message}';
      }

      onStatusChanged(DownloadStatus.failed, errorMessage);
      throw VideoApiException(message: errorMessage);
    } catch (e) {
      // Kiểm tra lỗi tên file quá dài trong trường hợp chung
      String errorMessage = 'Lỗi tải xuống';
      if (e.toString().contains('File name too long') ||
          e.toString().contains('errno = 63')) {
        errorMessage =
            'Tên tệp quá dài. Hãy thử với video có tiêu đề ngắn hơn.';
      } else {
        errorMessage = 'Lỗi tải xuống: ${e.toString()}';
      }

      onStatusChanged(DownloadStatus.failed, errorMessage);
      throw VideoApiException(message: errorMessage);
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
    // Giới hạn độ dài tối đa an toàn cho tên file (macOS giới hạn 255 ký tự)
    const int maxFileNameLength = 100;

    // Làm sạch tiêu đề video cho tên tệp
    var sanitizedTitle = video.title
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '') // Xóa ký tự không hợp lệ
        .replaceAll(RegExp(r'\s+'), '_') // Thay thế khoảng trắng bằng gạch dưới
        .replaceAll(
            RegExp(r'[^\x00-\x7F]'), ''); // Loại bỏ các ký tự không phải ASCII

    // Cắt ngắn tiêu đề nếu quá dài
    if (sanitizedTitle.length > maxFileNameLength) {
      sanitizedTitle = sanitizedTitle.substring(0, maxFileNameLength);
    }

    final platform = video.sourceName.toLowerCase();
    final height =
        quality.height != null ? '${quality.height}p' : quality.label;

    // Đảm bảo tiêu đề không rỗng
    if (sanitizedTitle.isEmpty) {
      sanitizedTitle = 'video';
    }

    // Thêm timestamp để đảm bảo tên file là duy nhất
    final timestamp =
        DateTime.now().millisecondsSinceEpoch.toString().substring(6);

    return '${sanitizedTitle}_${height}_${platform}_$timestamp.mp4';
  }

  /// Hủy tải xuống hiện tại nếu có
  void cancelCurrentDownload() {
    if (_currentCancelCallback != null) {
      _currentCancelCallback!();
      _currentCancelCallback = null;
    }
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
      // Xác định video ID từ URL
      final videoId = AppConstants.getTiktokVideoId(url);
      if (videoId == null) {
        throw VideoApiException(
          message: 'Không thể xác định ID video từ URL TikTok',
        );
      }

      // Thử lần lượt từng phương pháp
      List<Future<app_models.VideoModel> Function()> methods = [
        () => getDirectTikwmNoWatermark(
            url, videoId), // Phương pháp mới: TikWM API trực tiếp
        () => getNewSsstikNoWatermark(
            url, videoId), // Phương pháp mới: SSSTIK.io API
        () => getTikwmApiNoWatermark(url, videoId), // Phương pháp cũ: TikWM API
        () =>
            getSsstikNoWatermark(url, videoId), // Phương pháp cũ: SsstikIO API
        () => getAwemeApiNoWatermark(
            url, videoId), // Phương pháp cũ: API chính thức
      ];

      for (var method in methods) {
        try {
          return await method();
        } catch (e) {
          // Ghi log lỗi nhưng tiếp tục với phương pháp tiếp theo
          debugPrint(
              'Phương pháp tải video không watermark thất bại: ${e.toString()}');
          continue;
        }
      }

      // Nếu tất cả phương pháp đều thất bại
      throw VideoApiException(
        message:
            'Không thể tải xuống video TikTok không có watermark. TikTok có thể đã thay đổi API của họ. Vui lòng thử lại sau.',
      );
    } catch (e) {
      if (e is VideoApiException) rethrow;
      throw VideoApiException(
        message: 'Lỗi lấy thông tin video TikTok: ${e.toString()}',
      );
    }
  }

  /// Phương pháp 1: Sử dụng Aweme API (API TikTok chính thức)
  Future<app_models.VideoModel> getAwemeApiNoWatermark(
      String url, String videoId) async {
    final String apiUrl =
        'https://api16-normal-c-useast1a.tiktokv.com/aweme/v1/feed/?aweme_id=$videoId';
    final response = await dio.get(
      apiUrl,
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

    // Lấy kích thước file không watermark
    int noWatermarkSize = 0;
    try {
      final headResponse = await dio.head(
        downloadUrl,
        options: Options(
          followRedirects: true,
          validateStatus: (status) => status! < 500,
        ),
      );
      if (headResponse.statusCode == 200) {
        final contentLength = headResponse.headers.value('content-length');
        if (contentLength != null) {
          noWatermarkSize = int.tryParse(contentLength) ?? 0;
        }
      }
    } catch (e) {
      debugPrint(
          'Không thể lấy kích thước file không watermark: ${e.toString()}');
    }

    // Lấy kích thước file có watermark nếu có
    int withWatermarkSize = 0;
    if (downloadUrlWithWatermark.isNotEmpty &&
        downloadUrlWithWatermark != downloadUrl) {
      try {
        final headResponse = await dio.head(
          downloadUrlWithWatermark,
          options: Options(
            followRedirects: true,
            validateStatus: (status) => status! < 500,
          ),
        );
        if (headResponse.statusCode == 200) {
          final contentLength = headResponse.headers.value('content-length');
          if (contentLength != null) {
            withWatermarkSize = int.tryParse(contentLength) ?? 0;
          }
        }
      } catch (e) {
        debugPrint(
            'Không thể lấy kích thước file có watermark: ${e.toString()}');
      }
    }

    final List<app_models.VideoQuality> qualities = [
      app_models.VideoQuality(
        label: 'Không watermark',
        url: downloadUrl,
        fileSize: noWatermarkSize,
      ),
    ];

    // Thêm phiên bản có watermark nếu khác với URL không watermark
    if (downloadUrlWithWatermark.isNotEmpty &&
        downloadUrlWithWatermark != downloadUrl) {
      qualities.add(
        app_models.VideoQuality(
          label: 'Có watermark',
          url: downloadUrlWithWatermark,
          fileSize: withWatermarkSize,
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
  }

  /// Phương pháp 2: Sử dụng TikWM API
  Future<app_models.VideoModel> getTikwmApiNoWatermark(
      String url, String videoId) async {
    final String apiUrl = 'https://www.tikwm.com/api/?url=$url';
    final response = await dio.get(apiUrl);

    if (response.statusCode == 200 && response.data != null) {
      final data = response.data;
      if (data['success'] == true && data['data'] != null) {
        final videoData = data['data'];

        final String title = videoData['title'] ?? 'TikTok Video';
        final String author =
            videoData['author']?['nickname'] ?? 'TikTok Creator';
        final String authorAvatar = videoData['author']?['avatar'] ?? '';
        final String cover =
            videoData['cover'] ?? videoData['origin_cover'] ?? '';

        // URL video
        final String downloadUrl = videoData['play'] ?? '';
        final String hdDownloadUrl = videoData['hdplay'] ?? downloadUrl;

        if (downloadUrl.isEmpty) {
          throw VideoApiException(
            message: 'Không tìm thấy URL tải xuống cho video TikTok',
          );
        }

        // Lấy kích thước file HD
        int hdFileSize = 0;
        if (hdDownloadUrl.isNotEmpty && hdDownloadUrl != downloadUrl) {
          try {
            final headHdResponse = await dio.head(
              hdDownloadUrl,
              options: Options(
                followRedirects: true,
                validateStatus: (status) => status! < 500,
              ),
            );
            if (headHdResponse.statusCode == 200) {
              final contentLength =
                  headHdResponse.headers.value('content-length');
              if (contentLength != null) {
                hdFileSize = int.tryParse(contentLength) ?? 0;
              }
            }
          } catch (e) {
            debugPrint('Không thể lấy kích thước file HD: ${e.toString()}');
          }
        }

        // Lấy kích thước file SD
        int sdFileSize = 0;
        try {
          final headSdResponse = await dio.head(
            downloadUrl,
            options: Options(
              followRedirects: true,
              validateStatus: (status) => status! < 500,
            ),
          );
          if (headSdResponse.statusCode == 200) {
            final contentLength =
                headSdResponse.headers.value('content-length');
            if (contentLength != null) {
              sdFileSize = int.tryParse(contentLength) ?? 0;
            }
          }
        } catch (e) {
          debugPrint('Không thể lấy kích thước file SD: ${e.toString()}');
        }

        final List<app_models.VideoQuality> qualities = [];

        if (hdDownloadUrl.isNotEmpty && hdDownloadUrl != downloadUrl) {
          qualities.add(
            app_models.VideoQuality(
              label: 'HD',
              url: hdDownloadUrl,
              fileSize: hdFileSize,
            ),
          );
        }

        qualities.add(
          app_models.VideoQuality(
            label: 'SD',
            url: downloadUrl,
            fileSize: sdFileSize,
          ),
        );

        // Thời lượng video
        final duration = videoData['duration'] != null
            ? Duration(seconds: int.parse(videoData['duration'].toString()))
            : const Duration(seconds: 15);

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
      }
    }

    throw VideoApiException(
        message: 'Không thể phân tích dữ liệu video TikTok từ TikWM API');
  }

  /// Phương pháp 3: Sử dụng SsstikIO (phiên bản đơn giản hóa)
  Future<app_models.VideoModel> getSsstikNoWatermark(
      String url, String videoId) async {
    try {
      // Sử dụng direct API thay vì cơ chế form phức tạp
      final response = await dio.get(
        'https://api.tikmate.app/api/lookup',
        queryParameters: {'url': url},
        options: Options(
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.212 Safari/537.36',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;

        // Trích xuất thông tin từ phản hồi
        String downloadUrl = data['downloadUrl'] ?? '';
        if (downloadUrl.isEmpty) {
          throw VideoApiException(
              message: 'Không tìm thấy URL tải xuống từ SsstikIO API');
        }

        // Lấy kích thước file từ header
        int fileSize = 0;
        try {
          final headResponse = await dio.head(
            downloadUrl,
            options: Options(
              followRedirects: true,
              validateStatus: (status) => status! < 500,
            ),
          );
          if (headResponse.statusCode == 200) {
            final contentLength = headResponse.headers.value('content-length');
            if (contentLength != null) {
              fileSize = int.tryParse(contentLength) ?? 0;
            }
          }
        } catch (e) {
          debugPrint('Không thể lấy kích thước file Tikmate: ${e.toString()}');
        }

        // Tạo danh sách chất lượng video
        final List<app_models.VideoQuality> qualities = [
          app_models.VideoQuality(
            label: 'HD (Không watermark)',
            url: downloadUrl,
            fileSize: fileSize,
          ),
        ];

        // Trích xuất thêm thông tin
        final String title = data['title'] ?? 'TikTok Video #$videoId';
        final String author = data['author'] ?? 'TikTok Creator';
        final String thumbnailUrl = data['thumbnail'] ?? '';

        return app_models.VideoModel(
          id: videoId,
          title: title,
          author: author,
          authorAvatarUrl: '',
          thumbnailUrl: thumbnailUrl,
          originalUrl: url,
          source: app_models.VideoSource.tiktok,
          duration: const Duration(seconds: 15),
          publishedAt: DateTime.now(),
          availableQualities: qualities,
        );
      }

      throw VideoApiException(
          message: 'Không thể phân tích dữ liệu video TikTok từ SsstikIO API');
    } catch (e) {
      if (e is VideoApiException) rethrow;
      throw VideoApiException(
          message: 'Lỗi kết nối với SsstikIO: ${e.toString()}');
    }
  }

  /// Phương pháp 4: Sử dụng SSSTIK.io API
  Future<app_models.VideoModel> getNewSsstikNoWatermark(
      String url, String videoId) async {
    try {
      // Lấy HTML trang SSSTIK.io để có được token
      final htmlResponse = await dio.get(
        'https://ssstik.io/en',
        options: Options(
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/105.0.0.0 Safari/537.36',
            'Accept':
                'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          },
        ),
      );

      // Trích xuất token tt từ HTML
      final htmlContent = htmlResponse.data.toString();
      // Tìm token tt trong HTML bằng regex đơn giản
      final regexPattern = r'tt:"([^"]*)"';
      final regex = RegExp(regexPattern);
      final match = regex.firstMatch(htmlContent);
      final tt = match?.group(1) ?? '';

      if (tt.isEmpty) {
        throw VideoApiException(
            message: 'Không thể lấy token bảo mật từ SSSTIK.io');
      }

      // Tạo form data với token
      final formData = FormData.fromMap({
        'id': url,
        'locale': 'en',
        'tt': tt,
      });

      // Gửi POST request để lấy video
      final response = await dio.post(
        'https://ssstik.io/abc?url=dl',
        data: formData,
        options: Options(
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/105.0.0.0 Safari/537.36',
            'Accept':
                'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            'Referer': 'https://ssstik.io/en',
          },
        ),
      );

      // Parse HTML để tìm liên kết tải xuống
      final htmlData = response.data.toString();

      // Regex cho URL không watermark
      final downloadRegex =
          RegExp(r'href="(https?://[^"]+)" class="without_watermark');
      final downloadMatch = downloadRegex.firstMatch(htmlData);
      final downloadUrl = downloadMatch?.group(1) ?? '';

      // Nếu không tìm thấy URL
      if (downloadUrl.isEmpty) {
        throw VideoApiException(
            message: 'Không tìm thấy URL tải xuống từ SSSTIK.io');
      }

      // Trích xuất thông tin cơ bản từ HTML
      final titleRegex = RegExp(r'<title[^>]*>([^<]+)</title>');
      final titleMatch = titleRegex.firstMatch(htmlData);
      String title = titleMatch?.group(1) ?? 'TikTok Video #$videoId';

      // Loại bỏ "TikTok video download" khỏi tiêu đề
      title = title.replaceAll(' TikTok video download', '').trim();

      // Regex cho author và thumbnail
      final authorRegex = RegExp(r'class="author[^"]*"[^>]*>([^<]+)</');
      final authorMatch = authorRegex.firstMatch(htmlData);
      final author = authorMatch?.group(1)?.trim() ?? 'TikTok Creator';

      // Lấy thông tin kích thước file
      int fileSize = 0;
      try {
        // Gửi HEAD request để lấy kích thước file
        final headResponse = await dio.head(
          downloadUrl,
          options: Options(
            followRedirects: true,
            validateStatus: (status) => status! < 500,
          ),
        );
        // Lấy kích thước từ header Content-Length
        if (headResponse.statusCode == 200) {
          final contentLength = headResponse.headers.value('content-length');
          if (contentLength != null) {
            fileSize = int.tryParse(contentLength) ?? 0;
          }
        }
      } catch (e) {
        debugPrint('Không thể lấy kích thước file: ${e.toString()}');
      }

      final List<app_models.VideoQuality> qualities = [
        app_models.VideoQuality(
          label: 'HD (Không watermark)',
          url: downloadUrl,
          fileSize: fileSize,
        ),
      ];

      return app_models.VideoModel(
        id: videoId,
        title: title,
        author: author,
        authorAvatarUrl: '',
        thumbnailUrl: '',
        originalUrl: url,
        source: app_models.VideoSource.tiktok,
        duration: const Duration(seconds: 15), // Mặc định 15s cho TikTok
        publishedAt: DateTime.now(),
        availableQualities: qualities,
      );
    } catch (e) {
      if (e is VideoApiException) rethrow;
      throw VideoApiException(
          message: 'Lỗi kết nối với SSSTIK.io: ${e.toString()}');
    }
  }

  /// Phương pháp 5: Sử dụng TikWM API trực tiếp
  Future<app_models.VideoModel> getDirectTikwmNoWatermark(
      String url, String videoId) async {
    try {
      final response = await dio.get(
        'https://www.tikwm.com/api/',
        queryParameters: {
          'url': url,
          'hd': '1',
        },
        options: Options(
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/105.0.0.0 Safari/537.36',
            'Accept': 'application/json',
            'Referer': 'https://www.tikwm.com/',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data['code'] == 0 && data['data'] != null) {
          final videoData = data['data'];

          // URL video không watermark
          String downloadUrl = videoData['play'] ?? '';
          if (downloadUrl.isEmpty) {
            throw VideoApiException(
                message: 'Không tìm thấy URL tải xuống từ TikWM API');
          }

          // URL HD (nếu có)
          final String hdDownloadUrl = videoData['hdplay'] ?? '';

          // Lấy kích thước file cho URL tiêu chuẩn
          int standardFileSize = 0;
          try {
            final headStandardResponse = await dio.head(
              downloadUrl,
              options: Options(
                followRedirects: true,
                validateStatus: (status) => status! < 500,
              ),
            );
            if (headStandardResponse.statusCode == 200) {
              final contentLength =
                  headStandardResponse.headers.value('content-length');
              if (contentLength != null) {
                standardFileSize = int.tryParse(contentLength) ?? 0;
              }
            }
          } catch (e) {
            debugPrint('Không thể lấy kích thước file SD: ${e.toString()}');
          }

          // Lấy kích thước file cho URL HD (nếu có)
          int hdFileSize = 0;
          if (hdDownloadUrl.isNotEmpty) {
            try {
              final headHdResponse = await dio.head(
                hdDownloadUrl,
                options: Options(
                  followRedirects: true,
                  validateStatus: (status) => status! < 500,
                ),
              );
              if (headHdResponse.statusCode == 200) {
                final contentLength =
                    headHdResponse.headers.value('content-length');
                if (contentLength != null) {
                  hdFileSize = int.tryParse(contentLength) ?? 0;
                }
              }
            } catch (e) {
              debugPrint('Không thể lấy kích thước file HD: ${e.toString()}');
            }
          }

          // Tạo danh sách chất lượng video
          final List<app_models.VideoQuality> qualities = [];

          // Thêm phiên bản HD nếu có
          if (hdDownloadUrl.isNotEmpty) {
            qualities.add(
              app_models.VideoQuality(
                label: 'HD (Không watermark)',
                url: hdDownloadUrl,
                fileSize: hdFileSize,
              ),
            );
          }

          // Luôn thêm phiên bản chuẩn
          qualities.add(
            app_models.VideoQuality(
              label: 'SD (Không watermark)',
              url: downloadUrl,
              fileSize: standardFileSize,
            ),
          );

          // Trích xuất các thông tin khác
          final String title = videoData['title'] ?? 'TikTok Video #$videoId';
          final String author =
              videoData['author']['nickname'] ?? 'TikTok Creator';
          final String authorAvatar = videoData['author']['avatar'] ?? '';
          final String thumbnailUrl =
              videoData['cover'] ?? videoData['origin_cover'] ?? '';

          // Lấy thời lượng
          final int durationSeconds =
              int.tryParse(videoData['duration'].toString()) ?? 15;

          return app_models.VideoModel(
            id: videoId,
            title: title,
            author: author,
            authorAvatarUrl: authorAvatar,
            thumbnailUrl: thumbnailUrl,
            originalUrl: url,
            source: app_models.VideoSource.tiktok,
            duration: Duration(seconds: durationSeconds),
            publishedAt: DateTime.now(),
            availableQualities: qualities,
          );
        }
      }

      throw VideoApiException(
          message: 'Không thể phân tích dữ liệu video TikTok từ TikWM API');
    } catch (e) {
      if (e is VideoApiException) rethrow;
      throw VideoApiException(
          message: 'Lỗi kết nối với TikWM API: ${e.toString()}');
    }
  }

  @override
  app_models.VideoSource get supportedPlatform => app_models.VideoSource.tiktok;
}

/// Factory để tạo API client phù hợp với nguồn video
class VideoApiClientFactory {
  final Dio _dio;

  /// Danh sách các client đang hoạt động
  final List<VideoApiClient> _activeClients = [];

  VideoApiClientFactory(this._dio);

  /// Tạo API client dựa trên URL hoặc nguồn được chỉ định
  VideoApiClient createClient(String url, {app_models.VideoSource? source}) {
    // Xác định nguồn từ URL nếu không được chỉ định
    source ??= _determineSourceFromUrl(url);

    // Tạo client mới
    VideoApiClient client;
    switch (source) {
      case app_models.VideoSource.youtube:
        client = YoutubeApiClient(_dio);
        break;
      case app_models.VideoSource.tiktok:
        client = TiktokApiClient(_dio);
        break;
      case app_models.VideoSource.instagram:
      case app_models.VideoSource.facebook:
      case app_models.VideoSource.twitter:
      case app_models.VideoSource.other:
      default:
        throw Exception('Nền tảng ${source.toString()} chưa được hỗ trợ');
    }

    // Thêm vào danh sách client hoạt động
    _activeClients.add(client);
    return client;
  }

  /// Lấy danh sách các client đang hoạt động
  List<VideoApiClient> getActiveClients() {
    return List.unmodifiable(_activeClients);
  }

  /// Xóa client khỏi danh sách hoạt động
  void removeClient(VideoApiClient client) {
    _activeClients.remove(client);
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
