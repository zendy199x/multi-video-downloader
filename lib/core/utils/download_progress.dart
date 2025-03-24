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

/// Lớp để tính toán và theo dõi tốc độ tải xuống
class DownloadSpeed {
  /// Thời gian của lần cập nhật cuối cùng
  DateTime _lastUpdateTime = DateTime.now();

  /// Thời gian của lần hiển thị tốc độ cuối cùng
  DateTime _lastDisplayTime = DateTime.now();

  /// Số byte đã tải ở lần cập nhật cuối
  int _lastReceivedBytes = 0;

  /// Tốc độ tải xuống hiện tại (bytes/giây)
  double _currentSpeed = 0.0;

  /// Tốc độ tải xuống được hiển thị (chỉ cập nhật định kỳ)
  double _displaySpeed = 0.0;

  /// Danh sách lưu trữ các giá trị tốc độ gần đây để làm mượt
  final List<double> _recentSpeeds = [];

  /// Số mẫu tối đa để làm mượt tốc độ
  static const int _maxSmoothingSamples = 3;

  /// Khoảng thời gian tối thiểu giữa các lần hiển thị (miligiây)
  /// 500ms = 2 lần cập nhật mỗi giây - cân bằng tốt nhất theo nghiên cứu
  static const int _displayInterval = 500;

  /// Cập nhật và tính toán tốc độ tải xuống
  void update(int receivedBytes) {
    final now = DateTime.now();
    final duration = now.difference(_lastUpdateTime).inMilliseconds;

    if (duration > 0) {
      final bytesChange = receivedBytes - _lastReceivedBytes;
      // Chuyển đổi sang bytes/giây
      _currentSpeed = (bytesChange * 1000) / duration;

      // Thêm tốc độ hiện tại vào danh sách để làm mượt
      _recentSpeeds.add(_currentSpeed);

      // Giới hạn số mẫu để làm mượt
      if (_recentSpeeds.length > _maxSmoothingSamples) {
        _recentSpeeds.removeAt(0);
      }

      _lastUpdateTime = now;
      _lastReceivedBytes = receivedBytes;

      // Chỉ cập nhật tốc độ hiển thị mỗi _displayInterval ms
      final timeSinceLastDisplay =
          now.difference(_lastDisplayTime).inMilliseconds;
      if (timeSinceLastDisplay >= _displayInterval) {
        // Tính trung bình các mẫu gần đây để làm mượt tốc độ hiển thị
        _displaySpeed = _recentSpeeds.isEmpty
            ? 0.0
            : _recentSpeeds.reduce((a, b) => a + b) / _recentSpeeds.length;

        _lastDisplayTime = now;
      }
    }
  }

  /// Lấy tốc độ tải xuống hiện tại (bytes/giây)
  double get speed => _currentSpeed;

  /// Lấy tốc độ tải xuống hiện tại dưới dạng chuỗi đã định dạng (VD: 1.2 MB/s)
  String get speedString {
    // Sử dụng _displaySpeed đã được làm mượt để hiển thị
    if (_displaySpeed < 1024) {
      return '${_displaySpeed.toStringAsFixed(1)} B/s';
    } else if (_displaySpeed < 1024 * 1024) {
      return '${(_displaySpeed / 1024).toStringAsFixed(1)} KB/s';
    } else if (_displaySpeed < 1024 * 1024 * 1024) {
      return '${(_displaySpeed / (1024 * 1024)).toStringAsFixed(1)} MB/s';
    } else {
      return '${(_displaySpeed / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB/s';
    }
  }

  /// Reset trạng thái để bắt đầu tính toán mới
  void reset() {
    _lastUpdateTime = DateTime.now();
    _lastDisplayTime = DateTime.now();
    _lastReceivedBytes = 0;
    _currentSpeed = 0.0;
    _displaySpeed = 0.0;
    _recentSpeeds.clear();
  }
}
