import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:multi_video_downloader/features/common/models/video_model.dart'
    as app_models;
import 'package:intl/intl.dart';

/// Widget hiển thị thông tin video
class VideoInfoCard extends StatelessWidget {
  /// Thông tin video
  final app_models.VideoModel video;

  /// Callback khi chọn chất lượng video
  final Function(app_models.VideoQuality) onQualitySelected;

  /// Chất lượng đã chọn
  final app_models.VideoQuality? selectedQuality;

  /// Constructor
  const VideoInfoCard({
    Key? key,
    required this.video,
    required this.onQualitySelected,
    this.selectedQuality,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          _buildThumbnail(context),

          // Video Info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tiêu đề
                Text(
                  video.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // Tác giả và thời gian đăng
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      size: 16,
                      color:
                          theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      video.author,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (video.publishedAt != null) ...[
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color:
                            theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatPublishedDate(video.publishedAt!),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodyMedium?.color
                              ?.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),

                // Chọn chất lượng
                Text(
                  'Chọn chất lượng:',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: video.availableQualities.map((quality) {
                    return _buildQualityChip(context, quality);
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Xây dựng phần thumbnail
  Widget _buildThumbnail(BuildContext context) {
    return Stack(
      children: [
        // Thumbnail image
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: CachedNetworkImage(
              imageUrl: video.thumbnailUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey.shade300,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey.shade300,
                child: const Icon(Icons.error, size: 40),
              ),
            ),
          ),
        ),

        // Platform badge
        Positioned(
          top: 8,
          left: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Color(video.sourceColor).withOpacity(0.9),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              video.sourceName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),

        // Duration badge
        if (video.duration != null)
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                video.formattedDuration,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Xây dựng chip chọn chất lượng video
  Widget _buildQualityChip(
      BuildContext context, app_models.VideoQuality quality) {
    final theme = Theme.of(context);
    final isSelected = selectedQuality == quality;

    return GestureDetector(
      onTap: () => onQualitySelected(quality),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.primaryColor.withOpacity(0.1)
              : theme.cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? theme.primaryColor : theme.dividerColor,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.high_quality,
                  size: 16,
                  color:
                      isSelected ? theme.primaryColor : theme.iconTheme.color,
                ),
                const SizedBox(width: 4),
                Text(
                  quality.label,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? theme.primaryColor
                        : theme.textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              quality.formattedFileSize,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Format ngày xuất bản
  String _formatPublishedDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }
}
