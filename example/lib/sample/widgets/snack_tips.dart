part of 'rapid_kit_sample_widget.dart';

class SnackTips {
  SnackTips._();

  static void show(BuildContext context, String message, {Duration duration = const Duration(seconds: 2)}) {
    if (!context.mounted) return;

    final snackBar = SnackBar(
      content: Text(message),
      duration: duration,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
