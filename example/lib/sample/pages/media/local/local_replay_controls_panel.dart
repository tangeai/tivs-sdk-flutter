part of '../../rapid_kit_sample_pages.dart';

class LocalReplayControlsPanel extends StatelessWidget {
  final bool audioMuted;
  final bool paused;
  final bool recording;
  final bool speedFast;
  final VoidCallback onToggleMute;
  final VoidCallback onCapture;
  final VoidCallback onToggleSpeed;
  final VoidCallback onTogglePause;
  final VoidCallback onToggleRecord;

  const LocalReplayControlsPanel({
    super.key,
    required this.audioMuted,
    required this.paused,
    required this.recording,
    required this.speedFast,
    required this.onToggleMute,
    required this.onCapture,
    required this.onToggleSpeed,
    required this.onTogglePause,
    required this.onToggleRecord,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE1E7E8))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          IconButton(
            tooltip: audioMuted ? '开启声音' : '关闭声音',
            icon: Icon(
              audioMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
              size: 25,
              color: SampleThemeConfigure.colorTextPrimary,
            ),
            onPressed: onToggleMute,
          ),
          IconButton(
            tooltip: '截图',
            icon: const Icon(
              Icons.camera_alt_outlined,
              size: 25,
              color: SampleThemeConfigure.colorTextPrimary,
            ),
            onPressed: onCapture,
          ),
          IconButton(
            tooltip: speedFast ? '切换至 1 倍速' : '切换至 4 倍速',
            icon: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(Icons.crop_square_rounded, size: 31),
                Text(
                  speedFast ? '4x' : '1x',
                  style: TextStyle(
                    color: speedFast
                        ? SampleThemeConfigure.colorActive
                        : SampleThemeConfigure.colorTextPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
            color: speedFast
                ? SampleThemeConfigure.colorActive
                : SampleThemeConfigure.colorTextPrimary,
            onPressed: onToggleSpeed,
          ),
          IconButton(
            tooltip: paused ? '继续播放' : '暂停播放',
            icon: Icon(
              paused
                  ? Icons.play_circle_filled_rounded
                  : Icons.pause_circle_filled_outlined,
              size: 29,
              color: SampleThemeConfigure.colorTextPrimary,
            ),
            onPressed: onTogglePause,
          ),
          IconButton(
            tooltip: recording ? '停止录像' : '保存录像',
            icon: Icon(
              Icons.videocam_outlined,
              size: 27,
              color: recording
                  ? SampleThemeConfigure.colorActive
                  : SampleThemeConfigure.colorTextPrimary,
            ),
            onPressed: onToggleRecord,
          ),
        ],
      ),
    );
  }
}
