part of '../rapid_kit_sample_pages.dart';

class LocalReplayPage extends StatefulWidget {
  final String deviceId;
  final String deviceName;
  final int cameraCount;
  final String? deviceAbilities;

  const LocalReplayPage(
      {super.key,
      required this.deviceId,
      required this.deviceName,
      required this.cameraCount,
      this.deviceAbilities});

  @override
  State<LocalReplayPage> createState() => _LocalReplayPageState();
}

class _LocalReplayPageState extends LifecycleAwareState<LocalReplayPage> {
  late final LocalReplayPlaybackController _playbackController;

  @override
  void initState() {
    super.initState();
    _playbackController = LocalReplayPlaybackController();
  }

  @override
  void dispose() {
    _playbackController.dispose();
    super.dispose();
  }

  @override
  void start() {
    _playbackController.start();
  }

  @override
  void stop() {
    _playbackController.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('rapid-local-replay-page-root'),
      appBar: AppBar(
        title: const Text("卡录像",
            style: TextStyle(
                color: SampleThemeConfigure.colorPrimary, fontSize: 16)),
        backgroundColor: SampleThemeConfigure.colorBackground,
        leading: IconButton(
          key: const ValueKey('rapid-local-replay-back-action'),
          icon: const Icon(Icons.arrow_back,
              color: SampleThemeConfigure.colorPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: LocalReplayWidget(
        deviceId: widget.deviceId,
        deviceName: widget.deviceName,
        cameraCount: widget.cameraCount,
        deviceAbilities: widget.deviceAbilities,
        playbackController: _playbackController,
      ),
    );
  }
}
