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
    return Positioned(
      left: 16,
      right: 16,
      bottom: 32,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            IconButton(
              icon: Icon(
                audioMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                size: 25,
                color: SampleThemeConfigure.colorTextPrimary,
              ),
              onPressed: onToggleMute,
            ),
            IconButton(
              icon: const Icon(
                Icons.camera_alt,
                size: 25,
                color: SampleThemeConfigure.colorTextPrimary,
              ),
              onPressed: onCapture,
            ),
            IconButton(
              icon: Icon(
                Icons.speed_rounded,
                size: 25,
                color: speedFast
                    ? SampleThemeConfigure.colorActive
                    : SampleThemeConfigure.colorTextPrimary,
              ),
              onPressed: onToggleSpeed,
            ),
            IconButton(
              icon: Icon(
                paused
                    ? Icons.play_circle_filled_rounded
                    : Icons.pause_circle_filled_outlined,
                size: 25,
                color: SampleThemeConfigure.colorTextPrimary,
              ),
              onPressed: onTogglePause,
            ),
            IconButton(
              icon: Icon(
                Icons.emergency_recording_rounded,
                size: 25,
                color: recording
                    ? SampleThemeConfigure.colorActive
                    : SampleThemeConfigure.colorTextPrimary,
              ),
              onPressed: onToggleRecord,
            ),
          ],
        ),
      ),
    );
  }
}
