part of '../rapid_kit_sample_pages.dart';

class ChatSession implements MediaDumpSender {
  final BuildContext context;
  final Pipe pipe;
  final Player player;
  final void Function(bool mute) setMute;
  final bool Function() isPlayerMute;
  final bool Function() enable16k;

  final MediaChat? _mediaChat;

  bool _chatShouldRestoreMute = false;
  bool _chatMuteBackup = false;

  ChatSession({
    required this.context,
    required this.pipe,
    required this.player,
    required this.setMute,
    required this.isPlayerMute,
    required this.enable16k,
  }) : _mediaChat = MediaChat.create(pipe, playbackPlayer: player);

  bool get started => _mediaChat?.started() ?? false;

  bool get usePushToTalk => !SampleConstants.intercomAecEnabled;

  @override
  bool startDump() => _mediaChat?.startDump() ?? false;

  @override
  bool stopDump() => _mediaChat?.stopDump() ?? false;

  Future<void> pressToTalkStart() async {
    if (!usePushToTalk) {
      await toggle();
      return;
    }

    final mediaChat = _mediaChat;
    if (mediaChat == null || !pipe.isEstablished) return;
    if (mediaChat.started()) return;

    final microphoneGranted = await RuntimePermissions.accessGranted(
      PermissionType.microphone,
    );
    if (!microphoneGranted) {
      final state = await RuntimePermissions.requestAccess(
        PermissionType.microphone,
      );
      if (state == PermissionState.denied) {
        SnackTips.show(context, "请在系统设置中授予麦克风权限。");
      }
      return;
    }

    final config = await _loadIntercomAudioProcessingConfig();
    final duplexEnabled = config.aecLevel != 0;

    mediaChat.configureAudioProcessing(config);
    await mediaChat.prepare();

    _chatMuteBackup = isPlayerMute();
    if (!duplexEnabled && !_chatMuteBackup) {
      setMute(true);
      _chatShouldRestoreMute = true;
    } else {
      _chatShouldRestoreMute = false;
    }

    final sampleRate =
        enable16k() ? MediaChat.sampleRate16k : MediaChat.sampleRate8k;
    await mediaChat.start(sampleRate: sampleRate);
  }

  Future<void> pressToTalkEnd() async {
    if (!usePushToTalk) return;

    final mediaChat = _mediaChat;
    if (mediaChat == null) return;
    if (!mediaChat.started()) return;

    mediaChat.stop();

    if (_chatShouldRestoreMute) {
      setMute(_chatMuteBackup);
      _chatShouldRestoreMute = false;
    }
  }

  Future<void> toggle() async {
    final mediaChat = _mediaChat;
    if (mediaChat == null || !pipe.isEstablished) return;

    final microphoneGranted = await RuntimePermissions.accessGranted(
      PermissionType.microphone,
    );
    if (!microphoneGranted) {
      final state = await RuntimePermissions.requestAccess(
        PermissionType.microphone,
      );
      if (state == PermissionState.denied) {
        SnackTips.show(context, "请在系统设置中授予麦克风权限。");
      }
      return;
    }

    final config = await _loadIntercomAudioProcessingConfig();
    final duplexEnabled = config.aecLevel != 0;

    if (mediaChat.started()) {
      mediaChat.stop();

      if (_chatShouldRestoreMute) {
        setMute(_chatMuteBackup);
        _chatShouldRestoreMute = false;
      }
      return;
    }

    mediaChat.configureAudioProcessing(config);
    await mediaChat.prepare();
    if (!duplexEnabled) {
      _chatMuteBackup = isPlayerMute();
      if (!_chatMuteBackup) {
        setMute(true);
        _chatShouldRestoreMute = true;
      }
    }

    final sampleRate =
        enable16k() ? MediaChat.sampleRate16k : MediaChat.sampleRate8k;
    await mediaChat.start(sampleRate: sampleRate);
    SnackTips.show(
      context,
      "对讲采样率： ${enable16k() ? "16K" : "8K"}，模式： ${duplexEnabled ? "全双工" : "半双工"}",
    );
  }

  Future<IntercomAudioProcessingConfig>
      _loadIntercomAudioProcessingConfig() async {
    final rawAec = await SharedPreferencesUtil.instance.getInt(
          SampleConstants.storageKeyAudioIntercomAecLevel,
          AudioProcessingDefaults.unsetLevel,
        ) ??
        AudioProcessingDefaults.unsetLevel;
    final rawNs = await SharedPreferencesUtil.instance.getInt(
          SampleConstants.storageKeyAudioIntercomNsLevel,
        ) ??
        0;
    final rawAgc = await SharedPreferencesUtil.instance.getInt(
          SampleConstants.storageKeyAudioIntercomAgcLevel,
        ) ??
        SampleConstants.defaultAudioIntercomAgcLevel;

    final aec = rawAec == AudioProcessingDefaults.unsetLevel
        ? SampleConstants.defaultAudioIntercomAecLevel
        : rawAec.clamp(0, 2);
    final ns = rawNs.clamp(0, 2);
    final agc = rawAgc.clamp(0, 2);

    return IntercomAudioProcessingConfig(
      nsLevel: ns,
      aecLevel: aec,
      agcLevel: agc,
    );
  }

  void stopOnPause() {
    final mediaChat = _mediaChat;
    if (mediaChat == null) return;

    if (mediaChat.started()) {
      mediaChat.stop();
    }

    _chatShouldRestoreMute = false;
  }

  void applyAudioProcessingConfig(IntercomAudioProcessingConfig config) {
    final mediaChat = _mediaChat;
    if (mediaChat == null) return;
    mediaChat.configureAudioProcessing(config);
  }

  void destroy() {
    _mediaChat?.destroy();
  }
}
