class PrimaryChannelCapability {
  PrimaryChannelCapability._();

  static const int _maxHandledChannelCount = 3;

  static int? channelCount(Map<String, dynamic>? features) {
    if (features == null) return null;

    for (final entry in features.entries) {
      if (entry.key.toLowerCase() != 'multichannels') continue;

      final value =
          entry.value.toString().replaceAll('"', '').trim().toLowerCase();
      if (value == 'no') return 1;

      final match = RegExp(r'^([1-9]\d*)-composed$').firstMatch(value);
      return match == null ? null : int.parse(match.group(1)!);
    }

    return null;
  }

  static int handledChannelCount(Map<String, dynamic>? features) {
    final count = channelCount(features) ?? 1;
    return count > _maxHandledChannelCount ? _maxHandledChannelCount : count;
  }

  static bool supports(Map<String, dynamic>? features, int channel) {
    return channel >= 0 && channel < handledChannelCount(features);
  }
}
