part of '../library.dart';

class _CallRegistry {
  static const String _tag = 'CallObserver';
  static final Map<String, _CallRuntime> _runtimes = <String, _CallRuntime>{};
  static bool _initialized = false;

  static void ensureInitialized() {
    if (_initialized) {
      return;
    }
    _initialized = true;
    PersistentChannel.addMessageListener(_handlePersistentMessage);
  }

  static _CallRuntime? runtimeOf(String deviceId) => _runtimes[deviceId];

  static void register(_CallRuntime runtime) {
    _runtimes[runtime.deviceId] = runtime;
  }

  static void unbind(_CallRuntime runtime) {
    final current = _runtimes[runtime.deviceId];
    if (identical(current, runtime)) {
      _runtimes.remove(runtime.deviceId);
    }
  }

  static void _handlePersistentMessage(String name, String detail) {
    final message = name.trim();
    if (!_isPersistentCallMessage(message)) {
      return;
    }

    final payload = _decodeJsonObject(detail);
    final deviceId = _extractDeviceId(payload);
    if (deviceId == null || deviceId.isEmpty) {
      Logging.w(
        _tag,
        '[_handlePersistentMessage] missing device id, name=$name, detail=$detail',
      );
      return;
    }

    if (message == _persistentMessageDoorbell) {
      _handleIncomingDoorbell(deviceId);
      return;
    }

    final runtime = _runtimes[deviceId];
    if (runtime == null) {
      return;
    }

    final endReason = _persistentMessageToEndReason(message);
    if (endReason != null) {
      runtime.finish(endReason);
    }
  }

  static void _handleIncomingDoorbell(String deviceId) {
    final existing = _runtimes[deviceId];
    if (existing != null && !existing.isTerminal) {
      return;
    }

    final runtime = _CallRuntime.incoming(deviceId: deviceId);
    register(runtime);
    CallObserver._emitIncoming(runtime.incomingCall!);
  }
}

enum _CallDirection { incoming, outgoing }

class _CallRuntime {
  static const String _tag = 'CallRuntime';
  static const Duration _connectTimeout = Duration(seconds: 15);

  _CallRuntime.incoming({required this.deviceId})
      : direction = _CallDirection.incoming,
        _outgoingOptions = null,
        incomingCall = null,
        outgoingCall = null {
    incomingCall = IncomingCall._(this);
    _lastIncomingEvent = IncomingCallEvent(
      deviceId: deviceId,
      state: IncomingCallState.ringing,
    );
  }

  _CallRuntime.outgoing({
    required this.deviceId,
    required OutgoingCallOptions outgoingOptions,
  })  : direction = _CallDirection.outgoing,
        _outgoingOptions = outgoingOptions,
        incomingCall = null,
        outgoingCall = null {
    outgoingCall = OutgoingCall._(this);
    _lastOutgoingEvent = OutgoingCallEvent(
      deviceId: deviceId,
      state: OutgoingCallState.dialing,
    );
  }

  final String deviceId;
  final _CallDirection direction;
  final OutgoingCallOptions? _outgoingOptions;

  IncomingCall? incomingCall;
  OutgoingCall? outgoingCall;
  ConnectedCall? _connectedCall;

  Pipe? _pipe;
  PipeStateListener? _pipeStateListener;
  LiveStream? _boundLiveStream;
  Completer<bool>? _connectCompleter;
  final Completer<ConnectedCall> _connectedCallCompleter = Completer<ConnectedCall>();
  bool _cancelRequested = false;
  bool _outgoingRequestSent = false;
  bool _ended = false;

  IncomingCallEvent? _lastIncomingEvent;
  OutgoingCallEvent? _lastOutgoingEvent;
  ConnectedCallEvent? _lastConnectedCallEvent;

  final List<IncomingCallEventListener> _incomingListeners = [];
  final List<OutgoingCallEventListener> _outgoingListeners = [];
  final List<ConnectedCallEventListener> _connectedCallListeners = [];

  Pipe? get pipe => _pipe;
  bool get isTerminal => _ended;
  ConnectedCall? get connectedCall => _connectedCall;

  int get _timeoutSeconds => _outgoingOptions?.timeoutSeconds ?? _defaultCallTimeoutSeconds;

  IncomingCallState get currentIncomingState => _lastIncomingEvent?.state ?? IncomingCallState.ringing;

  CallEndReason? get currentIncomingEndReason => _lastIncomingEvent?.endReason;

  OutgoingCallState get currentOutgoingState => _lastOutgoingEvent?.state ?? OutgoingCallState.dialing;

  CallEndReason? get currentOutgoingEndReason => _lastOutgoingEvent?.endReason;

  ConnectedCallState get currentConnectedCallState => _lastConnectedCallEvent?.state ?? ConnectedCallState.active;

  CallEndReason? get currentConnectedCallEndReason => _lastConnectedCallEvent?.endReason;

  Future<void> prepareOutgoing() async {
    Logging.i(_tag, '[prepareOutgoing] start, deviceId=$deviceId');
    if (_cancelRequested || isTerminal) {
      Logging.i(
        _tag,
        '[prepareOutgoing] ignored before request, deviceId=$deviceId, cancelRequested=$_cancelRequested, isTerminal=$isTerminal',
      );
      return;
    }

    late final Resp<SendByAppResp> request;
    try {
      request = await MessageService.send(
        deviceId,
        topic: _messageTopicCall,
        data: _emptyJsonObject,
      );
    } catch (error, stackTrace) {
      Logging.e(
        _tag,
        '[prepareOutgoing] send-by-app threw, deviceId=$deviceId, error=$error, stackTrace=$stackTrace',
      );
      finish(CallEndReason.outgoingRequestFailed);
      rethrow;
    }

    Logging.i(
      _tag,
      '[prepareOutgoing] send-by-app finished, deviceId=$deviceId, success=${request.success}, code=${request.code}, message=${request.message}',
    );
    if (_cancelRequested || isTerminal) {
      Logging.i(
        _tag,
        '[prepareOutgoing] ignored after request, deviceId=$deviceId, cancelRequested=$_cancelRequested, isTerminal=$isTerminal',
      );
      return;
    }
    if (!request.success) {
      Logging.w(
        _tag,
        '[prepareOutgoing] send-by-app failed, deviceId=$deviceId, code=${request.code}, message=${request.message}',
      );
      finish(CallEndReason.outgoingRequestFailed);
      return;
    }

    _outgoingRequestSent = true;
    Logging.i(_tag, '[prepareOutgoing] request accepted, deviceId=$deviceId');
  }

  Future<void> continueOutgoing() async {
    Logging.i(_tag, '[continueOutgoing] start, deviceId=$deviceId');
    if (_cancelRequested || isTerminal) {
      Logging.i(
        _tag,
        '[continueOutgoing] ignored before ensure pipe, deviceId=$deviceId, cancelRequested=$_cancelRequested, isTerminal=$isTerminal',
      );
      return;
    }
    if (!_outgoingRequestSent) {
      Logging.w(_tag, '[continueOutgoing] request not prepared, deviceId=$deviceId');
      finish(CallEndReason.outgoingRequestFailed);
      return;
    }

    final ready = await _ensurePipeConnected();
    Logging.i(
      _tag,
      '[continueOutgoing] after ensure pipe, deviceId=$deviceId, ready=$ready, hasPipe=${_pipe != null}, pipeState=${_pipe?.currentState()}',
    );
    if (_cancelRequested || isTerminal) {
      Logging.i(
        _tag,
        '[continueOutgoing] ignored after ensure pipe, deviceId=$deviceId, cancelRequested=$_cancelRequested, isTerminal=$isTerminal',
      );
      return;
    }
    if (!ready || _pipe == null) {
      Logging.w(
        _tag,
        '[continueOutgoing] device connection failed, deviceId=$deviceId, ready=$ready, hasPipe=${_pipe != null}',
      );
      finish(CallEndReason.connectFailed);
      return;
    }

    _emitOutgoing(OutgoingCallState.ringing);
    Logging.i(
      _tag,
      '[continueOutgoing] before start_call, deviceId=$deviceId, timeoutSeconds=$_timeoutSeconds',
    );
    final resp = await InstructStandard.startCallRaw(
      _pipe!,
      flavor: _startCallRequestFlavor,
      timeoutSecond: _timeoutSeconds,
    );
    Logging.i(
      _tag,
      '[continueOutgoing] after start_call, deviceId=$deviceId, success=${resp.success}, code=${resp.code}, message=${resp.message}, result=${resp.data}',
    );
    if (_cancelRequested || isTerminal) {
      Logging.i(
        _tag,
        '[continueOutgoing] ignored after start_call, deviceId=$deviceId, cancelRequested=$_cancelRequested, isTerminal=$isTerminal',
      );
      return;
    }
    if (!resp.success) {
      finish(CallEndReason.operationFailed);
      return;
    }

    final result = resp.data ?? _startCallResultUnknown;
    if (_isStartCallAccepted(result)) {
      _activate();
      return;
    }

    final endReason = _startCallResultToEndReason(result);
    if (endReason != null) {
      finish(endReason);
      return;
    }

    finish(CallEndReason.operationFailed);
  }

  Future<Ret> acceptIncoming() async {
    if (direction != _CallDirection.incoming || isTerminal) {
      return Ret.error(-1, 'incoming call is not available');
    }

    final ready = await _ensurePipeConnected();
    if (!ready || _pipe == null) {
      finish(CallEndReason.connectFailed);
      return Ret.error(-1, 'device connection failed');
    }

    final ret = await InstructStandard.answerCall(_pipe!);
    if (!ret.success) {
      finish(CallEndReason.operationFailed);
      return ret;
    }

    _activate();
    return ret;
  }

  Future<Ret> rejectIncoming() async {
    if (direction != _CallDirection.incoming || isTerminal) {
      return Ret.error(-1, 'incoming call is not available');
    }

    final ready = await _ensurePipeConnected();
    if (!ready || _pipe == null) {
      finish(CallEndReason.connectFailed);
      return Ret.error(-1, 'device connection failed');
    }

    final ret = await InstructStandard.rejectCall(_pipe!);
    if (!ret.success) {
      finish(CallEndReason.operationFailed);
      return ret;
    }

    finish(CallEndReason.rejectedByLocal);
    return ret;
  }

  Future<Ret> cancelOutgoing() async {
    if (direction != _CallDirection.outgoing || isTerminal) {
      return Ret.error(-1, 'outgoing call is not available');
    }
    if (_connectedCall != null) {
      return Ret.error(-1, 'cancel is not allowed after call becomes active');
    }

    _cancelRequested = true;
    if (_outgoingRequestSent) {
      final ready = await _ensurePipeConnected();
      if (ready && _pipe != null && _pipe!.isEstablished) {
        final ret = await InstructStandard.cancelCall(_pipe!);
        if (!ret.success) {
          return ret;
        }
      }
    }

    finish(CallEndReason.cancelledByLocal);
    return Ret.success();
  }

  Future<Ret> hangupConnectedCall() async {
    if (_connectedCall == null || isTerminal) {
      return Ret.error(-1, 'connected call is not available');
    }
    if (_pipe == null || !_pipe!.isEstablished) {
      finish(CallEndReason.connectFailed);
      return Ret.error(-1, 'device connection failed');
    }

    final ret = await InstructStandard.hangupCall(_pipe!);
    if (!ret.success) {
      finish(CallEndReason.operationFailed);
      return ret;
    }

    finish(CallEndReason.hangupByLocal);
    return ret;
  }

  void bindLiveStream(LiveStream? stream) {
    if (identical(_boundLiveStream, stream)) {
      return;
    }

    _boundLiveStream?.setExternalDataListener(null);
    _boundLiveStream = stream;

    if (stream == null || _connectedCall == null || isTerminal) {
      return;
    }

    stream.setExternalDataListener(_handleLiveExternalData);
  }

  Future<ConnectedCall> waitConnectedCall() => _connectedCallCompleter.future;

  void addIncomingListener(IncomingCallEventListener listener) {
    if (!_incomingListeners.contains(listener)) {
      _incomingListeners.add(listener);
    }
    final event = _lastIncomingEvent;
    if (event != null) {
      listener(event);
    }
  }

  void removeIncomingListener(IncomingCallEventListener listener) {
    _incomingListeners.remove(listener);
  }

  void addOutgoingListener(OutgoingCallEventListener listener) {
    if (!_outgoingListeners.contains(listener)) {
      _outgoingListeners.add(listener);
    }
    final event = _lastOutgoingEvent;
    if (event != null) {
      listener(event);
    }
  }

  void removeOutgoingListener(OutgoingCallEventListener listener) {
    _outgoingListeners.remove(listener);
  }

  void addConnectedCallListener(ConnectedCallEventListener listener) {
    if (!_connectedCallListeners.contains(listener)) {
      _connectedCallListeners.add(listener);
    }
    final event = _lastConnectedCallEvent;
    if (event != null) {
      listener(event);
    }
  }

  void removeConnectedCallListener(ConnectedCallEventListener listener) {
    _connectedCallListeners.remove(listener);
  }

  void finish(CallEndReason reason) {
    if (_ended) {
      return;
    }
    Logging.i(
      _tag,
      '[finish] deviceId=$deviceId, direction=$direction, reason=$reason, hasPipe=${_pipe != null}, hasConnectedCall=${_connectedCall != null}',
    );
    _ended = true;

    _boundLiveStream?.setExternalDataListener(null);
    _boundLiveStream = null;

    if (_connectedCall != null || _lastConnectedCallEvent != null) {
      _emitConnectedCall(_connectedCallTerminalStateFor(reason), reason: reason);
    }
    if (incomingCall != null) {
      _emitIncoming(_incomingTerminalStateFor(reason), reason: reason);
    }
    if (outgoingCall != null) {
      _emitOutgoing(_outgoingTerminalStateFor(reason), reason: reason);
    }

    if (!_connectedCallCompleter.isCompleted) {
      _connectedCallCompleter.completeError(
        StateError('connected call is not available'),
      );
    }

    _CallRegistry.unbind(this);
    _disposeOwnedPipe();
  }

  Future<bool> _ensurePipeConnected() async {
    if (_pipe == null) {
      Logging.i(_tag, '[_ensurePipeConnected] create pipe, deviceId=$deviceId');
      _attachOwnedPipe(Pipe.create(deviceId));
    }

    final pipe = _pipe!;
    final currentState = pipe.currentState();
    Logging.i(
      _tag,
      '[_ensurePipeConnected] current state, deviceId=$deviceId, state=$currentState, connecting=${_connectCompleter != null}',
    );
    if (currentState == PipeState.established) {
      return true;
    }
    if (_isPipeTerminalFailure(currentState)) {
      return false;
    }

    if (_connectCompleter != null) {
      Logging.i(_tag, '[_ensurePipeConnected] reuse pending connection, deviceId=$deviceId');
      return _connectCompleter!.future;
    }

    _connectCompleter = Completer<bool>();
    if (currentState != PipeState.attempting) {
      Logging.i(_tag, '[_ensurePipeConnected] establish pipe, deviceId=$deviceId');
      pipe.establish();
    }

    try {
      return await _connectCompleter!.future.timeout(_connectTimeout, onTimeout: () => false);
    } finally {
      _connectCompleter = null;
    }
  }

  void _attachOwnedPipe(Pipe pipe) {
    _disposeOwnedPipe();
    _pipe = pipe;
    Logging.i(_tag, '[_attachOwnedPipe] attached, deviceId=$deviceId');
    _pipeStateListener = _handlePipeState;
    pipe.listen(_pipeStateListener!);
    pipe._nativePipe.setExternalDataListener(_handlePipeExternalData);
  }

  void _disposeOwnedPipe() {
    _completeConnect(false);

    final pipe = _pipe;
    final listener = _pipeStateListener;
    _pipe = null;
    _pipeStateListener = null;
    if (pipe == null) {
      return;
    }

    Logging.i(_tag, '[_disposeOwnedPipe] dispose, deviceId=$deviceId');

    if (listener != null) {
      pipe.listen((_) {});
    }
    try {
      pipe._nativePipe.setExternalDataListener(null);
    } catch (_) {}
    try {
      pipe.abolish();
    } catch (_) {}
    try {
      pipe.destroy();
    } catch (_) {}
  }

  void _activate() {
    Logging.i(_tag, '[_activate] deviceId=$deviceId, direction=$direction');
    if (_connectedCall == null) {
      _connectedCall = ConnectedCall._(this);
      _emitConnectedCall(ConnectedCallState.active);
      if (!_connectedCallCompleter.isCompleted) {
        _connectedCallCompleter.complete(_connectedCall!);
      }
      if (_boundLiveStream != null) {
        _boundLiveStream!.setExternalDataListener(_handleLiveExternalData);
      }
    }

    if (incomingCall != null) {
      _emitIncoming(IncomingCallState.connected);
    }
    if (outgoingCall != null) {
      _emitOutgoing(OutgoingCallState.connected);
    }
  }

  void _handlePipeState(PipeState state) {
    Logging.i(_tag, '[_handlePipeState] deviceId=$deviceId, state=$state');
    if (state == PipeState.established) {
      _completeConnect(true);
      return;
    }
    if (state == PipeState.abolished) {
      _completeConnect(false);
      if (!isTerminal) {
        finish(CallEndReason.connectFailed);
      }
      return;
    }

    if (!_isPipeTerminalFailure(state)) {
      return;
    }

    _completeConnect(false);
    if (!isTerminal) {
      finish(CallEndReason.connectFailed);
    }
  }

  void _handlePipeExternalData(
    int type,
    int data1,
    int data2,
    Uint8List? buffer,
  ) {
    final normalizedType = type == _externalEnvelopeType ? data2 : type;
    Logging.i(
      _tag,
      '[_handlePipeExternalData] deviceId=$deviceId, type=$type, data1=$data1, data2=$data2, normalizedType=$normalizedType, bufferLength=${buffer?.length ?? 0}',
    );
    if (normalizedType != _instructChannelCallEventType || buffer == null || buffer.length < 8 || isTerminal) {
      return;
    }

    final status = _readInt32LE(buffer, _instructChannelStatusOffset);
    final callState = _readInt32LE(buffer, _instructChannelCallStateOffset);
    final endReason = _instructChannelStatusToEndReason(status, callState);
    if (endReason != null) {
      finish(endReason);
    }
  }

  void _handleLiveExternalData(
    int type,
    int data1,
    int data2,
    Uint8List? buffer,
  ) {
    Logging.i(
      _tag,
      '[_handleLiveExternalData] deviceId=$deviceId, type=$type, data1=$data1, data2=$data2, bufferLength=${buffer?.length ?? 0}',
    );
    if (isTerminal || type != _liveStreamCallEventType) {
      return;
    }

    final endReason = _liveStreamStateToEndReason(data1);
    if (endReason != null) {
      finish(endReason);
    }
  }

  void _emitIncoming(IncomingCallState state, {CallEndReason? reason}) {
    final previous = _lastIncomingEvent;
    if (previous != null && previous.state == state && previous.endReason == reason) {
      return;
    }

    final event = IncomingCallEvent(
      deviceId: deviceId,
      state: state,
      endReason: reason,
    );
    _lastIncomingEvent = event;
    final listeners = List<IncomingCallEventListener>.from(_incomingListeners);
    for (final listener in listeners) {
      listener(event);
    }
  }

  void _emitOutgoing(OutgoingCallState state, {CallEndReason? reason}) {
    final previous = _lastOutgoingEvent;
    if (previous != null && previous.state == state && previous.endReason == reason) {
      return;
    }

    final event = OutgoingCallEvent(
      deviceId: deviceId,
      state: state,
      endReason: reason,
    );
    _lastOutgoingEvent = event;
    final listeners = List<OutgoingCallEventListener>.from(_outgoingListeners);
    for (final listener in listeners) {
      listener(event);
    }
  }

  void _emitConnectedCall(ConnectedCallState state, {CallEndReason? reason}) {
    final previous = _lastConnectedCallEvent;
    if (previous != null && previous.state == state && previous.endReason == reason) {
      return;
    }

    final event = ConnectedCallEvent(
      deviceId: deviceId,
      state: state,
      endReason: reason,
    );
    _lastConnectedCallEvent = event;
    final listeners = List<ConnectedCallEventListener>.from(_connectedCallListeners);
    for (final listener in listeners) {
      listener(event);
    }
  }

  void _completeConnect(bool ready) {
    final completer = _connectCompleter;
    if (completer == null || completer.isCompleted) {
      return;
    }
    completer.complete(ready);
  }

  static bool _isPipeTerminalFailure(PipeState state) {
    return state == PipeState.failed ||
        state == PipeState.shutdownByRemote ||
        state == PipeState.tokenNotAvailable ||
        state == PipeState.internetNotAvailable ||
        state == PipeState.authFailed;
  }
}
