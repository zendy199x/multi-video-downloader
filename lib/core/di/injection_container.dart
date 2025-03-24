import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:multi_video_downloader/core/api/video_api_client.dart';
import 'package:multi_video_downloader/features/download/bloc/video_download_bloc.dart';
import 'package:multi_video_downloader/features/download/repository/video_download_repository.dart';

/// Service locator instance
final sl = GetIt.instance;

/// Khởi tạo các dependencies
Future<void> init() async {
  // Core
  sl.registerLazySingleton<Dio>(() => Dio());
  sl.registerLazySingleton<InternetConnectionChecker>(
      () => InternetConnectionChecker());

  // API Client Factory
  sl.registerLazySingleton<VideoApiClientFactory>(
      () => VideoApiClientFactory(sl()));

  // Repositories
  sl.registerLazySingleton<VideoDownloadRepository>(
    () => VideoDownloadRepository(
      apiClientFactory: sl(),
      connectionChecker: sl(),
    ),
  );

  // BLoCs
  sl.registerFactory<VideoDownloadBloc>(
    () => VideoDownloadBloc(
      downloadRepository: sl(),
      connectionChecker: sl(),
    ),
  );
}
