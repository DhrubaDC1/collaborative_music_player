import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:collaborative_music_player/domain/track_item.dart';
import 'package:collaborative_music_player/services/audio/app_audio_handler.dart';
import 'package:collaborative_music_player/services/audio/audio_providers.dart';
import 'package:collaborative_music_player/services/party/party_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

final partySessionProvider =
    StateNotifierProvider<PartySessionController, PartyState>((ref) {
      final controller = PartySessionController(
        ref.watch(audioHandlerProvider),
      );
      ref.onDispose(controller.dispose);
      return controller;
    });

final _uuid = Uuid();

class PartySessionController extends StateNotifier<PartyState> {
  PartySessionController(this._audio) : super(PartyState.initial()) {
    _queueSub = _audio.queue.listen((_) {
      if (state.isHost) {
        _broadcastQueue();
      }
    });
  }

  final AppAudioHandler _audio;
  final Map<String, Socket> _clientSockets = <String, Socket>{};
  final Map<String, PartyPeer> _peersById = <String, PartyPeer>{};

  ServerSocket? _server;
  HttpServer? _fileServer;
  int? _fileServerPort;
  Socket? _hostSocket;
  StreamSubscription<List<MediaItem>>? _queueSub;
  Timer? _hostTickTimer;
  Timer? _pingTimer;
  Timer? _syncSpeedResetTimer;

  int _hostOffsetMs = 0;

  String get joinPayload {
    if (!state.isHost || state.hostAddress == null || state.port == null) {
      return '';
    }
    final hosts = _cachedJoinHosts.isEmpty
        ? state.hostAddress!
        : _cachedJoinHosts.join(',');
    return 'party://join?host=${state.hostAddress}&hosts=${Uri.encodeComponent(hosts)}&port=${state.port}&session=${state.sessionId}';
  }

  List<String> _cachedJoinHosts = const <String>[];

  Future<void> createSession({int port = 40440}) async {
    await leaveSession();
    try {
      final ipCandidates = await _resolveJoinIps();
      final ip = ipCandidates.isEmpty ? '127.0.0.1' : ipCandidates.first;
      _cachedJoinHosts = ipCandidates;
      final server = await ServerSocket.bind(InternetAddress.anyIPv4, port);
      _server = server;
      await _startFileServer();
      state = state.copyWith(
        role: PartyRole.host,
        status: PartyConnectionStatus.hosting,
        sessionId: _uuid.v4(),
        hostAddress: ip,
        port: server.port,
        peers: const [],
        message:
            'Session live on $ip:${server.port}${ipCandidates.length > 1 ? ' (${ipCandidates.join(', ')})' : ''}',
      );

      server.listen((socket) {
        final id = _uuid.v4();
        _clientSockets[id] = socket;
        _handleIncoming(socket, peerId: id, isClient: true);
      });

      _startHostTicks();
      _broadcastQueue();
    } catch (error) {
      state = state.copyWith(
        status: PartyConnectionStatus.error,
        message: 'Failed to create session: $error',
      );
    }
  }

  Future<void> joinSession({required String host, required int port}) async {
    return joinSessionCandidates(hosts: <String>[host], port: port);
  }

  Future<void> joinSessionCandidates({
    required List<String> hosts,
    required int port,
  }) async {
    await leaveSession();
    final uniqueHosts = hosts
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (uniqueHosts.isEmpty) {
      state = state.copyWith(
        status: PartyConnectionStatus.error,
        message: 'Join failed: no host provided.',
      );
      return;
    }

    state = state.copyWith(
      role: PartyRole.guest,
      status: PartyConnectionStatus.joining,
      hostAddress: uniqueHosts.first,
      port: port,
      message: 'Joining ${uniqueHosts.join(' | ')}:$port...',
    );

    try {
      final socket = await _connectToAnyHost(uniqueHosts, port);
      _hostSocket = socket;
      _handleIncoming(socket, peerId: 'host', isClient: false);
      _send(socket, {
        'type': 'join',
        'name': Platform.localHostname,
        'clientTimeMs': DateTime.now().millisecondsSinceEpoch,
      });
      _startGuestPings();
      state = state.copyWith(
        status: PartyConnectionStatus.connected,
        hostAddress: socket.remoteAddress.address,
        message: 'Connected to host ${socket.remoteAddress.address}:$port',
      );
    } catch (error) {
      state = state.copyWith(
        status: PartyConnectionStatus.error,
        message:
            'Join failed: $error. Ensure both phones are on same Wi-Fi and host uses Wi-Fi IP (usually wlan0).',
      );
    }
  }

  Future<Socket> _connectToAnyHost(List<String> hosts, int port) async {
    Object? lastError;
    for (final host in hosts) {
      try {
        return await Socket.connect(
          host,
          port,
          timeout: const Duration(seconds: 3),
        );
      } catch (error) {
        lastError = error;
      }
    }
    throw lastError ?? SocketException('Connection failed');
  }

  Future<void> leaveSession() async {
    _hostTickTimer?.cancel();
    _pingTimer?.cancel();
    _syncSpeedResetTimer?.cancel();

    for (final socket in _clientSockets.values) {
      await socket.close();
    }
    _clientSockets.clear();

    await _hostSocket?.close();
    _hostSocket = null;

    await _fileServer?.close(force: true);
    _fileServer = null;
    _fileServerPort = null;

    await _server?.close();
    _server = null;

    _peersById.clear();
    _hostOffsetMs = 0;
    state = PartyState.initial();
  }

  Future<void> hostPlay() async {
    final snapshot = await _audio.snapshot();
    final executeAt = DateTime.now().millisecondsSinceEpoch + 550;
    await _audio.play();
    _broadcast({
      'type': 'command',
      'command': 'play',
      'index': snapshot['index'],
      'positionMs': snapshot['positionMs'],
      'executeAtHostMs': executeAt,
    });
  }

  Future<void> hostPause() async {
    final snapshot = await _audio.snapshot();
    await _audio.pause();
    _broadcast({
      'type': 'command',
      'command': 'pause',
      'positionMs': snapshot['positionMs'],
    });
  }

  Future<void> hostSeek(Duration position) async {
    await _audio.seek(position);
    _broadcast({
      'type': 'command',
      'command': 'seek',
      'positionMs': position.inMilliseconds,
    });
  }

  Future<void> hostNext() async {
    await _audio.skipToNext();
    _broadcast(const {'type': 'command', 'command': 'next'});
  }

  Future<void> hostPrevious() async {
    await _audio.skipToPrevious();
    _broadcast(const {'type': 'command', 'command': 'previous'});
  }

  void _startHostTicks() {
    _hostTickTimer?.cancel();
    _hostTickTimer = Timer.periodic(const Duration(milliseconds: 450), (
      _,
    ) async {
      if (!state.isHost || _clientSockets.isEmpty) return;
      final snapshot = await _audio.snapshot();
      _broadcast({
        'type': 'syncTick',
        'command': 'syncTick',
        'positionMs': snapshot['positionMs'],
        'hostTimeMs': snapshot['hostTimeMs'],
        'isPlaying': snapshot['isPlaying'],
        'index': snapshot['index'],
      });
    });
  }

  void _startGuestPings() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      final socket = _hostSocket;
      if (socket == null) return;
      final t1 = DateTime.now().millisecondsSinceEpoch;
      _send(socket, {'type': 'ping', 'clientSendMs': t1});
    });
  }

  void _handleIncoming(
    Socket socket, {
    required String peerId,
    required bool isClient,
  }) {
    socket
        .map((chunk) => utf8.decode(chunk))
        .transform(const LineSplitter())
        .listen(
          (line) => _onMessage(
            line,
            socket: socket,
            peerId: peerId,
            isClient: isClient,
          ),
          onDone: () {
            if (isClient) {
              _removePeer(peerId);
            } else {
              state = state.copyWith(
                status: PartyConnectionStatus.disconnected,
                message: 'Disconnected from host',
              );
            }
          },
        );
  }

  Future<void> _onMessage(
    String line, {
    required Socket socket,
    required String peerId,
    required bool isClient,
  }) async {
    final message = jsonDecode(line) as Map<String, dynamic>;
    final type = message['type'] as String?;
    if (type == null) return;

    if (isClient) {
      if (type == 'join') {
        final peer = PartyPeer(
          id: peerId,
          name: message['name'] as String? ?? 'Guest',
          address: socket.remoteAddress.address,
        );
        _peersById[peerId] = peer;
        _updatePeers();
        _send(socket, {
          'type': 'joined',
          'sessionId': state.sessionId,
          'peerId': peerId,
          'hostTimeMs': DateTime.now().millisecondsSinceEpoch,
        });
        _broadcastQueue(toSocket: socket);
        return;
      }

      if (type == 'ping') {
        final hostRecv = DateTime.now().millisecondsSinceEpoch;
        final clientSend = message['clientSendMs'] as int;
        _send(socket, {
          'type': 'pong',
          'clientSendMs': clientSend,
          'hostRecvMs': hostRecv,
          'hostSendMs': DateTime.now().millisecondsSinceEpoch,
        });
        return;
      }

      if (type == 'requestCommand') {
        final command = message['command'] as String?;
        if (command == null) return;
        switch (command) {
          case 'play':
            await hostPlay();
          case 'pause':
            await hostPause();
          case 'next':
            await hostNext();
          case 'previous':
            await hostPrevious();
          case 'seek':
            final ms = message['positionMs'] as int? ?? 0;
            await hostSeek(Duration(milliseconds: ms));
        }
      }
      return;
    }

    switch (type) {
      case 'joined':
        state = state.copyWith(
          status: PartyConnectionStatus.connected,
          sessionId: message['sessionId'] as String?,
          message: 'Joined session ${message['sessionId']}',
        );
      case 'queue':
        final items = (message['items'] as List<dynamic>? ?? <dynamic>[])
            .cast<Map<String, dynamic>>();
        final tracks = await _resolveGuestQueueTracks(
          items,
          filePort: message['filePort'] as int?,
        );
        await _audio.replaceQueueFromTracks(tracks);
      case 'command':
      case 'syncTick':
        await _handleRemoteCommand(message);
      case 'pong':
        _handlePong(message);
    }
  }

  Future<void> _handleRemoteCommand(Map<String, dynamic> message) async {
    final executeAtHostMs = message['executeAtHostMs'] as int?;
    if (executeAtHostMs != null) {
      final executeAtLocal = executeAtHostMs - _hostOffsetMs;
      final delayMs = executeAtLocal - DateTime.now().millisecondsSinceEpoch;
      if (delayMs > 0) {
        await Future<void>.delayed(Duration(milliseconds: delayMs));
      }
    }

    if (message['type'] == 'syncTick') {
      final hostTime = message['hostTimeMs'] as int;
      final currentPosition = message['positionMs'] as int;
      final hostNow = DateTime.now().millisecondsSinceEpoch + _hostOffsetMs;
      state = state.copyWith(
        syncSkewMs:
            (currentPosition + (hostNow - hostTime)) -
            _audio.currentPosition.inMilliseconds,
      );
      message['hostOffsetMs'] = _hostOffsetMs;
    }

    await _audio.applyRemoteCommand(message);
  }

  void _handlePong(Map<String, dynamic> message) {
    final t1 = message['clientSendMs'] as int;
    final t2 = message['hostRecvMs'] as int;
    final t3 = message['hostSendMs'] as int;
    final t4 = DateTime.now().millisecondsSinceEpoch;

    final offset = ((t2 - t1) + (t3 - t4)) ~/ 2;
    _hostOffsetMs = ((_hostOffsetMs * 3) + offset) ~/ 4;
    state = state.copyWith(hostOffsetMs: _hostOffsetMs);
  }

  void _removePeer(String peerId) {
    _clientSockets.remove(peerId);
    _peersById.remove(peerId);
    _updatePeers();
  }

  void _updatePeers() {
    state = state.copyWith(peers: _peersById.values.toList(growable: false));
  }

  void _broadcastQueue({Socket? toSocket}) {
    final items = _audio.queue.value
        .map(
          (media) => {
            'id': media.id,
            'trackId': media.extras?['trackId'],
            'title': media.title,
            'artist': media.artist,
            'durationMs': media.duration?.inMilliseconds,
          },
        )
        .toList(growable: false);

    final packet = {
      'type': 'queue',
      'items': items,
      'filePort': _fileServerPort,
    };
    if (toSocket != null) {
      _send(toSocket, packet);
      return;
    }
    _broadcast(packet);
  }

  void _broadcast(Map<String, dynamic> packet) {
    for (final socket in _clientSockets.values) {
      _send(socket, packet);
    }
  }

  void _send(Socket socket, Map<String, dynamic> packet) {
    socket.write('${jsonEncode(packet)}\n');
  }

  Future<List<String>> _resolveJoinIps() async {
    final interfaces = await NetworkInterface.list(
      includeLoopback: false,
      type: InternetAddressType.IPv4,
    );

    final best = <String>[];
    final fallback = <String>[];

    for (final iface in interfaces) {
      final name = iface.name.toLowerCase();
      final skipInterface =
          name.contains('lo') ||
          name.contains('rmnet') ||
          name.contains('tun') ||
          name.contains('p2p') ||
          name.contains('docker') ||
          name.contains('veth') ||
          name.contains('tailscale') ||
          name.contains('adb');
      if (skipInterface) continue;

      final preferredInterface =
          name.contains('wlan') ||
          name.contains('wifi') ||
          name.contains('eth') ||
          name.contains('en');

      for (final address in iface.addresses) {
        if (address.type != InternetAddressType.IPv4) continue;
        final ip = address.address;
        if (_isLikelyLanAddress(ip)) {
          if (preferredInterface) {
            best.add(ip);
          } else {
            fallback.add(ip);
          }
        }
      }
    }

    final deduped = <String>{...best, ...fallback}.toList(growable: false);
    if (deduped.isNotEmpty) return deduped;
    return const <String>['127.0.0.1'];
  }

  bool _isLikelyLanAddress(String ip) {
    if (ip.startsWith('169.254.')) return false;
    if (ip.startsWith('127.')) return false;
    return ip.startsWith('192.168.') ||
        ip.startsWith('172.') ||
        ip.startsWith('10.');
  }

  Future<void> _startFileServer() async {
    await _fileServer?.close(force: true);
    final server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
    _fileServer = server;
    _fileServerPort = server.port;

    server.listen((request) async {
      try {
        if (request.method != 'GET' || request.uri.path != '/track') {
          request.response.statusCode = HttpStatus.notFound;
          await request.response.close();
          return;
        }

        final sourcePath = request.uri.queryParameters['path'];
        if (sourcePath == null || sourcePath.isEmpty) {
          request.response.statusCode = HttpStatus.badRequest;
          await request.response.close();
          return;
        }

        final file = File(sourcePath);
        if (!await file.exists()) {
          request.response.statusCode = HttpStatus.notFound;
          await request.response.close();
          return;
        }

        request.response.headers.contentType = ContentType.binary;
        await request.response.addStream(file.openRead());
      } catch (_) {
        request.response.statusCode = HttpStatus.internalServerError;
      } finally {
        await request.response.close();
      }
    });
  }

  Future<List<TrackItem>> _resolveGuestQueueTracks(
    List<Map<String, dynamic>> items, {
    required int? filePort,
  }) async {
    final resolved = <TrackItem>[];
    final host = state.hostAddress;

    for (final item in items) {
      final trackId = item['trackId'] as String? ?? _uuid.v4();
      final remotePath = item['id'] as String;
      final title = item['title'] as String;
      final artist = item['artist'] as String?;
      final durationMs = item['durationMs'] as int?;

      if (remotePath.startsWith('http://') ||
          remotePath.startsWith('https://')) {
        resolved.add(
          TrackItem(
            id: trackId,
            path: remotePath,
            title: title,
            artist: artist,
            durationMs: durationMs,
          ),
        );
        continue;
      }

      var localPath = remotePath;
      if (!await File(remotePath).exists() &&
          host != null &&
          filePort != null) {
        localPath = await _downloadTrackFromHost(
          host: host,
          port: filePort,
          remotePath: remotePath,
          trackId: trackId,
          title: title,
        );
      }

      if (!await File(localPath).exists()) {
        state = state.copyWith(message: 'Missing track on guest: $title');
        continue;
      }

      resolved.add(
        TrackItem(
          id: trackId,
          path: localPath,
          title: title,
          artist: artist,
          durationMs: durationMs,
        ),
      );
    }

    return resolved;
  }

  Future<String> _downloadTrackFromHost({
    required String host,
    required int port,
    required String remotePath,
    required String trackId,
    required String title,
  }) async {
    final extension = p.extension(remotePath).toLowerCase();
    final safeExtension = extension.isEmpty ? '.mp3' : extension;
    final storageDir = Directory('${Directory.systemTemp.path}/party_tracks');
    await storageDir.create(recursive: true);
    final output = File('${storageDir.path}/$trackId$safeExtension');
    if (await output.exists()) {
      return output.path;
    }

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
    try {
      final uri = Uri(
        scheme: 'http',
        host: host,
        port: port,
        path: '/track',
        queryParameters: {'path': remotePath},
      );
      final request = await client.getUrl(uri);
      final response = await request.close().timeout(
        const Duration(seconds: 30),
      );
      if (response.statusCode != HttpStatus.ok) {
        throw SocketException('HTTP ${response.statusCode}');
      }
      await response.pipe(output.openWrite());
      return output.path;
    } catch (_) {
      state = state.copyWith(message: 'Failed to fetch "$title" from host');
      return remotePath;
    } finally {
      client.close(force: true);
    }
  }

  @override
  void dispose() {
    _queueSub?.cancel();
    unawaited(leaveSession());
    super.dispose();
  }
}
