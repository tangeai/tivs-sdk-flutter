part of '../rapid_kit_sample_pages.dart';

class AudioProcessingDefaults {
  static const unsetLevel = -1;
  static const _switchOff = 0;
  static const _switchOn = 1;
  static const _hardwareAec = 2;

  static int resolveIntercomAecLevel(
    int storedLevel,
    Map<String, dynamic>? features,
  ) {
    if (storedLevel != unsetLevel) {
      return storedLevel.clamp(_switchOff, _hardwareAec);
    }
    return defaultIntercomAecLevel(features);
  }

  static int defaultIntercomAecLevel(Map<String, dynamic>? features) {
    final microphone = _lookupIgnoreCase(features, 'Microphone');
    if (microphone is Map) {
      final keys = microphone.keys
          .map((key) => key.toString().toLowerCase())
          .toList(growable: false);
      if (keys.contains('aec')) return _switchOn;
    }
    if (microphone is List) {
      final items = microphone
          .map((item) => item.toString().toLowerCase())
          .toList(growable: false);
      if (items.contains('aec')) return _switchOn;
    }
    if (microphone is String) {
      if (_containsAecToken(microphone)) return _switchOn;
    }
    return _switchOn;
  }

  static int defaultIntercomAecLevelFromDeviceAbilities(
    String? deviceAbilities,
  ) {
    if (deviceAbilities == null || deviceAbilities.isEmpty) return _switchOn;
    try {
      final json = convert.jsonDecode(deviceAbilities);
      if (json is! Map) return _switchOn;
      return defaultIntercomAecLevel(_featureMapFromAbilitiesJson(json));
    } catch (e) {
      return _switchOn;
    }
  }

  static Map<String, dynamic> _featureMapFromAbilitiesJson(
    Map<dynamic, dynamic> json,
  ) {
    final data = json['data'];
    if (data is Map && data['feature'] is Map) {
      return Map<String, dynamic>.from(data['feature'] as Map);
    }
    final feature = json['feature'];
    if (feature is Map) {
      return Map<String, dynamic>.from(feature);
    }
    return Map<String, dynamic>.from(json);
  }

  static bool _containsAecToken(String value) {
    return value
        .split(RegExp(r'[^A-Za-z0-9_]+'))
        .map((token) => token.toLowerCase())
        .contains('aec');
  }

  static dynamic _lookupIgnoreCase(Map<String, dynamic>? map, String key) {
    if (map == null) return null;
    final expected = key.toLowerCase();
    for (final entry in map.entries) {
      if (entry.key.toLowerCase() == expected) return entry.value;
    }
    return null;
  }
}

class DeviceAudioCapability {
  static const _negativeTokens = {
    'no',
    'false',
    '0',
    'off',
    'none',
    'unsupported',
    'disable',
    'disabled',
  };

  static bool streamAudioEnabledFromDeviceAbilities(String? deviceAbilities) {
    if (deviceAbilities == null || deviceAbilities.isEmpty) return true;
    try {
      final json = convert.jsonDecode(deviceAbilities);
      if (json is! Map) return true;
      return streamAudioEnabled(
        AudioProcessingDefaults._featureMapFromAbilitiesJson(json),
      );
    } catch (e) {
      return true;
    }
  }

  static bool streamAudioEnabled(Map<String, dynamic>? features) {
    final microphone = AudioProcessingDefaults._lookupIgnoreCase(
      features,
      'Microphone',
    );
    return !_declaresNo(microphone);
  }

  static bool _declaresNo(dynamic value) {
    if (value is bool) return !value;
    if (value is num) return value == 0;
    if (value is String) return _stringDeclaresNo(value);
    if (value is List) return value.any(_declaresNo);
    if (value is Map) {
      for (final key in [
        'enable',
        'enabled',
        'support',
        'supported',
        'available',
        'value',
        'status',
      ]) {
        if (value.containsKey(key)) return _declaresNo(value[key]);
      }
    }
    return false;
  }

  static bool _stringDeclaresNo(String value) {
    final tokens = value
        .split(RegExp(r'[^A-Za-z0-9_]+'))
        .map((token) => token.toLowerCase())
        .where((token) => token.isNotEmpty);
    return tokens.any(_negativeTokens.contains);
  }
}

class AudioConfigureOverlay {
  static void show(
    BuildContext context, {
    required Player player,
    required ChatSession chatSession,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return _AudioConfigureOverlayContent(
          player: player,
          chatSession: chatSession,
        );
      },
    );
  }
}

class _AudioConfigureOverlayContent extends StatefulWidget {
  final Player player;
  final ChatSession chatSession;

  const _AudioConfigureOverlayContent({
    required this.player,
    required this.chatSession,
  });

  @override
  State<_AudioConfigureOverlayContent> createState() =>
      _AudioConfigureOverlayContentState();
}

class _AudioConfigureOverlayContentState
    extends State<_AudioConfigureOverlayContent> {
  static const _switchOff = 0;
  static const _switchOn = 1;
  static const _hardwareAec = 2;

  static const _nsValues = [_switchOff, 1, 2];
  static const _nsLabels = ['关闭', '低', '高'];

  static const _agcValues = [_switchOff, 1, 2];
  static const _agcLabels = ['关闭', '低', '高'];

  static const _aecValues = [_switchOff, _switchOn, _hardwareAec];
  static final _aecLabels = [_nsLabels.first, 'Software AEC', 'Hardware AEC'];

  int _playbackNsLevel = _switchOff;
  int _playbackAgcLevel = SampleConstants.defaultAudioPlaybackAgcLevel;
  int _intercomAecLevel = _switchOff;
  int _intercomNsLevel = SampleConstants.defaultAudioIntercomNsLevel;
  int _intercomAgcLevel = SampleConstants.defaultAudioIntercomAgcLevel;

  @override
  void initState() {
    super.initState();
    _load();
  }

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
          _header(),
          const Divider(height: 1, color: SampleThemeConfigure.colorTextHint),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _sectionCard(
                  title: '播放',
                  children: [
                    _pickTile(
                      title: '降噪 (NS)',
                      valueText: _labelOf(
                        _playbackNsLevel,
                        _nsValues,
                        _nsLabels,
                      ),
                      onTap: () => _pick(
                        title: '播放降噪',
                        values: _nsValues,
                        labels: _nsLabels,
                        current: _playbackNsLevel,
                        onPicked: (v) => _setPlaybackNs(v),
                      ),
                    ),
                    _pickTile(
                      title: '自动增益 (AGC)',
                      valueText: _labelOf(
                        _playbackAgcLevel,
                        _agcValues,
                        _agcLabels,
                      ),
                      onTap: () => _pick(
                        title: '播放自动增益',
                        values: _agcValues,
                        labels: _agcLabels,
                        current: _playbackAgcLevel,
                        onPicked: (v) => _setPlaybackAgc(v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _sectionCard(
                  title: '对讲',
                  children: [
                    _pickTile(
                      title: '回声消除 (AEC)',
                      valueText: _labelOf(
                        _intercomAecLevel,
                        _aecValues,
                        _aecLabels,
                      ),
                      onTap: () => _pick(
                        title: '对讲回声消除',
                        values: _aecValues,
                        labels: _aecLabels,
                        current: _intercomAecLevel,
                        onPicked: (v) => _setIntercomAec(v),
                      ),
                    ),
                    _intercomNsTile(),
                    _intercomAgcTile(),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const SizedBox(width: 16),
          const Icon(
            Icons.tune,
            color: SampleThemeConfigure.colorPrimary,
            size: 20,
          ),
          const SizedBox(width: 8),
          const Text(
            '音频配置',
            style: TextStyle(
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
    );
  }

  Widget _sectionCard({required String title, required List<Widget> children}) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: SampleThemeConfigure.colorTextPrimary,
                ),
              ),
            ),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _pickTile({
    required String title,
    required String valueText,
    required VoidCallback onTap,
  }) {
    return ListTile(
      dense: true,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            valueText,
            style: const TextStyle(color: SampleThemeConfigure.colorTextSub),
          ),
          const SizedBox(width: 10),
          const Icon(
            Icons.arrow_forward_ios,
            size: 10,
            color: SampleThemeConfigure.colorTextHint,
          ),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _intercomNsTile() {
    if (_intercomAecLevel == _hardwareAec) {
      return _switchTile(
        title: '降噪 (NS)',
        value: _intercomNsLevel != _switchOff,
        onChanged: (enabled) => unawaited(
          _setIntercomNs(enabled ? _switchOn : _switchOff),
        ),
      );
    }
    return _pickTile(
      title: '降噪 (NS)',
      valueText: _labelOf(_intercomNsLevel, _nsValues, _nsLabels),
      onTap: () => _pick(
        title: '对讲降噪',
        values: _nsValues,
        labels: _nsLabels,
        current: _intercomNsLevel,
        onPicked: (v) => _setIntercomNs(v),
      ),
    );
  }

  Widget _intercomAgcTile() {
    if (_intercomAecLevel == _hardwareAec) {
      return _switchTile(
        title: '自动增益 (AGC)',
        value: _intercomAgcLevel != _switchOff,
        onChanged: (enabled) => unawaited(
          _setIntercomAgc(enabled ? _switchOn : _switchOff),
        ),
      );
    }
    return _pickTile(
      title: '自动增益 (AGC)',
      valueText: _labelOf(_intercomAgcLevel, _agcValues, _agcLabels),
      onTap: () => _pick(
        title: '对讲自动增益',
        values: _agcValues,
        labels: _agcLabels,
        current: _intercomAgcLevel,
        onPicked: (v) => _setIntercomAgc(v),
      ),
    );
  }

  Widget _switchTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile.adaptive(
      dense: true,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      value: value,
      activeColor: SampleThemeConfigure.colorPrimary,
      onChanged: onChanged,
    );
  }

  Future<void> _pick({
    required String title,
    required List<int> values,
    required List<String> labels,
    required int current,
    required void Function(int) onPicked,
  }) async {
    await showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(32.0),
          child: Wrap(
            children: List.generate(values.length, (i) {
              final v = values[i];
              final n = labels[i];
              final selected = v == current;
              return Container(
                margin: const EdgeInsets.only(bottom: 8.0),
                child: ListTile(
                  title: Text(n),
                  trailing: selected
                      ? const Icon(
                          Icons.check,
                          color: SampleThemeConfigure.colorPrimary,
                        )
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    onPicked(v);
                  },
                ),
              );
            }),
          ),
        );
      },
    );
  }

  String _labelOf(int value, List<int> values, List<String> labels) {
    final i = values.indexOf(value);
    if (i < 0 || i >= labels.length) return '未知';
    return labels[i];
  }

  Future<void> _load() async {
    var playbackNs = await SharedPreferencesUtil.instance.getInt(
          SampleConstants.storageKeyAudioPlaybackNsLevel,
        ) ??
        _switchOff;
    final playbackNsArtifactFixApplied =
        await SharedPreferencesUtil.instance.getInt(
              SampleConstants.storageKeyAudioPlaybackNsArtifactFixApplied,
            ) ??
            _switchOff;
    if (playbackNsArtifactFixApplied != _switchOn) {
      if (playbackNs != _switchOff) {
        playbackNs = _switchOff;
        await SharedPreferencesUtil.instance.setInt(
          SampleConstants.storageKeyAudioPlaybackNsLevel,
          _switchOff,
        );
      }
      await SharedPreferencesUtil.instance.setInt(
        SampleConstants.storageKeyAudioPlaybackNsArtifactFixApplied,
        _switchOn,
      );
    }
    var playbackAgc = await SharedPreferencesUtil.instance.getInt(
          SampleConstants.storageKeyAudioPlaybackAgcLevel,
        ) ??
        SampleConstants.defaultAudioPlaybackAgcLevel;
    final intercomAec = await SharedPreferencesUtil.instance.getInt(
          SampleConstants.storageKeyAudioIntercomAecLevel,
          AudioProcessingDefaults.unsetLevel,
        ) ??
        AudioProcessingDefaults.unsetLevel;
    var intercomNs = await SharedPreferencesUtil.instance.getInt(
          SampleConstants.storageKeyAudioIntercomNsLevel,
        ) ??
        SampleConstants.defaultAudioIntercomNsLevel;
    final intercomAgc = await SharedPreferencesUtil.instance.getInt(
          SampleConstants.storageKeyAudioIntercomAgcLevel,
        ) ??
        SampleConstants.defaultAudioIntercomAgcLevel;
    final feedbackLoopFixApplied = await SharedPreferencesUtil.instance.getInt(
          SampleConstants.storageKeyAudioFeedbackLoopFixApplied,
        ) ??
        _switchOff;
    if (feedbackLoopFixApplied != _switchOn) {
      playbackAgc = SampleConstants.defaultAudioPlaybackAgcLevel;
      intercomNs = SampleConstants.defaultAudioIntercomNsLevel;
      await SharedPreferencesUtil.instance.setInt(
        SampleConstants.storageKeyAudioPlaybackAgcLevel,
        playbackAgc,
      );
      await SharedPreferencesUtil.instance.setInt(
        SampleConstants.storageKeyAudioIntercomNsLevel,
        intercomNs,
      );
      await SharedPreferencesUtil.instance.setInt(
        SampleConstants.storageKeyAudioFeedbackLoopFixApplied,
        _switchOn,
      );
    }

    final safePlaybackNs = playbackNs.clamp(0, 2);
    final safePlaybackAgc = playbackAgc.clamp(0, 2);
    final safeIntercomAec = intercomAec == AudioProcessingDefaults.unsetLevel
        ? SampleConstants.defaultAudioIntercomAecLevel
        : intercomAec.clamp(0, _hardwareAec);
    final safeIntercomNs = intercomNs.clamp(0, 2);
    final safeIntercomAgc = intercomAgc.clamp(0, 2);

    setState(() {
      _playbackNsLevel = safePlaybackNs;
      _playbackAgcLevel = safePlaybackAgc;
      _intercomAecLevel = safeIntercomAec;
      _intercomNsLevel = safeIntercomNs;
      _intercomAgcLevel = safeIntercomAgc;
    });

    SampleConstants.intercomAecEnabled = safeIntercomAec != _switchOff;
    _applyToSession();
  }

  Future<void> _setPlaybackNs(int v) async {
    final value = v.clamp(0, 2);
    setState(() => _playbackNsLevel = value);
    await SharedPreferencesUtil.instance.setInt(
      SampleConstants.storageKeyAudioPlaybackNsLevel,
      value,
    );
    _applyPlayback();
  }

  Future<void> _setPlaybackAgc(int v) async {
    final value = v.clamp(0, 2);
    setState(() => _playbackAgcLevel = value);
    await SharedPreferencesUtil.instance.setInt(
      SampleConstants.storageKeyAudioPlaybackAgcLevel,
      value,
    );
    _applyPlayback();
  }

  Future<void> _setIntercomAec(int v) async {
    final value = v.clamp(0, _hardwareAec);
    setState(() => _intercomAecLevel = value);
    await SharedPreferencesUtil.instance.setInt(
      SampleConstants.storageKeyAudioIntercomAecLevel,
      value,
    );
    SampleConstants.intercomAecEnabled = value != _switchOff;
    _applyIntercom();
  }

  Future<void> _setIntercomNs(int v) async {
    final value = v.clamp(0, 2);
    setState(() => _intercomNsLevel = value);
    await SharedPreferencesUtil.instance.setInt(
      SampleConstants.storageKeyAudioIntercomNsLevel,
      value,
    );
    _applyIntercom();
  }

  Future<void> _setIntercomAgc(int v) async {
    final value = v.clamp(0, 2);
    setState(() => _intercomAgcLevel = value);
    await SharedPreferencesUtil.instance.setInt(
      SampleConstants.storageKeyAudioIntercomAgcLevel,
      value,
    );
    _applyIntercom();
  }

  void _applyToSession() {
    _applyPlayback();
    _applyIntercom();
  }

  void _applyPlayback() {
    widget.player.configureAudioProcessing(
      PlayerAudioProcessingConfig(
        nsLevel: _playbackNsLevel,
        agcLevel: _playbackAgcLevel,
      ),
    );
  }

  void _applyIntercom() {
    widget.chatSession.applyAudioProcessingConfig(
      IntercomAudioProcessingConfig(
        nsLevel: _intercomNsLevel,
        aecLevel: _intercomAecLevel,
        agcLevel: _intercomAgcLevel,
      ),
    );
  }
}
