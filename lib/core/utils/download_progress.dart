/// Trạng thái tiến trình tải xuống video
enum VideoDownloadProgress {
  /// Trạng thái ban đầu
  initial,

  /// Đang tải thông tin video
  loadingInfo,

  /// Thông tin video đã được tải
  infoLoaded,

  /// Đang tải xuống video
  downloading,

  /// Tải xuống hoàn tất
  completed,

  /// Tải xuống bị hủy
  cancelled,

  /// Lỗi xảy ra
  error,
}
