part of '../../rapid_kit_sample_pages.dart';

class LocalReplayTimelinePanel extends StatelessWidget {
  final DateTime selectedDate;
  final int total;
  final bool loading;
  final bool downloading;
  final int? downloadingRecordTimestamp;
  final double downloadProgress;
  final List<RecordIndex> records;
  final String? timestampLabel;
  final VoidCallback onRetryLoad;
  final void Function(RecordIndex record) onSeek;
  final void Function(RecordIndex record) onDownload;

  const LocalReplayTimelinePanel({
    super.key,
    required this.selectedDate,
    required this.total,
    required this.loading,
    required this.downloading,
    required this.downloadingRecordTimestamp,
    required this.downloadProgress,
    required this.records,
    this.timestampLabel,
    required this.onRetryLoad,
    required this.onSeek,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _header(),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(8)),
            ),
            child: _body(context),
          ),
        ),
      ],
    );
  }

  Widget _header() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              "${selectedDate.year.toString().padLeft(4, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}",
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (timestampLabel != null) ...[
              const SizedBox(height: 6),
              Text(
                timestampLabel!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              "共 $total 个录像",
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (loading) {
      return createCenterLoading(size: 16.0, color: Colors.white);
    }

    if (records.isEmpty) {
      return _empty();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 2),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        final isActiveDownload = downloading &&
            record.startTimestampSecond == downloadingRecordTimestamp;
        return LocalReplayTimelineItem(
          record: record,
          downloading: downloading,
          downloadProgress: isActiveDownload ? downloadProgress : null,
          onSeek: () => onSeek(record),
          onDownload: () => onDownload(record),
        );
      },
    );
  }

  Widget _empty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inbox_outlined,
            color: Colors.white.withOpacity(0.5),
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            "暂无录像",
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class LocalReplayTimelineItem extends StatelessWidget {
  final RecordIndex record;
  final bool downloading;
  final double? downloadProgress;
  final VoidCallback onSeek;
  final VoidCallback onDownload;

  const LocalReplayTimelineItem({
    super.key,
    required this.record,
    required this.downloading,
    required this.downloadProgress,
    required this.onSeek,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey(
          'rapid-local-replay-seek-${record.startTimestampSecond}',
        ),
        onTap: downloading ? null : onSeek,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: SampleThemeConfigure.colorSoftWhite,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      record.startTimestampSecond.toHHmmss(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "${record.durationSecond}秒 ${LocalReplayUiHelpers.eventLabel(record.eventType)}",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Tooltip(
                message: downloadProgress == null
                    ? "Download"
                    : "Downloading ${(_normalizedProgress * 100).round()}%",
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: OutlinedButton(
                    key: ValueKey(
                      'local-replay-download-${record.startTimestampSecond}',
                    ),
                    onPressed: downloading ? null : onDownload,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white.withOpacity(0.9),
                      side: BorderSide(color: Colors.white.withOpacity(0.45)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: downloadProgress == null
                        ? const Icon(Icons.download_rounded, size: 16)
                        : _buildDownloadProgress(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double get _normalizedProgress => downloadProgress!.clamp(0.0, 1.0);

  Widget _buildDownloadProgress() {
    final progress = _normalizedProgress;
    final percent = (progress * 100).round();
    return Semantics(
      label: "Downloading",
      value: "$percent%",
      child: SizedBox.square(
        key: ValueKey(
          'local-replay-download-progress-${record.startTimestampSecond}',
        ),
        dimension: 22,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: progress,
              strokeWidth: 2,
              color: Colors.white,
              backgroundColor: Colors.white24,
            ),
            Text(
              "$percent",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
