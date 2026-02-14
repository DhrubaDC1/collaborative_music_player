import 'package:collaborative_music_player/core/widgets/glass_panel.dart';
import 'package:collaborative_music_player/design_system/accessibility/reduced_motion.dart';
import 'package:collaborative_music_player/design_system/components/glass_button.dart';
import 'package:collaborative_music_player/design_system/components/glass_input.dart';
import 'package:collaborative_music_player/design_system/components/status_pill.dart';
import 'package:collaborative_music_player/services/party/party_models.dart';
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
    final reducedMotion = prefersReducedMotion(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: ListView(
        children: [
          const SizedBox(height: 12),
          Text(
            'Party Session',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusPill(
                label: state.status.name.toUpperCase(),
                tone: switch (state.status) {
                  PartyConnectionStatus.connected => StatusTone.success,
                  PartyConnectionStatus.hosting => StatusTone.warning,
                  PartyConnectionStatus.error => StatusTone.error,
                  _ => StatusTone.info,
                },
              ),
              if (state.isConnected)
                StatusPill(
                  label: 'Peers ${state.peers.length}',
                  tone: StatusTone.info,
                ),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedContainer(
            duration: reducedMotion
                ? Duration.zero
                : const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: GlassPanel(
              radius: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Host or Join',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      GlassButton(
                        onPressed: state.isConnected
                            ? null
                            : () => controller.createSession(),
                        icon: Icons.campaign_rounded,
                        label: 'Create Party',
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
                  GlassInput(
                    controller: _hostController,
                    hint: '192.168.x.x',
                    label: 'Host IP',
                  ),
                  const SizedBox(height: 10),
                  GlassInput(
                    controller: _portController,
                    hint: '40440',
                    label: 'Port',
                  ),
                  if (state.message != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      state.message!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (state.isHost && controller.joinPayload.isNotEmpty) ...[
            const SizedBox(height: 16),
            GlassPanel(
              radius: 24,
              child: Column(
                children: [
                  Text(
                    'Invite with QR',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  QrImageView(data: controller.joinPayload, size: 220),
                  const SizedBox(height: 8),
                  SelectableText(controller.joinPayload),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          RepaintBoundary(
            child: GlassPanel(
              radius: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Participants',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  if (state.peers.isEmpty)
                    const Text('No guests connected yet.')
                  else
                    ...state.peers.map(
                      (peer) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GlassPanel(
                          blur: 10,
                          radius: 18,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              const CircleAvatar(
                                child: Icon(Icons.person_rounded, size: 18),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(peer.name),
                                    Text(
                                      peer.address,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              if (peer.lastRttMs != null)
                                StatusPill(
                                  label: '${peer.lastRttMs}ms',
                                  tone: peer.lastRttMs! < 80
                                      ? StatusTone.success
                                      : StatusTone.warning,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
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
