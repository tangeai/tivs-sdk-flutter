part of '../../rapid_kit_sample_pages.dart';

class LocalReplayBufferingOverlay extends StatelessWidget {
  final double width;
  final double height;

  const LocalReplayBufferingOverlay({
    super.key,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: Colors.black54,
      child: Center(
        child: createCenterLoading(size: 20, color: Colors.white),
      ),
    );
  }
}

class LocalReplayPausedOverlay extends StatelessWidget {
  final double width;
  final double height;
  final String message;

  const LocalReplayPausedOverlay({
    super.key,
    required this.width,
    required this.height,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: Colors.black54,
      child: Center(
        child: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class LocalReplayConnectionErrorOverlay extends StatelessWidget {
  final double width;
  final double height;
  final String message;
  final VoidCallback onRetry;

  const LocalReplayConnectionErrorOverlay({
    super.key,
    required this.width,
    required this.height,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: Colors.black87,
      child: Center(
        child: GestureDetector(
          onTap: onRetry,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.white,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
