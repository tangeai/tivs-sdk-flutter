part of 'rapid_kit_sample_widget.dart';

class SecretEntranceIcon extends StatefulWidget {
  final VoidCallback onSecretTap;
  final int requiredTaps;
  final Duration maxInterval;
  final Widget icon;

  const SecretEntranceIcon({
    Key? key,
    required this.onSecretTap,
    required this.icon,
    this.requiredTaps = 5,
    this.maxInterval = const Duration(milliseconds: 500),
  }) : super(key: key);

  @override
  SecretEntranceIconState createState() => SecretEntranceIconState();
}

class SecretEntranceIconState extends State<SecretEntranceIcon> {
  int _tapCount = 0;
  DateTime _lastTapTime = DateTime.now();

  void _handleTap() {
    final currentTime = DateTime.now();
    if (currentTime.difference(_lastTapTime) <= widget.maxInterval) {
      _tapCount++;
    } else {
      _tapCount = 1; // Reset and count current tap
    }

    if (_tapCount >= widget.requiredTaps) {
      widget.onSecretTap();
      _tapCount = 0; // Reset count after successful trigger
    }

    _lastTapTime = currentTime;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Center(
        child: widget.icon,
      ),
    );
  }
}
