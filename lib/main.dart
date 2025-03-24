import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:multi_video_downloader/core/di/injection_container.dart' as di;
import 'package:multi_video_downloader/core/theme/app_theme.dart';
import 'package:multi_video_downloader/features/download/bloc/video_download_bloc.dart';
import 'package:multi_video_downloader/features/home/pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cố định hướng ứng dụng thành dọc
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Khởi tạo các dependencies
  await di.init();

  runApp(const MyApp());
}

/// Widget chính của ứng dụng
class MyApp extends StatelessWidget {
  /// Constructor
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<VideoDownloadBloc>(
          create: (_) => di.sl<VideoDownloadBloc>(),
        ),
      ],
      child: MaterialApp(
        title: 'MultiVid Downloader',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const HomePage(),
      ),
    );
  }
}
