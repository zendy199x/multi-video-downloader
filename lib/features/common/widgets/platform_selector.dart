import 'package:flutter/material.dart';
import 'package:multi_video_downloader/features/common/models/video_model.dart';

/// Widget cho phép người dùng chọn nền tảng video
class PlatformSelector extends StatelessWidget {
  /// Nền tảng đã chọn
  final VideoSource? selectedPlatform;

  /// Callback khi người dùng chọn nền tảng
  final Function(VideoSource) onPlatformSelected;

  /// Constructor
  const PlatformSelector({
    Key? key,
    this.selectedPlatform,
    required this.onPlatformSelected,
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
          )
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chọn nền tảng',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.titleMedium?.color,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildPlatformButton(
                context,
                VideoSource.youtube,
                'YouTube',
                const Color(0xFFFF0000),
                Icons.play_circle_fill,
              ),
              _buildPlatformButton(
                context,
                VideoSource.tiktok,
                'TikTok',
                const Color(0xFF000000),
                Icons.music_note,
              ),
              _buildPlatformButton(
                context,
                VideoSource.instagram,
                'Instagram',
                const Color(0xFFE1306C),
                Icons.camera_alt,
              ),
              _buildPlatformButton(
                context,
                VideoSource.facebook,
                'Facebook',
                const Color(0xFF1877F2),
                Icons.facebook,
              ),
              _buildPlatformButton(
                context,
                VideoSource.twitter,
                'Twitter',
                const Color(0xFF1DA1F2),
                Icons.message,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Xây dựng nút chọn nền tảng
  Widget _buildPlatformButton(
    BuildContext context,
    VideoSource platform,
    String name,
    Color color,
    IconData icon,
  ) {
    final bool isSelected = selectedPlatform == platform;
    final theme = Theme.of(context);

    return Material(
      color: isSelected ? color.withOpacity(0.1) : theme.cardColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => onPlatformSelected(platform),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? color : theme.dividerColor,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? color : theme.iconTheme.color,
              ),
              const SizedBox(width: 6),
              Text(
                name,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                  color: isSelected ? color : theme.textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
