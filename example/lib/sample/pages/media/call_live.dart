part of '../rapid_kit_sample_pages.dart';

class CallLivePage extends StatefulWidget {
  final IncomingCall? initialIncomingCall;
  final OutgoingCallOptions? outgoingOptions;
  final String deviceId;
  final String deviceName;
  final int cameraCount;
  final bool lan;
  final String? deviceAbilities;

  const CallLivePage({
    super.key,
    this.initialIncomingCall,
    this.outgoingOptions,
    required this.deviceId,
    required this.deviceName,
    required this.cameraCount,
    required this.lan,
    this.deviceAbilities,
  }) : assert(
          (initialIncomingCall == null) != (outgoingOptions == null),
          'CallLivePage requires either initialIncomingCall or outgoingOptions',
        );

  @override
  State<CallLivePage> createState() => _CallLivePageState();
}

class _CallLivePageState extends LifecycleAwareState<CallLivePage> {
  bool _isFullScreen = false;
  bool _active = false;
  bool _submitting = false;
  bool _startCancelled = false;
  bool _resolvingConnectedCall = false;
  IncomingCall? _incomingCall;
  OutgoingCall? _outgoingCall;
  ConnectedCall? _connectedCall;
  final GlobalKey<_LiveStreamWidgetState> _liveStreamKey = GlobalKey();

  bool get _callReady => _connectedCall?.state == ConnectedCallState.active;
  bool get _showLiveStream => _connectedCall != null;

  bool get _isTerminal {
    if (_connectedCall != null) {
      return _connectedCall!.isTerminal;
    }
    if (_incomingCall != null) {
      return _incomingCall!.isTerminal;
    }
    if (_outgoingCall != null) {
      return _outgoingCall!.isTerminal;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    final incomingCall = widget.initialIncomingCall;
    if (incomingCall != null) {
      _playIncomingPrompt();
      _bindIncomingCall(incomingCall);
      return;
    }
    unawaited(_startOutgoingCall());
  }

  @override
  void dispose() {
    _connectedCall?.bindLiveStream(null);
    _connectedCall?.removeListener(_handleConnectedCallEvent);
    _incomingCall?.removeListener(_handleIncomingEvent);
    _outgoingCall?.removeListener(_handleOutgoingEvent);
    super.dispose();
  }

  void _bindIncomingCall(IncomingCall call) {
    if (identical(_incomingCall, call)) {
      return;
    }
    _incomingCall?.removeListener(_handleIncomingEvent);
    _incomingCall = call;
    call.addListener(_handleIncomingEvent);
    if (call.state == IncomingCallState.connected) {
      unawaited(_resolveConnectedCall(call.connectedCall));
    }
  }

  void _bindOutgoingCall(OutgoingCall call) {
    if (identical(_outgoingCall, call)) {
      return;
    }
    _outgoingCall?.removeListener(_handleOutgoingEvent);
    _outgoingCall = call;
    call.addListener(_handleOutgoingEvent);
    if (call.state == OutgoingCallState.connected) {
      unawaited(_resolveConnectedCall(call.connectedCall));
    }
  }

  void _bindConnectedCall(ConnectedCall call) {
    if (identical(_connectedCall, call)) {
      return;
    }
    _connectedCall?.bindLiveStream(null);
    _connectedCall?.removeListener(_handleConnectedCallEvent);
    _connectedCall = call;
    _connectedCall!.addListener(_handleConnectedCallEvent);
    _scheduleLiveStreamBinding();
    _syncLiveActivation();
  }

  Future<void> _startOutgoingCall() async {
    final options = widget.outgoingOptions;
    if (options == null) {
      return;
    }

    try {
      final call = await OutgoingCall.start(
        widget.deviceId,
        options: options,
      );
      if (_startCancelled) {
        await call.cancel();
        return;
      }
      if (!mounted) {
        return;
      }
      _bindOutgoingCall(call);
      setState(() {});
    } catch (error) {
      if (!mounted) {
        return;
      }
      final spec = _callActionDialogSpec(
        title: '呼叫启动失败',
        message: '呼叫启动失败：${error.toString()}',
      );
      await _showCallResultDialog(
        spec.title,
        spec.message,
        icon: spec.icon,
        accentColor: spec.accentColor,
        badgeColor: spec.badgeColor,
      );
      if (!mounted) {
        return;
      }
      Navigator.pop(context);
    }
  }

  Future<void> _resolveConnectedCall(Future<ConnectedCall> future) async {
    if (_connectedCall != null || _resolvingConnectedCall) {
      return;
    }

    _resolvingConnectedCall = true;
    try {
      final connectedCall = await future;
      if (!mounted) {
        return;
      }
      _bindConnectedCall(connectedCall);
      setState(() {});
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    } finally {
      _resolvingConnectedCall = false;
    }
  }

  void _setActive(bool active) {
    if (_active == active) {
      return;
    }
    setState(() => _active = active);
  }

  void _syncLiveActivation() {
    _setActive(_callReady);
  }

  Future<void> _deactivateLiveStreamIfNeeded() async {
    if (!_showLiveStream || !_active) {
      return;
    }
    _setActive(false);
    await WidgetsBinding.instance.endOfFrame;
  }

  void _scheduleLiveStreamBinding() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final connectedCall = _connectedCall;
      final liveStream = _liveStreamKey.currentState?.primaryStream;
      if (connectedCall == null || liveStream == null || connectedCall.isTerminal) {
        return;
      }
      connectedCall.bindLiveStream(liveStream);
    });
  }

  void _onFullScreenChanged(bool isFullScreen) {
    setState(() => _isFullScreen = isFullScreen);
  }

  void _playIncomingPrompt() {
    if (!Platform.isAndroid) {
      return;
    }
    unawaited(SystemSound.play(SystemSoundType.alert));
  }

  @override
  void start() {
    _syncLiveActivation();
  }

  @override
  void stop() {
    _setActive(false);
  }

  @override
  Widget build(BuildContext context) {
    final pageBody = _showLiveStream
        ? LiveStreamWidget(
            key: _liveStreamKey,
            deviceId: widget.deviceId,
            deviceName: widget.deviceName,
            cameraCount: widget.cameraCount,
            lan: widget.lan,
            deviceAbilities: widget.deviceAbilities,
            active: _active,
            onFullScreenChanged: _onFullScreenChanged,
          )
        : _buildPendingBody();

    if (_isFullScreen && _showLiveStream) {
      return Scaffold(body: pageBody);
    }

    return WillPopScope(
      onWillPop: () async {
        await _handleBackPressed();
        return false;
      },
      child: Scaffold(
        backgroundColor: SampleThemeConfigure.colorBackground,
        appBar: _buildAppBar(),
        body: pageBody,
      ),
    );
  }

  Widget _buildPendingBody() {
    return ColoredBox(
      color: SampleThemeConfigure.colorBackground,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 80, 24, 32),
          child: Column(
            children: [
              const Spacer(),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  decoration: BoxDecoration(
                    color: SampleThemeConfigure.colorForeground,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: const Color(0xFFE4DED0)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF1EE),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const Icon(
                          Icons.call_rounded,
                          size: 36,
                          color: SampleThemeConfigure.colorPrimary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        widget.deviceName.isEmpty ? widget.deviceId : widget.deviceName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: SampleThemeConfigure.colorTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.deviceId,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: SampleThemeConfigure.colorTextSub,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F2E7),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          _statusText(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: SampleThemeConfigure.colorTextPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: _buildPendingActions(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingActions() {
    if (_incomingCall != null && !_incomingCall!.isTerminal) {
      return Row(
        children: [
          Expanded(
            child: FilledButton(
              onPressed: _submitting
                  ? null
                  : () {
                      unawaited(_acceptIncomingCall());
                    },
              style: FilledButton.styleFrom(
                backgroundColor: SampleThemeConfigure.colorPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: const Text('接听'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              onPressed: _submitting
                  ? null
                  : () {
                      unawaited(_endCall());
                    },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade400,
                backgroundColor: const Color(0xFFFFF6F4),
                padding: const EdgeInsets.symmetric(vertical: 15),
                side: const BorderSide(color: Color(0xFFF2CCC5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: const Text('拒接'),
            ),
          ),
        ],
      );
    }

    return OutlinedButton(
      onPressed: (_submitting || _isTerminal)
          ? null
          : () {
              unawaited(_handleBackPressed());
            },
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.red.shade400,
        backgroundColor: const Color(0xFFFFF6F4),
        padding: const EdgeInsets.symmetric(vertical: 15),
        side: const BorderSide(color: Color(0xFFF2CCC5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      child: Text(_pendingActionLabel()),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        widget.deviceName.isEmpty ? widget.deviceId : widget.deviceName,
        style: const TextStyle(
          color: SampleThemeConfigure.colorPrimary,
          fontSize: 14,
        ),
      ),
      backgroundColor: SampleThemeConfigure.colorBackground,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back,
          color: SampleThemeConfigure.colorPrimary,
        ),
        onPressed: () {
          unawaited(_handleBackPressed());
        },
      ),
      actions: _callReady
          ? [
              IconButton(
                icon: const Icon(
                  Icons.call_end_rounded,
                  color: Colors.redAccent,
                ),
                onPressed: _submitting
                    ? null
                    : () {
                        unawaited(_endCall());
                      },
              ),
            ]
          : null,
    );
  }

  String _pendingActionLabel() {
    if (_connectedCall != null) {
      return '挂断';
    }
    return _incomingCall != null ? '拒接' : '取消呼叫';
  }

  String _statusText() {
    if (_connectedCall != null) {
      switch (_connectedCall!.state) {
        case ConnectedCallState.active:
          return '呼叫已接通，可以开始音视频';
        case ConnectedCallState.ended:
        case ConnectedCallState.failed:
          return _callEndReasonText(_connectedCall!.endReason);
      }
    }

    if (_incomingCall != null) {
      switch (_incomingCall!.state) {
        case IncomingCallState.ringing:
          return '设备正在呼叫';
        case IncomingCallState.connected:
          return '正在进入通话';
        case IncomingCallState.ended:
        case IncomingCallState.failed:
          return _callEndReasonText(_incomingCall!.endReason);
      }
    }

    if (_outgoingCall != null) {
      switch (_outgoingCall!.state) {
        case OutgoingCallState.dialing:
          return '正在启动呼叫';
        case OutgoingCallState.ringing:
          return '设备已收到呼叫请求，等待设备侧处理';
        case OutgoingCallState.connected:
          return '正在进入通话';
        case OutgoingCallState.ended:
        case OutgoingCallState.failed:
          return _callEndReasonText(_outgoingCall!.endReason);
      }
    }

    return '正在准备呼叫';
  }

  Future<void> _showCallResultDialog(
    String title,
    String message, {
    IconData icon = Icons.info_outline_rounded,
    Color accentColor = SampleThemeConfigure.colorPrimary,
    Color badgeColor = const Color(0xFFEAF1EE),
  }) async {
    if (!mounted) {
      return;
    }
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: SampleThemeConfigure.colorForeground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: accentColor, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: SampleThemeConfigure.colorTextPrimary,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(
              fontSize: 15,
              height: 1.6,
              color: SampleThemeConfigure.colorTextPrimary,
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              style: FilledButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showTerminalResultAndPop(CallEndReason? reason) async {
    await _deactivateLiveStreamIfNeeded();
    if (!mounted) {
      return;
    }
    final spec = _callResultDialogSpec(reason);
    await _showCallResultDialog(
      spec.title,
      spec.message,
      icon: spec.icon,
      accentColor: spec.accentColor,
      badgeColor: spec.badgeColor,
    );
    if (!mounted) {
      return;
    }
    Navigator.pop(context);
  }

  Future<void> _handleBackPressed() async {
    if (_incomingCall == null && _outgoingCall == null && _connectedCall == null) {
      _startCancelled = true;
      if (!mounted) {
        return;
      }
      Navigator.pop(context);
      return;
    }

    if (_isTerminal) {
      if (!mounted) {
        return;
      }
      Navigator.pop(context);
      return;
    }

    await _endCall();
  }

  Future<void> _acceptIncomingCall() async {
    final call = _incomingCall;
    if (call == null || call.isTerminal || _submitting) {
      return;
    }

    setState(() {
      _submitting = true;
    });

    final ret = await call.accept();
    if (!mounted) {
      return;
    }

    setState(() {
      _submitting = false;
    });

    if (!ret.success) {
      final spec = _callActionDialogSpec(
        title: '接听失败',
        message: ret.message ?? '接听失败，请稍后重试。',
      );
      await _showCallResultDialog(
        spec.title,
        spec.message,
        icon: spec.icon,
        accentColor: spec.accentColor,
        badgeColor: spec.badgeColor,
      );
    }
  }

  Future<void> _endCall() async {
    if (_submitting) {
      return;
    }
    if (_connectedCall == null && _incomingCall == null && _outgoingCall == null) {
      return;
    }

    final shouldDeactivateLiveStream = _connectedCall != null && !_connectedCall!.isTerminal;
    if (shouldDeactivateLiveStream) {
      await _deactivateLiveStreamIfNeeded();
      if (!mounted) {
        return;
      }
    }

    setState(() {
      _submitting = true;
    });

    late final Ret ret;
    if (_connectedCall != null && !_connectedCall!.isTerminal) {
      ret = await _connectedCall!.hangup();
    } else if (_incomingCall != null && !_incomingCall!.isTerminal) {
      ret = await _incomingCall!.reject();
    } else if (_outgoingCall != null && !_outgoingCall!.isTerminal) {
      ret = await _outgoingCall!.cancel();
    } else {
      ret = Ret.success();
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _submitting = false;
    });

    if (!ret.success) {
      if (shouldDeactivateLiveStream && mounted) {
        _syncLiveActivation();
      }
      final spec = _callActionDialogSpec(
        title: '操作失败',
        message: ret.message ?? '当前操作未执行成功，请稍后重试。',
      );
      await _showCallResultDialog(
        spec.title,
        spec.message,
        icon: spec.icon,
        accentColor: spec.accentColor,
        badgeColor: spec.badgeColor,
      );
    }
  }

  void _handleIncomingEvent(IncomingCallEvent event) {
    if (!mounted) {
      return;
    }

    if (event.state == IncomingCallState.connected) {
      unawaited(_resolveConnectedCall(_incomingCall!.connectedCall));
      setState(() {});
      return;
    }

    if ((event.state == IncomingCallState.ended || event.state == IncomingCallState.failed) && _connectedCall == null) {
      _setActive(false);
      final message = _callEndReasonText(event.endReason);
      if (message.isNotEmpty) {
        unawaited(_showTerminalResultAndPop(event.endReason));
      } else {
        Navigator.pop(context);
      }
      return;
    }

    setState(() {});
  }

  void _handleOutgoingEvent(OutgoingCallEvent event) {
    if (!mounted) {
      return;
    }

    if (event.state == OutgoingCallState.connected) {
      unawaited(_resolveConnectedCall(_outgoingCall!.connectedCall));
      setState(() {});
      return;
    }

    if ((event.state == OutgoingCallState.ended || event.state == OutgoingCallState.failed) && _connectedCall == null) {
      _setActive(false);
      final message = _callEndReasonText(event.endReason);
      if (message.isNotEmpty) {
        unawaited(_showTerminalResultAndPop(event.endReason));
      } else {
        Navigator.pop(context);
      }
      return;
    }

    setState(() {});
  }

  void _handleConnectedCallEvent(ConnectedCallEvent event) {
    if (!mounted) {
      return;
    }

    if (event.state == ConnectedCallState.active) {
      _scheduleLiveStreamBinding();
      _syncLiveActivation();
      return;
    }

    if (event.state == ConnectedCallState.ended || event.state == ConnectedCallState.failed) {
      _setActive(false);
      final message = _callEndReasonText(event.endReason);
      if (message.isNotEmpty) {
        unawaited(_showTerminalResultAndPop(event.endReason));
      } else {
        Navigator.pop(context);
      }
      return;
    }

    setState(() {});
  }
}

class _CallResultDialogSpec {
  final String title;
  final String message;
  final IconData icon;
  final Color accentColor;
  final Color badgeColor;

  const _CallResultDialogSpec({
    required this.title,
    required this.message,
    required this.icon,
    required this.accentColor,
    required this.badgeColor,
  });

  _CallResultDialogSpec copyWith({
    String? title,
    String? message,
    IconData? icon,
    Color? accentColor,
    Color? badgeColor,
  }) {
    return _CallResultDialogSpec(
      title: title ?? this.title,
      message: message ?? this.message,
      icon: icon ?? this.icon,
      accentColor: accentColor ?? this.accentColor,
      badgeColor: badgeColor ?? this.badgeColor,
    );
  }
}

_CallResultDialogSpec _callActionDialogSpec({
  required String title,
  required String message,
}) {
  return const _CallResultDialogSpec(
    title: '',
    message: '',
    icon: Icons.error_outline_rounded,
    accentColor: Color(0xFFC85A54),
    badgeColor: Color(0xFFFFEEEC),
  ).copyWith(title: title, message: message);
}

_CallResultDialogSpec _callResultDialogSpec(CallEndReason? reason) {
  switch (reason) {
    case CallEndReason.cancelledByLocal:
      return const _CallResultDialogSpec(
        title: '已取消呼叫',
        message: '本次呼叫已由当前客户端取消。',
        icon: Icons.close_rounded,
        accentColor: Color(0xFF8A6E3B),
        badgeColor: Color(0xFFF7F2E7),
      );
    case CallEndReason.rejectedByLocal:
      return const _CallResultDialogSpec(
        title: '已拒接',
        message: '你已拒绝本次来电。',
        icon: Icons.call_end_rounded,
        accentColor: Color(0xFFB85C38),
        badgeColor: Color(0xFFFFF0EB),
      );
    case CallEndReason.hangupByLocal:
      return const _CallResultDialogSpec(
        title: '已挂断',
        message: '本次通话已结束。',
        icon: Icons.call_end_rounded,
        accentColor: Color(0xFFB85C38),
        badgeColor: Color(0xFFFFF0EB),
      );
    case CallEndReason.cancelledByRemote:
      return const _CallResultDialogSpec(
        title: '设备已取消',
        message: '设备侧取消了本次呼叫。',
        icon: Icons.notifications_off_outlined,
        accentColor: Color(0xFF8A6E3B),
        badgeColor: Color(0xFFF7F2E7),
      );
    case CallEndReason.rejectedByRemote:
      return const _CallResultDialogSpec(
        title: '对方已拒接',
        message: '设备当前未接受这次呼叫。',
        icon: Icons.call_end_rounded,
        accentColor: Color(0xFFC85A54),
        badgeColor: Color(0xFFFFEEEC),
      );
    case CallEndReason.hangupByRemote:
      return const _CallResultDialogSpec(
        title: '设备已挂断',
        message: '设备侧结束了当前通话。',
        icon: Icons.phone_disabled_rounded,
        accentColor: Color(0xFFC85A54),
        badgeColor: Color(0xFFFFEEEC),
      );
    case CallEndReason.missed:
      return const _CallResultDialogSpec(
        title: '暂时无人接听',
        message: '本次呼叫在等待时间内未接通。',
        icon: Icons.schedule_rounded,
        accentColor: Color(0xFF8A6E3B),
        badgeColor: Color(0xFFF7F2E7),
      );
    case CallEndReason.busy:
      return const _CallResultDialogSpec(
        title: '对方忙线中',
        message: '设备当前正在通话或处理其他呼叫，请稍后再试。',
        icon: Icons.hourglass_top_rounded,
        accentColor: Color(0xFF8A6E3B),
        badgeColor: Color(0xFFF7F2E7),
      );
    case CallEndReason.answeredByElsewhere:
      return const _CallResultDialogSpec(
        title: '已被其他端接听',
        message: '这次呼叫已经在其他客户端接通。',
        icon: Icons.devices_other_rounded,
        accentColor: SampleThemeConfigure.colorPrimary,
        badgeColor: Color(0xFFEAF1EE),
      );
    case CallEndReason.connectFailed:
      return const _CallResultDialogSpec(
        title: '连接设备失败',
        message: '客户端未能成功连接到设备，请检查网络或设备状态后重试。',
        icon: Icons.wifi_off_rounded,
        accentColor: Color(0xFFC85A54),
        badgeColor: Color(0xFFFFEEEC),
      );
    case CallEndReason.outgoingRequestFailed:
      return const _CallResultDialogSpec(
        title: '呼叫请求发送失败',
        message: '客户端未能成功发出呼叫请求，请稍后重试。',
        icon: Icons.cloud_off_rounded,
        accentColor: Color(0xFFC85A54),
        badgeColor: Color(0xFFFFEEEC),
      );
    case CallEndReason.operationFailed:
      return const _CallResultDialogSpec(
        title: '呼叫操作失败',
        message: '当前呼叫操作未执行成功，请稍后重试。',
        icon: Icons.error_outline_rounded,
        accentColor: Color(0xFFC85A54),
        badgeColor: Color(0xFFFFEEEC),
      );
    case null:
      return const _CallResultDialogSpec(
        title: '呼叫已结束',
        message: '本次呼叫已结束。',
        icon: Icons.info_outline_rounded,
        accentColor: SampleThemeConfigure.colorPrimary,
        badgeColor: Color(0xFFEAF1EE),
      );
  }
}

String _callEndReasonText(CallEndReason? reason) {
  switch (reason) {
    case CallEndReason.cancelledByLocal:
      return '已取消呼叫';
    case CallEndReason.rejectedByLocal:
      return '已拒接';
    case CallEndReason.hangupByLocal:
      return '已挂断';
    case CallEndReason.cancelledByRemote:
      return '设备已取消';
    case CallEndReason.rejectedByRemote:
      return '设备已拒接';
    case CallEndReason.hangupByRemote:
      return '设备已挂断';
    case CallEndReason.missed:
      return '呼叫超时';
    case CallEndReason.busy:
      return '设备忙线中';
    case CallEndReason.answeredByElsewhere:
      return '已在其他端接听';
    case CallEndReason.connectFailed:
      return '设备连接失败';
    case CallEndReason.outgoingRequestFailed:
      return '云端呼叫请求失败';
    case CallEndReason.operationFailed:
      return '呼叫操作失败';
    case null:
      return '呼叫已结束';
  }
}
