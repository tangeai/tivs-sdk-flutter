part of 'rapid_kit_sample_widget.dart';

class ProgressDialog {
  static OverlayEntry? _overlayEntry;
  static final ValueNotifier<double> _progressNotifier = ValueNotifier<double>(0.0);
  static final ValueNotifier<String> _messageNotifier = ValueNotifier<String>('');

  ProgressDialog._();

  static void show(BuildContext context, {String initialMessage = '处理中...'}) {
    if (_overlayEntry != null) return;

    _progressNotifier.value = 0.0;
    _messageNotifier.value = initialMessage;

    _overlayEntry = OverlayEntry(
      builder: (context) => Material(
        color: Colors.black54,
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ValueListenableBuilder<double>(
                  valueListenable: _progressNotifier,
                  builder: (context, progress, child) {
                    return Column(
                      children: [
                        SizedBox(
                          width: 120,
                          height: 120,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: progress / 100,
                                strokeWidth: 4,
                                backgroundColor: Colors.grey[300],
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  SampleThemeConfigure.colorPrimary,
                                ),
                              ),
                              Text(
                                '${progress.toInt()}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: SampleThemeConfigure.colorTextPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ValueListenableBuilder<String>(
                          valueListenable: _messageNotifier,
                          builder: (context, message, child) {
                            return Text(
                              message,
                              style: const TextStyle(
                                fontSize: 16,
                                color: SampleThemeConfigure.colorTextPrimary,
                              ),
                              textAlign: TextAlign.center,
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  static void updateProgress(double progress, {String? message}) {
    _progressNotifier.value = progress.clamp(0.0, 100.0);
    if (message != null) {
      _messageNotifier.value = message;
    }
  }

  static void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}
