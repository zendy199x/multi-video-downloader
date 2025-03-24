# MultiVid Downloader

Ứng dụng Flutter để tải video đa nền tảng như YouTube, TikTok, Instagram, Facebook và Twitter.

## Tính năng

- 📱 Tải video từ nhiều nền tảng phổ biến:
  - YouTube (bao gồm cả YouTube Shorts)
  - TikTok
  - Instagram
  - Facebook
  - Twitter (X)
- 🎮 Giao diện người dùng hiện đại, thân thiện và dễ sử dụng
- 🔍 Tự động phát hiện URL video từ clipboard
- ⚙️ Hỗ trợ nhiều chất lượng video khác nhau
- 📂 Lưu video vào thư viện ảnh/video
- 📚 Xem lịch sử tải xuống
- 🌓 Hỗ trợ chế độ tối/sáng

## Cài đặt

1. Clone dự án:
```bash
git clone https://github.com/your-username/multi_video_downloader.git
cd multi_video_downloader
```

2. Cài đặt các dependencies:
```bash
flutter pub get
```

3. Chạy ứng dụng:
```bash
flutter run
```

## Kiến trúc ứng dụng

Ứng dụng được phát triển dựa trên kiến trúc Clean Architecture và sử dụng các công nghệ sau:

- **Flutter BLoC** - Quản lý trạng thái
- **Dio** - Thực hiện các yêu cầu HTTP
- **youtube_explode_dart** - Xử lý API YouTube
- **get_it** - Dependency injection
- **Path Provider** - Quản lý đường dẫn hệ thống

## Sử dụng

1. Mở ứng dụng
2. Dán URL video từ YouTube, TikTok, Instagram, Facebook, hoặc Twitter
3. Ứng dụng sẽ tự động phân tích và tải về thông tin video
4. Chọn chất lượng video mong muốn
5. Nhấn nút tải xuống để bắt đầu tải video
6. Video đã tải sẽ được lưu vào thư viện của bạn

## Yêu cầu

- Flutter 3.0.0 trở lên
- Dart 2.17.0 trở lên
- Android 5.0 (API 21) trở lên hoặc iOS 11 trở lên

## Đóng góp

Đóng góp luôn được chào đón! Nếu bạn muốn đóng góp, vui lòng:

1. Fork dự án
2. Tạo branch cho tính năng của bạn (`git checkout -b feature/amazing-feature`)
3. Commit các thay đổi của bạn (`git commit -m 'Add some amazing feature'`)
4. Push lên branch (`git push origin feature/amazing-feature`)
5. Mở Pull Request

## Giấy phép

Dự án này được cấp phép theo Giấy phép MIT - xem tệp [LICENSE](LICENSE) để biết chi tiết. 