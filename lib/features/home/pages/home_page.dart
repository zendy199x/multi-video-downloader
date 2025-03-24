import 'dart:io' show File, Platform, Process;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:lottie/lottie.dart';
import 'package:clipboard/clipboard.dart';
import 'package:multi_video_downloader/features/common/models/video_model.dart'
    as app_models;
import 'package:multi_video_downloader/features/common/widgets/download_progress_widget.dart';
import 'package:multi_video_downloader/features/common/widgets/platform_selector.dart';
import 'package:multi_video_downloader/features/common/widgets/url_input_field.dart';
import 'package:multi_video_downloader/features/common/widgets/video_info_card.dart';
import 'package:multi_video_downloader/features/download/bloc/video_download_bloc.dart';
import 'package:multi_video_downloader/core/theme/app_theme.dart';
import 'package:multi_video_downloader/core/utils/app_constants.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher.dart';

/// Trang chính của ứng dụng
class HomePage extends StatefulWidget {
  /// Constructor
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _urlController = TextEditingController();
  final FocusNode _urlFocusNode = FocusNode();

  app_models.VideoSource? _selectedPlatform;
  app_models.VideoQuality? _selectedQuality;
  bool _isOpeningDirectory = false;
  bool _isOpeningFile = false;

  @override
  void initState() {
    super.initState();
    _checkClipboard();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _urlFocusNode.dispose();
    super.dispose();
  }

  /// Kiểm tra clipboard khi ứng dụng khởi động
  Future<void> _checkClipboard() async {
    try {
      final clipboardContent = await FlutterClipboard.paste();
      if (clipboardContent.isNotEmpty && _isValidUrl(clipboardContent)) {
        _urlController.text = clipboardContent;
      }
    } catch (e) {
      debugPrint('Lỗi khi đọc clipboard: $e');
    }
  }

  /// Kiểm tra xem URL có hợp lệ không
  bool _isValidUrl(String url) {
    return AppConstants.isValidVideoUrl(url);
  }

  /// Dán từ clipboard
  Future<void> _pasteFromClipboard() async {
    try {
      final clipboardContent = await FlutterClipboard.paste();
      if (clipboardContent.isNotEmpty) {
        setState(() {
          _urlController.text = clipboardContent;
        });
      }
    } catch (e) {
      debugPrint('Lỗi khi dán từ clipboard: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể dán từ clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Gửi URL để phân tích
  void _submitUrl() {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập URL video'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (!_isValidUrl(url)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('URL không hợp lệ hoặc không được hỗ trợ'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    context.read<VideoDownloadBloc>().add(
          CheckVideoUrl(
            url: url,
          ),
        );

    // Ẩn bàn phím
    FocusScope.of(context).unfocus();
  }

  /// Xử lý khi người dùng chọn nền tảng
  void _onPlatformSelected(app_models.VideoSource platform) {
    setState(() {
      _selectedPlatform = platform;
    });
  }

  /// Xử lý khi người dùng chọn chất lượng video
  void _onQualitySelected(app_models.VideoQuality quality) {
    setState(() {
      _selectedQuality = quality;
    });
  }

  /// Tải xuống video
  void _downloadVideo(
      app_models.VideoModel video, app_models.VideoQuality quality) {
    context.read<VideoDownloadBloc>().add(
          DownloadVideo(
            videoModel: video,
            quality: quality,
          ),
        );
  }

  /// Hủy tải xuống
  void _cancelDownload() {
    final bloc = context.read<VideoDownloadBloc>();
    if (bloc.state is VideoDownloadInProgress) {
      final downloadState = bloc.state as VideoDownloadInProgress;
      bloc.add(CancelDownload(videoModel: downloadState.videoModel));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.headlineSmall,
            children: [
              TextSpan(
                text: 'MultiVid ',
                style: TextStyle(
                  color: Theme.of(context).textTheme.headlineSmall?.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: 'Downloader',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              // TODO: Mở trang cài đặt
            },
          ),
        ],
      ),
      body: BlocConsumer<VideoDownloadBloc, VideoDownloadState>(
        listener: (context, state) {
          if (state is VideoDownloadError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
                action: SnackBarAction(
                  label: 'OK',
                  textColor: Colors.white,
                  onPressed: () {},
                ),
              ),
            );
          } else if (state is VideoDownloadComplete) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Tải xuống hoàn tất: ${path.basename(state.filePath)}'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
                action: SnackBarAction(
                  label: 'Mở',
                  textColor: Colors.white,
                  onPressed: () => _openFile(state.filePath),
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Input URL
                UrlInputField(
                  controller: _urlController,
                  focusNode: _urlFocusNode,
                  onSubmit: _submitUrl,
                  onPastePressed: _pasteFromClipboard,
                ),

                const SizedBox(height: 16),

                // Chọn nền tảng
                if (_selectedPlatform == null && state is VideoDownloadInitial)
                  PlatformSelector(
                    selectedPlatform: _selectedPlatform,
                    onPlatformSelected: _onPlatformSelected,
                  ),

                const SizedBox(height: 16),

                // Hiển thị trạng thái
                _buildStatusWidget(state),

                // Hiển thị thông tin video
                if (state is VideoInfoLoaded)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: VideoInfoCard(
                      video: state.videoModel,
                      onQualitySelected: _onQualitySelected,
                      selectedQuality: _selectedQuality,
                    ),
                  ),

                // Hiển thị nút tải xuống
                if (state is VideoInfoLoaded && _selectedQuality != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('Tải xuống video'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () =>
                          _downloadVideo(state.videoModel, _selectedQuality!),
                    ),
                  ),

                // Hiển thị tiến trình tải xuống
                if (state is VideoDownloadInProgress)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: DownloadProgressWidget(
                      video: state.videoModel,
                      selectedQuality: state.quality,
                      progressPercent: state.progress,
                      downloadSpeed: state.downloadSpeed,
                      receivedBytes: state.receivedBytes,
                      totalBytes: state.totalBytes,
                      onCancel: _cancelDownload,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Xây dựng widget hiển thị trạng thái
  Widget _buildStatusWidget(VideoDownloadState state) {
    if (state is VideoInfoLoading) {
      return _buildLoadingWidget('Đang tải thông tin video...');
    } else if (state is VideoDownloadInitial) {
      return _buildInitialStateWidget();
    } else if (state is VideoDownloadComplete) {
      return _buildCompletedWidget(state.filePath);
    } else if (state is VideoDownloadCancelled) {
      return _buildCancelledWidget();
    } else {
      return Container();
    }
  }

  /// Widget hiển thị trạng thái đang tải
  Widget _buildLoadingWidget(String message) {
    return Center(
      child: Column(
        children: [
          const SpinKitPulse(
            color: Colors.blue,
            size: 80.0,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Widget hiển thị trạng thái ban đầu
  Widget _buildInitialStateWidget() {
    return Center(
      child: Column(
        children: [
          Lottie.network(
            'https://assets6.lottiefiles.com/private_files/lf30_y9czxcb9.json',
            width: 200,
            height: 200,
          ),
          const SizedBox(height: 16),
          Text(
            'Dán URL video để bắt đầu tải xuống',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Mở file video
  Future<void> _openFile(String filePath) async {
    // Nếu đang xử lý, không cho phép người dùng nhấn lại
    if (_isOpeningFile) return;

    try {
      // Đánh dấu đang trong quá trình xử lý
      setState(() {
        _isOpeningFile = true;
      });

      final file = File(filePath);
      if (await file.exists()) {
        try {
          final result = await OpenFile.open(filePath);
          if (result.type != ResultType.done) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Không thể mở file: ${result.message}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Lỗi khi mở file: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File không tồn tại'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      // Đảm bảo luôn reset trạng thái sau khi hoàn thành
      if (mounted) {
        setState(() {
          _isOpeningFile = false;
        });
      }
    }
  }

  /// Mở thư mục chứa file
  Future<void> _openDirectory(String filePath) async {
    // Nếu đang xử lý, không cho phép người dùng nhấn lại
    if (_isOpeningDirectory) return;

    try {
      // Đánh dấu đang trong quá trình xử lý
      setState(() {
        _isOpeningDirectory = true;
      });

      final directory = path.dirname(filePath);
      final file = File(filePath);

      if (Platform.isAndroid) {
        // Sử dụng thư viện mở thư mục trên Android
        try {
          // Phương pháp 1: Dùng Storage Access Framework để mở thư mục (Android 11+)
          final uri = Uri.parse(
              'content://com.android.externalstorage.documents/document/primary:${directory.replaceAll('/storage/emulated/0/', '')}');
          final result = await launchUrl(uri);

          if (!result) {
            // Phương pháp 2: Sử dụng OpenFile để mở thư mục cha của file
            final openResult = await OpenFile.open(directory);

            if (openResult.type != ResultType.done) {
              // Phương pháp 3: Nếu không mở được thư mục, hiển thị đường dẫn và mở file manager
              await launchUrl(Uri.parse(
                  'content://com.android.externalstorage.documents/root/primary'));

              // Hiển thị đường dẫn đến file
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đường dẫn file: $directory'),
                    backgroundColor: Colors.blue,
                    duration: const Duration(seconds: 5),
                  ),
                );
              }
            }
          }
        } catch (e) {
          // Thử mở file manager
          await launchUrl(Uri.parse(
              'content://com.android.externalstorage.documents/root/primary'));

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('File đã được lưu tại:\n$directory'),
                backgroundColor: Colors.blue,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }
      } else if (Platform.isIOS) {
        // iOS không hỗ trợ mở thư mục nên hiển thị đường dẫn và mở ứng dụng Files
        try {
          // Thử dùng url_launcher để mở ứng dụng Files
          final filesUrl = Uri.parse('shareddocuments://');
          final canLaunch = await canLaunchUrl(filesUrl);

          if (canLaunch) {
            await launchUrl(filesUrl);
          }

          // Hiển thị thông tin đường dẫn
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Đường dẫn file: $directory'),
                backgroundColor: Colors.blue,
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'Mở Files',
                  onPressed: () async {
                    final openResult = await OpenFile.open(directory);
                    if (openResult.type != ResultType.done) {
                      await launchUrl(filesUrl);
                    }
                  },
                ),
              ),
            );
          }
        } catch (e) {
          // Nếu không thể mở, chỉ hiển thị đường dẫn
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Đường dẫn file: $directory'),
                backgroundColor: Colors.blue,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }
      } else if (Platform.isMacOS) {
        await Process.run('open', [directory]);
      } else if (Platform.isWindows) {
        await Process.run('explorer', [directory.replaceAll('/', '\\')]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [directory]);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không hỗ trợ mở thư mục trên nền tảng này'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi mở thư mục: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Đảm bảo luôn reset trạng thái sau khi hoàn thành
      if (mounted) {
        setState(() {
          _isOpeningDirectory = false;
        });
      }
    }
  }

  /// Widget hiển thị trạng thái đã tải xuống hoàn tất
  Widget _buildCompletedWidget(String filePath) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 48,
              ),
              const SizedBox(height: 8),
              const Text(
                'Tải xuống hoàn tất',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                path.basename(filePath),
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton.icon(
                    onPressed: _isOpeningDirectory
                        ? null
                        : () => _openDirectory(filePath),
                    icon: _isOpeningDirectory
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.folder_open),
                    label: const Text('Mở thư mục'),
                  ),
                  ElevatedButton.icon(
                    onPressed:
                        _isOpeningFile ? null : () => _openFile(filePath),
                    icon: _isOpeningFile
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.play_arrow),
                    label: const Text('Xem video'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Widget hiển thị trạng thái hủy tải xuống
  Widget _buildCancelledWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Tải xuống đã bị hủy',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
