import 'package:equatable/equatable.dart';

/// Enum đại diện cho các nền tảng video được hỗ trợ
enum VideoSource {
  youtube,
  tiktok,
  facebook,
  instagram,
  twitter,
  other,
}

/// Model chất lượng video
class VideoQuality {
  /// Label để hiển thị (e.g., '720p', '1080p HD')
  final String label;

  /// Kích thước tệp tính theo byte
  final int fileSize;

  /// URL trực tiếp để tải xuống
  final String url;

  /// Chiều cao video (nếu có)
  final int? height;

  /// Chiều rộng video (nếu có)
  final int? width;

  /// Constructor
  const VideoQuality({
    required this.label,
    this.fileSize = 0,
    required this.url,
    this.height,
    this.width,
  });

  /// Format kích thước tệp theo cách đọc thân thiện với người dùng
  String get formattedFileSize {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else if (fileSize < 1024 * 1024 * 1024) {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// Alias cho url để tương thích với các phần khác của code
  String get downloadUrl => url;
}

/// Model cho video từ các nền tảng khác nhau
class VideoModel extends Equatable {
  /// ID duy nhất của video
  final String id;

  /// Tiêu đề video
  final String title;

  /// Tên tác giả/kênh
  final String author;

  /// URL đến avatar của tác giả
  final String? authorAvatarUrl;

  /// URL ảnh thu nhỏ của video
  final String thumbnailUrl;

  /// Thời lượng video
  final Duration? duration;

  /// Ngày xuất bản
  final DateTime? publishedAt;

  /// Nguồn video (YouTube, TikTok, etc.)
  final VideoSource source;

  /// URL gốc của video
  final String originalUrl;

  /// Danh sách các tùy chọn chất lượng có sẵn
  final List<VideoQuality> availableQualities;

  /// Đường dẫn cục bộ đến video đã tải xuống, nếu có
  final String? localPath;

  /// Constructor
  const VideoModel({
    required this.id,
    required this.title,
    required this.author,
    this.authorAvatarUrl,
    required this.thumbnailUrl,
    this.duration,
    this.publishedAt,
    required this.source,
    required this.originalUrl,
    required this.availableQualities,
    this.localPath,
  });

  /// Format thời lượng video thành 'MM:SS' hoặc 'HH:MM:SS'
  String get formattedDuration {
    if (duration == null) return '';

    final hours = duration!.inHours;
    final minutes = duration!.inMinutes.remainder(60);
    final seconds = duration!.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  /// Lấy tên nền tảng để hiển thị
  String get sourceName {
    switch (source) {
      case VideoSource.youtube:
        return 'YouTube';
      case VideoSource.tiktok:
        return 'TikTok';
      case VideoSource.facebook:
        return 'Facebook';
      case VideoSource.instagram:
        return 'Instagram';
      case VideoSource.twitter:
        return 'Twitter';
      case VideoSource.other:
        return 'Khác';
    }
  }

  /// Lấy màu liên quan đến nền tảng
  int get sourceColor {
    switch (source) {
      case VideoSource.youtube:
        return 0xFFFF0000; // YouTube Red
      case VideoSource.tiktok:
        return 0xFF000000; // TikTok Black
      case VideoSource.facebook:
        return 0xFF1877F2; // Facebook Blue
      case VideoSource.instagram:
        return 0xFFE1306C; // Instagram Pink
      case VideoSource.twitter:
        return 0xFF1DA1F2; // Twitter Blue
      case VideoSource.other:
        return 0xFF808080; // Gray
    }
  }

  /// Lấy chất lượng cao nhất có sẵn
  VideoQuality? get highestQuality {
    if (availableQualities.isEmpty) return null;
    return availableQualities.reduce(
      (max, quality) => max.fileSize > quality.fileSize ? max : quality,
    );
  }

  /// Lấy chất lượng thấp nhất có sẵn
  VideoQuality? get lowestQuality {
    if (availableQualities.isEmpty) return null;
    return availableQualities.reduce(
      (min, quality) => min.fileSize < quality.fileSize ? min : quality,
    );
  }

  /// Tạo bản sao với các giá trị mới
  VideoModel copyWith({
    String? id,
    String? title,
    String? author,
    String? authorAvatarUrl,
    String? thumbnailUrl,
    Duration? duration,
    DateTime? publishedAt,
    VideoSource? source,
    String? originalUrl,
    List<VideoQuality>? availableQualities,
    String? localPath,
  }) {
    return VideoModel(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      duration: duration ?? this.duration,
      publishedAt: publishedAt ?? this.publishedAt,
      source: source ?? this.source,
      originalUrl: originalUrl ?? this.originalUrl,
      availableQualities: availableQualities ?? this.availableQualities,
      localPath: localPath ?? this.localPath,
    );
  }

  /// Tạo một VideoModel trống để sử dụng khi cần
  factory VideoModel.empty() {
    return const VideoModel(
      id: 'empty',
      title: '',
      author: '',
      thumbnailUrl: '',
      originalUrl: '',
      source: VideoSource.other,
      availableQualities: [],
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        author,
        thumbnailUrl,
        duration,
        source,
        originalUrl,
        availableQualities
      ];
}
