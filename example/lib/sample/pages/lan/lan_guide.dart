part of '../rapid_kit_sample_pages.dart';

class LanResetPage extends StatefulWidget {
  const LanResetPage({super.key});

  @override
  State<LanResetPage> createState() => _LanResetPageState();
}

class _LanResetPageState extends LifecycleAwareState<LanResetPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildTitleBar(context),
      body: _buildRootBody(context),
    );
  }

  AppBar _buildTitleBar(BuildContext context) {
    return AppBar(
      title: const Text('设备配置', style: TextStyle(color: SampleThemeConfigure.colorPrimary)),
      backgroundColor: SampleThemeConfigure.colorBackground,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: SampleThemeConfigure.colorPrimary),
        onPressed: () {
          Navigator.pop(context, false);
        },
      ),
      elevation: 0,
    );
  }

  Widget _buildRootBody(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            '如何操作',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: SampleThemeConfigure.colorTextPrimary),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            '设备重置之后，将手机连接设备热点',
            style: TextStyle(
              fontSize: 16,
              color: SampleThemeConfigure.colorTextSub,
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              color: const Color.fromRGBO(97, 94, 94, 0.138),
              child: const Center(
                child: Icon(
                  Icons.settings_backup_restore_rounded,
                  size: 100,
                  color: SampleThemeConfigure.colorTextPrimary,
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: SampleThemeConfigure.colorPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50.0),
              ),
              padding: const EdgeInsets.symmetric(vertical: 20.0),
            ),
            onPressed: () {
              Navigator.pop(context, true);
            },
            child: const Text(
              '确认连上了设备热点',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
