part of 'rapid_kit_sample_widget.dart';

class SnackDialog extends StatelessWidget {
  final String title;
  final String content;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const SnackDialog({
    super.key,
    required this.title,
    required this.content,
    this.onConfirm,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            if (onCancel != null) {
              onCancel!();
            }
          },
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            if (onConfirm != null) {
              onConfirm!();
            }
          },
          child: const Text('确定'),
        ),
      ],
    );
  }
}

extension SnackDialogExtension on BuildContext {
  void showSnackDialog({
    required String title,
    required String content,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    showDialog(
      context: this,
      builder: (BuildContext context) {
        return SnackDialog(
          title: title,
          content: content,
          onConfirm: onConfirm,
          onCancel: onCancel,
        );
      },
    );
  }
}
