part of '../../rapid_kit_sample_pages.dart';

Scaffold _scaffold(String title, BuildContext context, Widget root,
    String deviceId, String deviceName,
    {bool showSettingsGear = true}) {
  return Scaffold(
    appBar: AppBar(
      title: Text(title,
          style: const TextStyle(
              color: SampleThemeConfigure.colorPrimary, fontSize: 14)),
      backgroundColor: SampleThemeConfigure.colorBackground,
      leading: IconButton(
        key: const ValueKey('rapid-live-back-action'),
        icon: const Icon(Icons.arrow_back,
            color: SampleThemeConfigure.colorPrimary),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
      actions: showSettingsGear
          ? <Widget>[
              Container(
                margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: SampleThemeConfigure.colorPrimary,
                    backgroundColor: Colors.transparent,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    minimumSize: const Size(50, 28),
                    side: const BorderSide(
                        color: SampleThemeConfigure.colorPrimary, width: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => InstructStandardPage(
                            deviceId: deviceId, deviceName: deviceName),
                      ),
                    );
                  },
                  child: const Text('指令',
                      style: TextStyle(fontSize: 12),
                      textAlign: TextAlign.center),
                ),
              )
            ]
          : null,
    ),
    body: root,
  );
}
