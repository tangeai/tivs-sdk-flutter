part of '../rapid_kit_sample_pages.dart';

class InstructOverlay {
  static void show(BuildContext context, String deviceId, String deviceName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return _InstructOverlayContent(
          deviceId: deviceId,
          deviceName: deviceName,
        );
      },
    );
  }
}

class _InstructOverlayContent extends StatefulWidget {
  final String deviceId;
  final String deviceName;

  const _InstructOverlayContent({
    required this.deviceId,
    required this.deviceName,
  });

  @override
  State<_InstructOverlayContent> createState() => _InstructOverlayContentState();
}

class _InstructOverlayContentState extends State<_InstructOverlayContent> {
  final GlobalKey<_InstructStandardWidgetState> _instructWidgetKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height / 2,
      decoration: const BoxDecoration(
        color: SampleThemeConfigure.colorBackground,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                const SizedBox(width: 16),
                const Icon(
                  Icons.settings_rounded,
                  color: SampleThemeConfigure.colorPrimary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  "基于指令控制设备",
                  style: const TextStyle(
                    color: SampleThemeConfigure.colorTextPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: SampleThemeConfigure.colorTextHint,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: SampleThemeConfigure.colorTextHint),
          Expanded(
            child: InstructStandardWidget(
              key: _instructWidgetKey,
              deviceId: widget.deviceId,
              deviceName: widget.deviceName,
            ),
          ),
        ],
      ),
    );
  }
}
