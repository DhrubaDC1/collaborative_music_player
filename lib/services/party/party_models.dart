enum PartyRole { none, host, guest }

enum PartyConnectionStatus {
  idle,
  hosting,
  joining,
  connected,
  disconnected,
  error,
}

class PartyPeer {
  const PartyPeer({
    required this.id,
    required this.name,
    required this.address,
    this.lastRttMs,
  });

  final String id;
  final String name;
  final String address;
  final int? lastRttMs;

  PartyPeer copyWith({int? lastRttMs}) {
    return PartyPeer(
      id: id,
      name: name,
      address: address,
      lastRttMs: lastRttMs ?? this.lastRttMs,
    );
  }
}

class PartyState {
  const PartyState({
    required this.role,
    required this.status,
    required this.sessionId,
    required this.hostAddress,
    required this.port,
    required this.peers,
    required this.syncSkewMs,
    required this.hostOffsetMs,
    this.message,
  });

  factory PartyState.initial() {
    return const PartyState(
      role: PartyRole.none,
      status: PartyConnectionStatus.idle,
      sessionId: null,
      hostAddress: null,
      port: null,
      peers: <PartyPeer>[],
      syncSkewMs: 0,
      hostOffsetMs: 0,
      message: null,
    );
  }

  final PartyRole role;
  final PartyConnectionStatus status;
  final String? sessionId;
  final String? hostAddress;
  final int? port;
  final List<PartyPeer> peers;
  final int syncSkewMs;
  final int hostOffsetMs;
  final String? message;

  bool get isHost => role == PartyRole.host;
  bool get isGuest => role == PartyRole.guest;
  bool get isConnected =>
      status == PartyConnectionStatus.connected ||
      status == PartyConnectionStatus.hosting;

  PartyState copyWith({
    PartyRole? role,
    PartyConnectionStatus? status,
    String? sessionId,
    String? hostAddress,
    int? port,
    List<PartyPeer>? peers,
    int? syncSkewMs,
    int? hostOffsetMs,
    String? message,
  }) {
    return PartyState(
      role: role ?? this.role,
      status: status ?? this.status,
      sessionId: sessionId ?? this.sessionId,
      hostAddress: hostAddress ?? this.hostAddress,
      port: port ?? this.port,
      peers: peers ?? this.peers,
      syncSkewMs: syncSkewMs ?? this.syncSkewMs,
      hostOffsetMs: hostOffsetMs ?? this.hostOffsetMs,
      message: message,
    );
  }
}
