part of '../rapid_kit_sample_pages.dart';

class WiredResetPage extends StatefulWidget {
  const WiredResetPage({super.key});

  @override
  State<WiredResetPage> createState() => _WiredResetPageState();
}

class _WiredResetPageState extends LifecycleAwareState<WiredResetPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildTitleBar(context),
      body: _buildRootBody(context),
    );
  }

  AppBar _buildTitleBar(BuildContext context) {
    return AppBar(
      title: const Text('准备配网', style: TextStyle(color: SampleThemeConfigure.colorPrimary)),
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
            '如何重置智能摄像头？',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: SampleThemeConfigure.colorTextPrimary),
          ),
        ),

        // 第二部分：灰色的14号文本
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            '设备重置后，通过网线连接到可正常联网的路由器，再进入下一步',
            style: TextStyle(
              fontSize: 16,
              color: SampleThemeConfigure.colorTextSub,
            ),
          ),
        ),

        // 第三部分：灰色区域填满整个空间，正中央是一个图标
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

        // 第四部分：红色的圆角矩形按钮
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
              '准备就绪',
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
