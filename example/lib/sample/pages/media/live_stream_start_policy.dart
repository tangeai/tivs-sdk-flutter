enum LiveStreamStartAction {
  establishPipe,
  waitForPipe,
  startPrimary,
  none,
}

class LiveStreamStartPolicy {
  static LiveStreamStartAction resolve({
    required bool pipeEstablished,
    required bool pipeAttempting,
    required bool primaryStarted,
  }) {
    if (!pipeEstablished) {
      return pipeAttempting
          ? LiveStreamStartAction.waitForPipe
          : LiveStreamStartAction.establishPipe;
    }
    if (primaryStarted) return LiveStreamStartAction.none;
    return LiveStreamStartAction.startPrimary;
  }
}

class LiveStreamSecondaryStartPolicy {
  static bool shouldStart({
    required bool hasIndependentSecondary,
    required bool active,
    required bool pipeEstablished,
    required bool primaryStarted,
    required bool secondaryStarted,
  }) {
    return hasIndependentSecondary &&
        active &&
        pipeEstablished &&
        primaryStarted &&
        !secondaryStarted;
  }
}

class LiveStreamQualityApplyPolicy {
  static bool shouldApply({
    required bool pureAudioMode,
    required bool pipeEstablished,
    required bool primaryStarted,
    required bool primaryPlaybackReady,
  }) {
    return !pureAudioMode &&
        pipeEstablished &&
        primaryStarted &&
        primaryPlaybackReady;
  }
}

class LiveStreamRenderPolicy {
  static bool anyVisiblePlayerRendering(Iterable<bool> playerReady) {
    return playerReady.any((ready) => ready);
  }
}
