/// Connectivity snapshot for AI-gated scouting flows.
enum OnlineStatus {
  /// Initial probe or re-check in progress — treat as not ready.
  checking,

  /// No usable network for cloud AI.
  offline,

  /// Network interface up and reachability probe succeeded.
  online,
}

class StillScoutOnlineSnapshot {
  const StillScoutOnlineSnapshot(this.status);

  final OnlineStatus status;

  bool get isOnline => status == OnlineStatus.online;
  bool get isChecking => status == OnlineStatus.checking;
}
