part of 'rapid_kit_sample_widget.dart';

Widget createCenterLoading({double size = 50.0, Color color = SampleThemeConfigure.colorPrimary}) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        SpinKitThreeBounce(
          color: color,
          size: size,
        ),
      ],
    ),
  );
}

Positioned createBufferingWidget() {
  return Positioned.fill(
    child: Container(
      color: Colors.black54,
      child: Center(
        child: createCenterLoading(size: 20, color: Colors.white),
      ),
    ),
  );
}

class WiFiDetails {
  final String ssid;
  final String password;

  WiFiDetails(this.ssid, this.password);

  @override
  String toString() {
    return 'SSID: $ssid, Password: $password';
  }
}

Future<WiFiDetails> chooseWifi(BuildContext context) async {
  TextEditingController ssidController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  return showDialog<WiFiDetails>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Enter WiFi Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: ssidController,
              decoration: const InputDecoration(
                labelText: 'WiFi Name (SSID)',
              ),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              final result = WiFiDetails("", "");
              Navigator.of(context).pop(result);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final result = WiFiDetails(ssidController.text, passwordController.text);
              Navigator.of(context).pop(result);
            },
            child: const Text('Next'),
          ),
        ],
      );
    },
  ).then((value) => value ?? WiFiDetails("", "")); // 确保返回非 null 值
}
