part of '../rapid_kit_sample_pages.dart';

class AssistantPage extends StatefulWidget {
  const AssistantPage({super.key});

  @override
  State<AssistantPage> createState() => _State();
}

class _State extends LifecycleAwareState<AssistantPage> {
  String _loggingId = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('上传日志', style: TextStyle(color: SampleThemeConfigure.colorPrimary)),
        backgroundColor: SampleThemeConfigure.colorBackground,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: SampleThemeConfigure.colorPrimary),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: _buildVideoPlayerBody(),
    );
  }

  Widget _buildVideoPlayerBody() {
    return Center(
      child: Text(
        _loggingId,
        style: const TextStyle(
          fontSize: 14.0,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _upload();
    });
  }

  void _upload() async {
    _showLoadingDialog();
    final resp = await Assistant.uploadLogs();
    _hideLoadingDialog();
    if (resp.success) {
      setState(() {
        _loggingId = "日志编号: ${resp.data}";
      });
    } else {
      setState(() {
        _loggingId = '上传失败';
      });
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                createCenterLoading(size: 20, color: Colors.white),
              ],
            ),
          ),
        );
      },
    );
  }

  void _hideLoadingDialog() {
    Navigator.of(context).pop();
  }
}
