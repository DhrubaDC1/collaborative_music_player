import 'package:collaborative_music_player/core/widgets/glass_panel.dart';
import 'package:collaborative_music_player/services/party/party_session_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

class PartyTab extends ConsumerStatefulWidget {
  const PartyTab({super.key});

  @override
  ConsumerState<PartyTab> createState() => _PartyTabState();
}

class _PartyTabState extends ConsumerState<PartyTab> {
  final _hostController = TextEditingController();
  final _portController = TextEditingController(text: '40440');

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(partySessionProvider);
    final controller = ref.read(partySessionProvider.notifier);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: ListView(
        children: [
          const SizedBox(height: 12),
          Text(
            'Party Session',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'LAN-only collaborative mode with synchronized local playback.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          GlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.icon(
                      onPressed: state.isConnected
                          ? null
                          : () => controller.createSession(),
                      icon: const Icon(Icons.campaign_rounded),
                      label: const Text('Create Party'),
                    ),
                    OutlinedButton.icon(
                      onPressed: state.isConnected
                          ? () => controller.leaveSession()
                          : () => _joinFromFields(controller),
                      icon: Icon(
                        state.isConnected ? Icons.logout : Icons.login,
                      ),
                      label: Text(state.isConnected ? 'Leave' : 'Join'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _scanJoinQr,
                      icon: const Icon(Icons.qr_code_scanner_rounded),
                      label: const Text('Scan QR'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _hostController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Host IP',
                    hintText: '192.168.x.x',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _portController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Port',
                  ),
                ),
                const SizedBox(height: 12),
                Text('Status: ${state.status.name}'),
                if (state.message != null) ...[
                  const SizedBox(height: 4),
                  Text(state.message!),
                ],
              ],
            ),
          ),
          if (state.isHost && controller.joinPayload.isNotEmpty) ...[
            const SizedBox(height: 16),
            GlassPanel(
              child: Column(
                children: [
                  Text(
                    'Scan to Join',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  QrImageView(data: controller.joinPayload, size: 220),
                  const SizedBox(height: 8),
                  SelectableText(controller.joinPayload),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          GlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Participants',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                if (state.peers.isEmpty)
                  const Text('No guests connected yet.')
                else
                  ...state.peers.map(
                    (peer) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        child: Icon(Icons.person_rounded),
                      ),
                      title: Text(peer.name),
                      subtitle: Text(peer.address),
                      trailing: peer.lastRttMs == null
                          ? null
                          : Text('${peer.lastRttMs}ms'),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _joinFromFields(PartySessionController controller) {
    final host = _hostController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? 40440;
    if (host.isEmpty) return;
    controller.joinSessionCandidates(hosts: <String>[host], port: port);
  }

  Future<void> _scanJoinQr() async {
    final code = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.8,
          child: MobileScanner(
            onDetect: (capture) {
              final text = capture.barcodes.first.rawValue;
              if (text == null) return;
              Navigator.of(context).pop(text);
            },
          ),
        );
      },
    );

    if (code == null) return;
    final uri = Uri.tryParse(code);
    final host = uri?.queryParameters['host'];
    final hostsRaw = uri?.queryParameters['hosts'];
    final hosts = (hostsRaw == null || hostsRaw.isEmpty)
        ? <String>[]
        : hostsRaw
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList(growable: false);
    final port = int.tryParse(uri?.queryParameters['port'] ?? '');
    if ((host == null && hosts.isEmpty) || port == null) return;
    final preferredHost = host ?? hosts.first;
    _hostController.text = preferredHost;
    _portController.text = '$port';
    await ref
        .read(partySessionProvider.notifier)
        .joinSessionCandidates(
          hosts: <String>[preferredHost, ...hosts],
          port: port,
        );
  }
}
