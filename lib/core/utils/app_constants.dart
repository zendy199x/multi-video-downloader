import 'package:flutter/material.dart';

/// Các hằng số được sử dụng trong toàn bộ ứng dụng
class AppConstants {
  AppConstants._();

  /// Tên ứng dụng
  static const String appName = 'MultiVid Downloader';

  /// Người phát triển
  static const String developer = 'Zendy';

  /// Phiên bản ứng dụng
  static const String appVersion = '1.0.0';

  /// Địa chỉ trang web
  static const String website = 'https://zendycode.com';

  /// Email liên hệ
  static const String contactEmail = 'zendy199x@gmail.com';

  /// Github repository
  static const String githubRepo =
      'https://github.com/zendy199x/multi_video_downloader';

  /// Kích thước tối đa của tệp (100 MB)
  static const int maxFileSize = 100 * 1024 * 1024;

  /// Regex để khớp với URL YouTube
  static final RegExp youtubeUrlPattern = RegExp(
    r'^((?:https?:)?\/\/)?((?:www|m)\.)?((?:youtube(-nocookie)?\.com|youtu.be))(\/(?:[\w\-]+\?v=|embed\/|live\/|v\/)?)([\w\-]+)(\S+)?$',
  );

  /// Regex để khớp với URL TikTok
  static final RegExp tiktokUrlPattern = RegExp(
    r'^((?:https?:)?\/\/)?((?:www|m|vm)\.)?((?:tiktok\.com))(\/(?:@[\w.-]+\/video\/)?)([\w-]+)(\S+)?$',
  );

  /// Regex để khớp với URL Instagram
  static final RegExp instagramUrlPattern = RegExp(
    r'^((?:https?:)?\/\/)?((?:www|m)\.)?((?:instagram\.com))(\/(?:p|reel|tv)\/)([\w-]+)(\S+)?$',
  );

  /// Regex để khớp với URL Facebook
  static final RegExp facebookUrlPattern = RegExp(
    r'^((?:https?:)?\/\/)?((?:www|m|web|fb|facebook)\.)?((?:facebook\.com|fb\.watch))(\/(?:watch|story|reel|videos)?\/?)?((?:\?v=)?(?:[\w.-]+)?)(\S+)?$',
  );

  /// Regex để khớp với URL Twitter
  static final RegExp twitterUrlPattern = RegExp(
    r'^((?:https?:)?\/\/)?((?:www|m|mobile)\.)?((?:twitter\.com|x\.com))(\/(?:\w+)\/status\/)([\d]+)(\S+)?$',
  );

  /// Kiểm tra xem URL có phải là URL video từ bất kỳ nền tảng nào được hỗ trợ
  static bool isValidVideoUrl(String url) {
    return youtubeUrlPattern.hasMatch(url) ||
        tiktokUrlPattern.hasMatch(url) ||
        instagramUrlPattern.hasMatch(url) ||
        facebookUrlPattern.hasMatch(url) ||
        twitterUrlPattern.hasMatch(url);
  }

  /// Lấy ID của video từ URL YouTube
  static String? getYoutubeVideoId(String url) {
    final match = youtubeUrlPattern.firstMatch(url);
    return match?.group(6);
  }

  /// Lấy ID của video từ URL TikTok
  static String? getTiktokVideoId(String url) {
    final match = tiktokUrlPattern.firstMatch(url);
    return match?.group(5);
  }

  /// Lấy ID của video từ URL Instagram
  static String? getInstagramVideoId(String url) {
    final match = instagramUrlPattern.firstMatch(url);
    return match?.group(5);
  }

  /// Lấy ID của video từ URL Facebook
  static String? getFacebookVideoId(String url) {
    final match = facebookUrlPattern.firstMatch(url);
    return match?.group(5);
  }

  /// Lấy ID của video từ URL Twitter
  static String? getTwitterVideoId(String url) {
    final match = twitterUrlPattern.firstMatch(url);
    return match?.group(5);
  }

  /// Thư mục lưu video
  static const String downloadDirectory = 'MultiVid Downloads';

  /// Thời gian timeout cho API requests (30 giây)
  static const int apiTimeoutSeconds = 30;

  /// Base URL cho API
  static const String apiBaseUrl = 'https://api.multividdownloader.com';

  /// Thời gian giữa các lần kiểm tra cập nhật (7 ngày)
  static const Duration updateCheckInterval = Duration(days: 7);

  /// Khóa lưu trữ cho lịch sử tải xuống
  static const String downloadHistoryKey = 'download_history';

  /// Khóa lưu trữ cho cài đặt người dùng
  static const String userSettingsKey = 'user_settings';

  /// Số lượng lần thử lại tối đa cho các yêu cầu API
  static const int maxApiRetries = 3;

  // Storage Keys
  static const String kThemeMode = 'theme_mode';
  static const String kLastDownloadPath = 'last_download_path';

  // URLs - Regex Patterns
  static const String youtubePattern =
      r'^((?:https?:)?\/\/)?((?:www|m)\.)?((?:youtube\.com|youtu.be))(\/(?:[\w\-]+\?v=|embed\/|v\/)?)([\w\-]+)(\S+)?$';
  static const String tiktokPattern =
      r'https?:\/\/(www\.|vm\.|m\.)?tiktok\.com\/.+';
  static const String instagramPattern =
      r'https?:\/\/(www\.)?instagram\.com\/(p|reel|tv)\/([^/?#&]+).*';
  static const String facebookPattern =
      r'https?:\/\/(www\.|m\.|web\.|mbasic\.)?facebook\.com\/.*\/(videos|reel|watch|story).*';
  static const String twitterPattern =
      r'https?:\/\/(www\.)?twitter\.com\/[a-zA-Z0-9_]+\/status\/[0-9]+';

  // API endpoints
  static const String baseApiUrl = 'https://api.example.com';
  static const String youtubeDLEndpoint = '$baseApiUrl/youtube/info';
  static const String tiktokDLEndpoint = '$baseApiUrl/tiktok/info';
  static const String instagramDLEndpoint = '$baseApiUrl/instagram/info';
  static const String facebookDLEndpoint = '$baseApiUrl/facebook/info';
  static const String twitterDLEndpoint = '$baseApiUrl/twitter/info';

  // Messages
  static const String connectionError =
      'Không có kết nối internet. Vui lòng kiểm tra kết nối và thử lại.';
  static const String serverError =
      'Đã xảy ra lỗi máy chủ. Vui lòng thử lại sau.';
  static const String invalidUrlError =
      'URL không hợp lệ. Vui lòng kiểm tra và thử lại.';
  static const String unsupportedPlatformError =
      'Nền tảng này không được hỗ trợ.';
  static const String downloadStarted = 'Bắt đầu tải xuống...';
  static const String downloadComplete = 'Tải xuống hoàn tất!';
  static const String downloadError = 'Lỗi tải xuống. Vui lòng thử lại.';
  static const String downloadCancelled = 'Tải xuống đã bị hủy.';
  static const String permissionDenied = 'Cần quyền truy cập để lưu video.';

  // Supported Platforms
  static const List<String> supportedPlatforms = [
    'YouTube',
    'TikTok',
    'Instagram',
    'Facebook',
    'Twitter',
  ];

  // Download Quality Options
  static const List<String> downloadQualityOptions = [
    'HD (720p)',
    'Full HD (1080p)',
    '4K (2160p)',
    'Tự động (Chất lượng tốt nhất)',
    'Thấp (480p)',
  ];

  // Kích thước tệp
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1048576) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else if (bytes < 1073741824) {
      return '${(bytes / 1048576).toStringAsFixed(2)} MB';
    } else {
      return '${(bytes / 1073741824).toStringAsFixed(2)} GB';
    }
  }

  // Chủ đề
  static const Color primaryColor = Color(0xFF3366FF);
  static const Color secondaryColor = Color(0xFF00CCFF);
  static const Color accentColor = Color(0xFFFF6B6B);
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color darkBackgroundColor = Color(0xFF121212);
  static const Color textColor = Color(0xFF333333);
  static const Color darkTextColor = Color(0xFFEEEEEE);
}
