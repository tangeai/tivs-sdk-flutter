part of '../rapid_kit_sample_pages.dart';

class InstructStandardPage extends StatefulWidget {
  final String deviceId;
  final String deviceName;

  const InstructStandardPage({super.key, required this.deviceId, required this.deviceName});

  @override
  State<InstructStandardPage> createState() => _InstructStandardPageState();
}

class _InstructStandardPageState extends State<InstructStandardPage> {
  final GlobalKey<_InstructStandardWidgetState> _instructWidgetKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final instructWidget = InstructStandardWidget(
      key: _instructWidgetKey,
      deviceId: widget.deviceId,
      deviceName: widget.deviceName,
    );

    return _scaffold(widget.deviceName.isEmpty ? widget.deviceId : widget.deviceName, context,
        instructWidget, widget.deviceId, widget.deviceName,
        showSettingsGear: false);
  }
}
