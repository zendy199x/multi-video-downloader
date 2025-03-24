import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:multi_video_downloader/core/theme/app_theme.dart';

/// Widget trường nhập liệu URL
class UrlInputField extends StatelessWidget {
  /// TextEditingController cho trường nhập liệu
  final TextEditingController controller;

  /// Focus node cho trường nhập liệu
  final FocusNode? focusNode;

  /// Callback khi người dùng gửi URL
  final VoidCallback onSubmit;

  /// Callback khi nhấn nút dán
  final VoidCallback onPastePressed;

  /// Placeholder text
  final String hintText;

  /// Constructor
  const UrlInputField({
    Key? key,
    required this.controller,
    this.focusNode,
    required this.onSubmit,
    required this.onPastePressed,
    this.hintText = 'Dán liên kết video vào đây...',
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Liên kết video',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.titleMedium?.color,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    hintText: hintText,
                    filled: true,
                    fillColor: theme.scaffoldBackgroundColor,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: theme.dividerColor,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: theme.dividerColor,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: theme.primaryColor,
                        width: 1.5,
                      ),
                    ),
                    suffixIcon: controller.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              controller.clear();
                            },
                          )
                        : null,
                  ),
                  textInputAction: TextInputAction.go,
                  keyboardType: TextInputType.url,
                  onSubmitted: (_) => onSubmit(),
                  onChanged: (_) {
                    // Để kích hoạt rebuild khi văn bản thay đổi
                    (context as Element).markNeedsBuild();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Column(
                  children: [
                    // Nút dán
                    Material(
                      color: theme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        onTap: onPastePressed,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.content_paste,
                                size: 16,
                                color: theme.primaryColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Dán',
                                style: TextStyle(
                                  color: theme.primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: controller.text.isNotEmpty ? onSubmit : null,
              icon: const Icon(Icons.search),
              label: const Text('Tìm kiếm video'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Hỗ trợ YouTube, TikTok, Facebook, Instagram và Twitter',
              style: TextStyle(
                fontSize: 12,
                color: theme.hintColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
