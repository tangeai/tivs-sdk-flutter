part of '../../rapid_kit_sample_pages.dart';

class LocalReplayTimelineOverlay extends StatelessWidget {
  final double width;
  final Widget child;

  const LocalReplayTimelineOverlay({
    super.key,
    required this.width,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      top: LocalReplayUiConstants.timelineTop,
      bottom: LocalReplayUiConstants.timelineBottom,
      child: SizedBox(
        width: width,
        child: child,
      ),
    );
  }
}
