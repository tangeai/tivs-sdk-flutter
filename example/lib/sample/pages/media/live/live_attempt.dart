// ignore_for_file: deprecated_member_use

part of '../../rapid_kit_sample_pages.dart';

class EstablishFailedWidget extends StatelessWidget {
  final VoidCallback onRetry;
  final String? connectionState;

  const EstablishFailedWidget({
    Key? key,
    required this.onRetry,
    this.connectionState,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                connectionState != null ? '连接失败\n$connectionState' : '连接失败',
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: onRetry,
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Colors.transparent),
                  side: MaterialStateProperty.all(const BorderSide(color: Colors.white)),
                  shape: MaterialStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  elevation: MaterialStateProperty.all(0),
                ),
                child: const Text(
                  '重试',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
