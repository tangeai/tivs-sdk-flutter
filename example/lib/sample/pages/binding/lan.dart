part of '../rapid_kit_sample_pages.dart';

class LanBindingPage extends StatefulWidget {
  const LanBindingPage({super.key});

  @override
  State<LanBindingPage> createState() => _LanBindingPageState();
}

class _LanBindingPageState extends LifecycleAwareState<LanBindingPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildTitleBar(context),
      body: _buildRootBody(context),
    );
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigateToReset();
    });
  }

  Future<void> _navigateToDiscovery() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LanDiscoveryPage()),
    );

    if (!mounted) return;

    if (result.isNotEmpty) {
      final response = await BindingService.bind(result as String, deviceName: "有线添加的摄像头");
      if (!mounted) return;
      String tips;
      if (!response.success) {
        tips = "绑定失败: ${response.message}";
      } else {
        tips = "绑定成功！";
      }
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("提示"),
            content: Text(tips),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: const Text("确定"),
              ),
            ],
          );
        },
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _navigateToReset() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WiredResetPage()),
    );

    if (!mounted) return;

    if (result == true) {
      _navigateToDiscovery();
    } else {
      Navigator.of(context).pop();
    }
  }

  AppBar _buildTitleBar(BuildContext context) {
    return AppBar(
      title: const Text('网络配置', style: TextStyle(color: SampleThemeConfigure.colorPrimary)),
      backgroundColor: SampleThemeConfigure.colorBackground,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: SampleThemeConfigure.colorPrimary),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
      elevation: 0,
    );
  }

  Widget _buildRootBody(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _finish(context),
      ],
    );
  }

  Padding _finish(BuildContext context) {
    return Padding(
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
          Navigator.pop(context);
        },
        child: const Text(
          '完成',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
