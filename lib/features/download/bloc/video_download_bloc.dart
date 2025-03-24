import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:multi_video_downloader/core/utils/download_progress.dart';
import 'package:multi_video_downloader/features/common/models/video_model.dart'
    as app_models;
import 'package:multi_video_downloader/features/download/repository/video_download_repository.dart';
import 'package:multi_video_downloader/core/utils/app_constants.dart';
import 'package:multi_video_downloader/core/api/video_api_client.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

// EVENTS

/// Events cho VideoDownloadBloc
abstract class VideoDownloadEvent extends Equatable {
  const VideoDownloadEvent();

  @override
  List<Object?> get props => [];
}

/// Event kiểm tra URL video
class CheckVideoUrl extends VideoDownloadEvent {
  final String url;

  const CheckVideoUrl({required this.url});

  @override
  List<Object> get props => [url];
}

/// Event yêu cầu tải xuống video
class DownloadVideo extends VideoDownloadEvent {
  final app_models.VideoModel videoModel;
  final app_models.VideoQuality quality;

  const DownloadVideo({required this.videoModel, required this.quality});

  @override
  List<Object> get props => [videoModel, quality];
}

/// Event hủy tải xuống video
class CancelDownload extends VideoDownloadEvent {
  final app_models.VideoModel videoModel;

  const CancelDownload({required this.videoModel});

  @override
  List<Object> get props => [videoModel];
}

// STATES

/// States cho VideoDownloadBloc
abstract class VideoDownloadState extends Equatable {
  const VideoDownloadState();

  @override
  List<Object?> get props => [];
}

/// Trạng thái ban đầu
class VideoDownloadInitial extends VideoDownloadState {}

/// Đang tải thông tin video
class VideoInfoLoading extends VideoDownloadState {}

/// Đã tải xong thông tin video
class VideoInfoLoaded extends VideoDownloadState {
  final app_models.VideoModel videoModel;

  const VideoInfoLoaded({required this.videoModel});

  @override
  List<Object> get props => [videoModel];
}

/// Đang tải xuống video
class VideoDownloadInProgress extends VideoDownloadState {
  final app_models.VideoModel videoModel;
  final app_models.VideoQuality quality;
  final int progress;

  const VideoDownloadInProgress({
    required this.videoModel,
    required this.quality,
    required this.progress,
  });

  @override
  List<Object> get props => [videoModel, quality, progress];
}

/// Tải xuống hoàn tất
class VideoDownloadComplete extends VideoDownloadState {
  final app_models.VideoModel videoModel;
  final app_models.VideoQuality quality;
  final String filePath;

  const VideoDownloadComplete({
    required this.videoModel,
    required this.quality,
    required this.filePath,
  });

  @override
  List<Object> get props => [videoModel, quality, filePath];
}

/// Tải xuống bị hủy
class VideoDownloadCancelled extends VideoDownloadState {
  final app_models.VideoModel videoModel;
  final app_models.VideoQuality quality;

  const VideoDownloadCancelled({
    required this.videoModel,
    required this.quality,
  });

  @override
  List<Object> get props => [videoModel, quality];
}

/// Lỗi trong quá trình tải xuống
class VideoDownloadError extends VideoDownloadState {
  final String message;

  const VideoDownloadError({required this.message});

  @override
  List<Object> get props => [message];
}

// BLOC IMPLEMENTATION

/// BloC để quản lý trạng thái tải xuống video
class VideoDownloadBloc extends Bloc<VideoDownloadEvent, VideoDownloadState> {
  final VideoDownloadRepository _downloadRepository;
  final InternetConnectionChecker _connectionChecker;

  VideoDownloadBloc({
    required VideoDownloadRepository downloadRepository,
    required InternetConnectionChecker connectionChecker,
  })  : _downloadRepository = downloadRepository,
        _connectionChecker = connectionChecker,
        super(VideoDownloadInitial()) {
    on<CheckVideoUrl>(_onCheckVideoUrl);
    on<DownloadVideo>(_onDownloadVideo);
    on<CancelDownload>(_onCancelDownload);
  }

  /// Xử lý sự kiện kiểm tra URL video
  Future<void> _onCheckVideoUrl(
    CheckVideoUrl event,
    Emitter<VideoDownloadState> emit,
  ) async {
    // Kiểm tra kết nối mạng
    final hasConnection = await _connectionChecker.hasConnection;
    if (!hasConnection) {
      emit(VideoDownloadError(message: AppConstants.connectionError));
      return;
    }

    emit(VideoInfoLoading());

    try {
      final videoModel = await _downloadRepository.getVideoInfo(event.url);
      emit(VideoInfoLoaded(videoModel: videoModel));
    } on VideoDownloadException catch (e) {
      emit(VideoDownloadError(message: e.message));
    } catch (e) {
      emit(VideoDownloadError(message: 'Lỗi không xác định: ${e.toString()}'));
    }
  }

  /// Xử lý sự kiện tải xuống video
  Future<void> _onDownloadVideo(
    DownloadVideo event,
    Emitter<VideoDownloadState> emit,
  ) async {
    // Kiểm tra kết nối mạng
    final hasConnection = await _connectionChecker.hasConnection;
    if (!hasConnection) {
      emit(VideoDownloadError(message: AppConstants.connectionError));
      return;
    }

    emit(
      VideoDownloadInProgress(
        videoModel: event.videoModel,
        quality: event.quality,
        progress: 0,
      ),
    );

    try {
      String filePath = await _downloadRepository.downloadVideo(
        video: event.videoModel,
        quality: event.quality,
        onProgress: (received, total) {
          if (total != -1) {
            final progress = (received / total * 100).toInt();
            emit(
              VideoDownloadInProgress(
                videoModel: event.videoModel,
                quality: event.quality,
                progress: progress,
              ),
            );
          }
        },
        onStatusChanged: (status, path) {
          if (status == DownloadStatus.cancelled) {
            emit(
              VideoDownloadCancelled(
                videoModel: event.videoModel,
                quality: event.quality,
              ),
            );
          } else if (status == DownloadStatus.completed && path != null) {
            emit(
              VideoDownloadComplete(
                videoModel: event.videoModel,
                quality: event.quality,
                filePath: path,
              ),
            );
          } else if (status == DownloadStatus.failed) {
            emit(VideoDownloadError(message: path ?? 'Lỗi tải xuống video'));
          }
        },
        onCancelled: () {
          emit(
            VideoDownloadCancelled(
              videoModel: event.videoModel,
              quality: event.quality,
            ),
          );
        },
      );

      if (filePath.isNotEmpty) {
        emit(
          VideoDownloadComplete(
            videoModel: event.videoModel,
            quality: event.quality,
            filePath: filePath,
          ),
        );
      }
    } catch (e) {
      emit(VideoDownloadError(message: 'Lỗi tải xuống: ${e.toString()}'));
    }
  }

  /// Xử lý sự kiện hủy tải xuống
  void _onCancelDownload(
    CancelDownload event,
    Emitter<VideoDownloadState> emit,
  ) {
    // Chúng ta xử lý vấn đề này trong _onDownloadVideo với tham số onCancel
    // Nhưng chúng ta vẫn cần một sự kiện để biểu thị ý định hủy
  }
}
