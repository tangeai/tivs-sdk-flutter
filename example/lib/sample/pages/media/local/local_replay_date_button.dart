part of '../../rapid_kit_sample_pages.dart';

class LocalReplayDateButton extends StatelessWidget {
  final VoidCallback onTap;

  const LocalReplayDateButton({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 16,
      top: 0,
      bottom: 0,
      child: Center(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: SampleThemeConfigure.colorPrimary,
              size: 30,
            ),
          ),
        ),
      ),
    );
  }
}
