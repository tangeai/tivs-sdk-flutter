part of 'rapid_kit_sample_util.dart';

class AutoActionScheduler {
  final VoidCallback onAction;
  final int minDelayMs;
  final int maxDelayMs;
  final math.Random _random = math.Random();

  Timer? _timer;

  AutoActionScheduler({
    required this.onAction,
    this.minDelayMs = 100,
    this.maxDelayMs = 20000,
  });

  void start() {
    if (_timer?.isActive == true) return;

    _scheduleNext();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void _scheduleNext() {
    _timer?.cancel();

    final delay = Duration(milliseconds: minDelayMs + _random.nextInt(maxDelayMs - minDelayMs + 1));

    _timer = Timer(delay, () {
      onAction();
      _scheduleNext();
    });
  }
}
