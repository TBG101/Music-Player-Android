enum DownloadStatus { queued, downloading, converting, completed, failed, cancelled }

class DownloadTask {
  DownloadTask({
    required this.videoId,
    required this.title,
    required this.thumbnailUrl,
    this.status = DownloadStatus.queued,
    this.progress = 0,
    this.downloadedBytes = 0,
    this.totalBytes = 0,
  });

  final String videoId;
  final String title;
  final String thumbnailUrl;
  DownloadStatus status;
  int progress;
  int downloadedBytes;
  int totalBytes;
}
