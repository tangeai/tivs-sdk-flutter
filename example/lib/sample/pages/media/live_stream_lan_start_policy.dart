enum LiveStreamLanStartAction {
  establishPipe,
  startPlayers,
  none,
}

class LiveStreamLanStartPolicy {
  static LiveStreamLanStartAction resolve({
    required bool pipeEstablished,
    required bool streamStarted,
  }) {
    if (!pipeEstablished) return LiveStreamLanStartAction.establishPipe;
    if (streamStarted) return LiveStreamLanStartAction.none;
    return LiveStreamLanStartAction.startPlayers;
  }
}
