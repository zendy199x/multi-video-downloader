import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:multi_video_downloader/features/common/models/video_model.dart'
    as app_models;
import 'package:multi_video_downloader/core/utils/app_constants.dart';

/// Widget hiển thị tiến trình tải xuống video
class DownloadProgressWidget extends StatelessWidget {
  /// Video đang được tải xuống
  final app_models.VideoModel video;

  /// Chất lượng đã chọn
  final app_models.VideoQuality selectedQuality;

  /// Tiến trình tải xuống (0-100)
  final int progressPercent;

  /// Tốc độ tải xuống hiện tại (định dạng chuỗi)
  final String? downloadSpeed;

  /// Số byte đã nhận
  final int? receivedBytes;

  /// Tổng số byte
  final int? totalBytes;

  /// Callback khi hủy tải xuống
  final VoidCallback onCancel;

  /// Constructor
  const DownloadProgressWidget({
    Key? key,
    required this.video,
    required this.selectedQuality,
    required this.progressPercent,
    required this.onCancel,
    this.downloadSpeed,
    this.receivedBytes,
    this.totalBytes,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Tạo text hiển thị dung lượng đã tải và tốc độ
    String progressText = '';

    // Hiển thị tốc độ tải xuống nếu có (đặt trước phần trăm)
    if (downloadSpeed != null && downloadSpeed!.isNotEmpty) {
      progressText += '$downloadSpeed | ';
    }

    // Thêm phần trăm tiến trình
    progressText += '$progressPercent%';

    // Hiển thị dung lượng đã tải / tổng dung lượng
    if (receivedBytes != null && totalBytes != null && totalBytes! > 0) {
      final receivedMB = (receivedBytes! / (1024 * 1024)).toStringAsFixed(1);
      final totalMB = (totalBytes! / (1024 * 1024)).toStringAsFixed(1);
      progressText += ' | $receivedMB/$totalMB MB';
    } else if (selectedQuality.formattedFileSize.isNotEmpty) {
      progressText += ' | ${selectedQuality.formattedFileSize}';
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: video.thumbnailUrl,
                  width: 80,
                  height: 60,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey.shade300,
                    width: 80,
                    height: 60,
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey.shade300,
                    width: 80,
                    height: 60,
                    child: const Icon(Icons.error),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Thông tin video
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      video.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      video.author,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color:
                            theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // Platform badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Color(video.sourceColor).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            video.sourceName,
                            style: TextStyle(
                              color: Color(video.sourceColor),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Quality badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.primaryColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            selectedQuality.label,
                            style: TextStyle(
                              color: theme.primaryColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Nút hủy
              IconButton(
                icon: const Icon(Icons.cancel),
                color: Colors.red,
                onPressed: onCancel,
                tooltip: 'Hủy tải xuống',
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Đang tải xuống...',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    progressText,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Progress indicator
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progressPercent / 100,
                  minHeight: 8,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  valueColor:
                      AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                ),
              ),
            ],
          ),

          // Hiển thị thông báo tùy theo tiến trình
          if (progressPercent < 10)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Đang khởi tạo tải xuống...',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                ),
              ),
            )
          else if (progressPercent >= 10 && progressPercent < 99)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Tải xuống đang tiến hành, vui lòng chờ...',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                ),
              ),
            )
          else if (progressPercent >= 99)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Đang hoàn tất tải xuống...',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
