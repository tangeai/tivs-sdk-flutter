String rapidStackTrace() {
  final lines = StackTrace.current.toString().split('\n');
  final frames = <String>[];

  const maxFrames = 5;

  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) continue;
    if (!trimmed.startsWith('#')) continue;

    final normalized = trimmed.replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.contains(' rapidStackTrace ') || normalized.contains('stacktrace.dart')) continue;

    frames.add(normalized);
    if (frames.length >= maxFrames) break;
  }

  if (frames.isEmpty) return '<unknown>';
  return frames.join(' | ');
}
