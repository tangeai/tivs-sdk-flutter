part of '../library.dart';

const String _persistentMessageDoorbell = 'doorbell';
const String _persistentMessageCancelled = 'cancelled';
const String _persistentMessageMissed = 'missed';

const String _messageTopicCall = 'call';
const String _emptyJsonObject = '{}';

const int _startCallRequestFlavor = 2;
const int _startCallResultRejectedByRemote = 0;
const int _startCallResultConnectedAudioOnly = 1;
const int _startCallResultConnectedAudioVideo = 2;
const int _startCallResultMissed = -1;
const int _startCallResultBusy = -2;
const int _startCallResultUnknown = -10000;

const int _externalEnvelopeType = 255;
const int _instructChannelCallEventType = 2;
const int _instructChannelCallStatusFinished = 5;
const int _instructChannelCallStatusHangup = 6;
const int _instructChannelStatusOffset = 0;
const int _instructChannelCallStateOffset = 4;

const int _callStateMissed = 0;
const int _callStateAnsweredElsewhere = 1;
const int _callStateRejectedByRemote = 2;
const int _callStateCancelledByRemote = 3;
const int _callStateHangupByRemote = 4;
const int _callStateBusy = 5;

const int _liveStreamCallEventType = 5;
const int _liveStreamCallStateAnsweredElsewhere = 1;
const int _liveStreamCallStateHangupByRemote = 3;

const int _defaultCallTimeoutSeconds = 30;

typedef IncomingCallListener = void Function(IncomingCall call);
typedef IncomingCallEventListener = void Function(IncomingCallEvent event);
typedef OutgoingCallEventListener = void Function(OutgoingCallEvent event);
typedef ConnectedCallEventListener = void Function(ConnectedCallEvent event);

class OutgoingCallOptions {
  final int timeoutSeconds;

  const OutgoingCallOptions({
    this.timeoutSeconds = _defaultCallTimeoutSeconds,
  });
}

enum CallEndReason {
  cancelledByLocal,
  rejectedByLocal,
  hangupByLocal,
  cancelledByRemote,
  rejectedByRemote,
  hangupByRemote,
  missed,
  busy,
  answeredByElsewhere,
  connectFailed,
  outgoingRequestFailed,
  operationFailed,
}

enum IncomingCallState { ringing, connected, ended, failed }

enum OutgoingCallState { dialing, ringing, connected, ended, failed }

enum ConnectedCallState { active, ended, failed }

class IncomingCallEvent {
  final String deviceId;
  final IncomingCallState state;
  final CallEndReason? endReason;

  const IncomingCallEvent({
    required this.deviceId,
    required this.state,
    this.endReason,
  });
}

class OutgoingCallEvent {
  final String deviceId;
  final OutgoingCallState state;
  final CallEndReason? endReason;

  const OutgoingCallEvent({
    required this.deviceId,
    required this.state,
    this.endReason,
  });
}

class ConnectedCallEvent {
  final String deviceId;
  final ConnectedCallState state;
  final CallEndReason? endReason;

  const ConnectedCallEvent({
    required this.deviceId,
    required this.state,
    this.endReason,
  });
}

bool _isPersistentCallMessage(String message) {
  return message == _persistentMessageDoorbell ||
      message == _persistentMessageCancelled ||
      message == _persistentMessageMissed;
}

CallEndReason? _persistentMessageToEndReason(String message) {
  switch (message) {
    case _persistentMessageCancelled:
      return CallEndReason.cancelledByRemote;
    case _persistentMessageMissed:
      return CallEndReason.missed;
    default:
      return null;
  }
}

bool _isStartCallAccepted(int result) {
  return result == _startCallResultConnectedAudioOnly ||
      result == _startCallResultConnectedAudioVideo;
}

CallEndReason? _startCallResultToEndReason(int result) {
  switch (result) {
    case _startCallResultRejectedByRemote:
      return CallEndReason.rejectedByRemote;
    case _startCallResultMissed:
      return CallEndReason.missed;
    case _startCallResultBusy:
      return CallEndReason.busy;
    default:
      return null;
  }
}

CallEndReason? _instructChannelStatusToEndReason(int status, int callState) {
  if (status == _instructChannelCallStatusHangup) {
    return CallEndReason.hangupByRemote;
  }
  if (status != _instructChannelCallStatusFinished) {
    return null;
  }

  switch (callState) {
    case _callStateMissed:
      return CallEndReason.missed;
    case _callStateAnsweredElsewhere:
      return CallEndReason.answeredByElsewhere;
    case _callStateRejectedByRemote:
      return CallEndReason.rejectedByRemote;
    case _callStateCancelledByRemote:
      return CallEndReason.cancelledByRemote;
    case _callStateHangupByRemote:
      return CallEndReason.hangupByRemote;
    case _callStateBusy:
      return CallEndReason.busy;
    default:
      return null;
  }
}

CallEndReason? _liveStreamStateToEndReason(int state) {
  switch (state) {
    case _liveStreamCallStateAnsweredElsewhere:
      return CallEndReason.answeredByElsewhere;
    case _liveStreamCallStateHangupByRemote:
      return CallEndReason.hangupByRemote;
    default:
      return null;
  }
}

IncomingCallState _incomingTerminalStateFor(CallEndReason reason) {
  switch (reason) {
    case CallEndReason.connectFailed:
    case CallEndReason.operationFailed:
    case CallEndReason.outgoingRequestFailed:
      return IncomingCallState.failed;
    default:
      return IncomingCallState.ended;
  }
}

OutgoingCallState _outgoingTerminalStateFor(CallEndReason reason) {
  switch (reason) {
    case CallEndReason.connectFailed:
    case CallEndReason.operationFailed:
    case CallEndReason.outgoingRequestFailed:
      return OutgoingCallState.failed;
    default:
      return OutgoingCallState.ended;
  }
}

ConnectedCallState _connectedCallTerminalStateFor(CallEndReason reason) {
  switch (reason) {
    case CallEndReason.connectFailed:
    case CallEndReason.operationFailed:
    case CallEndReason.outgoingRequestFailed:
      return ConnectedCallState.failed;
    default:
      return ConnectedCallState.ended;
  }
}

Map<String, dynamic> _decodeJsonObject(String source) {
  final decoded = json.decode(source);
  if (decoded is Map<String, dynamic>) {
    return decoded;
  }
  if (decoded is Map) {
    return decoded.map((key, value) => MapEntry(key.toString(), value));
  }
  return <String, dynamic>{};
}

String? _extractDeviceId(Map<String, dynamic> jsonObject) {
  final value =
      jsonObject['uuid'] ?? jsonObject['device_id'] ?? jsonObject['deviceId'];
  return value?.toString();
}

int _readInt32LE(Uint8List data, int offset) {
  final byteData = ByteData.sublistView(data, offset, offset + 4);
  return byteData.getInt32(0, Endian.little);
}
