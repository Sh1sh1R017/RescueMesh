import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/services/hardware_profiler_service.dart';
import '../../domain/services/model_download_service.dart';
import '../../domain/services/llm_inference_service.dart';
import '../../providers/llm_provider.dart';

/// Module D — Setup/Status Screen
///
/// Dark-mode first. Shows:
///   • Device RAM & active model
///   • Per-tier download progress with mesh IP input
///   • Load model button
class LlmSettingsScreen extends ConsumerStatefulWidget {
  const LlmSettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LlmSettingsScreen> createState() => _LlmSettingsScreenState();
}

class _LlmSettingsScreenState extends ConsumerState<LlmSettingsScreen> {
  final TextEditingController _urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _urlController.text = ref.read(meshUrlProvider);
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hardwareAsync = ref.watch(hardwareProfileProvider);
    final activeTier = ref.watch(activeTierProvider);
    final loaderState = ref.watch(modelLoaderProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0F12),
      appBar: AppBar(
        title: const Text('LLM Engine Settings'),
        backgroundColor: const Color(0xFF111318),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFF2A2D35), height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHardwareCard(hardwareAsync),
            const SizedBox(height: 16),
            _buildActiveModelCard(activeTier, loaderState),
            const SizedBox(height: 16),
            _buildMeshUrlCard(),
            const SizedBox(height: 16),
            _buildSectionLabel('MODEL PACKS'),
            const SizedBox(height: 8),
            _buildModelTileForTier(
              tier: ModelTier.base,
              title: 'Base Model (0.5B) — Failsafe',
              subtitle: 'Qwen2.5-0.5B-Instruct-Q4_K_M • ~490 MB',
              minRam: '2 GB RAM minimum',
              hardwareAsync: hardwareAsync,
            ),
            _buildModelTileForTier(
              tier: ModelTier.enhancement1,
              title: 'Enhancement Pack 1 (1.5B)',
              subtitle: 'Qwen2.5-1.5B-Instruct-Q4_K_M • ~1.1 GB',
              minRam: '6 GB RAM required',
              hardwareAsync: hardwareAsync,
            ),
            _buildModelTileForTier(
              tier: ModelTier.enhancement2,
              title: 'Enhancement Pack 2 (3B)',
              subtitle: 'Qwen2.5-3B-Instruct-Q4_K_M • ~1.9 GB',
              minRam: '8 GB RAM required',
              hardwareAsync: hardwareAsync,
            ),
            const SizedBox(height: 24),
            _buildLoadButton(hardwareAsync, loaderState),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHardwareCard(AsyncValue<HardwareProfile> hardwareAsync) {
    return _DarkCard(
      child: hardwareAsync.when(
        loading: () => const _LoadingRow(label: 'Profiling device hardware...'),
        error: (e, _) => _ErrorRow(message: e.toString()),
        data: (profile) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionLabel('DEVICE HARDWARE'),
            const SizedBox(height: 12),
            _InfoRow(label: 'Device', value: profile.deviceModel),
            _InfoRow(
              label: 'Total RAM',
              value: '${profile.totalRamGb.toStringAsFixed(1)} GB',
              valueColor: _ramColor(profile.totalRamGb),
            ),
            _InfoRow(
              label: 'CPU Cores',
              value: '${profile.physicalCoreCount} physical '
                  '(${profile.llamaThreadCount} for LLM)',
            ),
            _InfoRow(
              label: 'Max Supported Tier',
              value: HardwareProfilerService.tierLabel(profile.maxAllowedTier),
              valueColor: _tierColor(profile.maxAllowedTier),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveModelCard(
      ModelTier activeTier, AsyncValue<void> loaderState) {
    final tierLabel = HardwareProfilerService.tierLabel(activeTier);
    final inferState = ref.watch(inferenceStateProvider);

    return _DarkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel('ACTIVE MODEL'),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _tierColor(activeTier).withValues(alpha: 0.15),
                  border: Border.all(color: _tierColor(activeTier)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'QWEN2.5 · $tierLabel',
                  style: TextStyle(
                    color: _tierColor(activeTier),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              inferState.when(
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
                data: (s) => _StatusDot(status: s.status),
              ),
            ],
          ),
          inferState.when(
            loading: () => const SizedBox(),
            error: (e, _) => const SizedBox(),
            data: (s) {
              if (s.loadProgressMessage.isNotEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    s.loadProgressMessage,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                );
              }
              if (s.errorMessage != null) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    s.errorMessage!,
                    style: const TextStyle(color: Color(0xFFFF5252), fontSize: 12),
                  ),
                );
              }
              return const SizedBox();
            },
          ),
          if (loaderState.isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: LinearProgressIndicator(
                backgroundColor: Color(0xFF2A2D35),
                color: Color(0xFF00E5FF),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMeshUrlCard() {
    return _DarkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel('MESH DOWNLOAD SOURCE'),
          const SizedBox(height: 4),
          const Text(
            'Enter the IP of your local mesh router / file server.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _urlController,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'monospace',
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: 'http://192.168.4.1:8080/models/',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
              filled: true,
              fillColor: const Color(0xFF1A1D24),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFF2A2D35)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFF2A2D35)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFF00E5FF)),
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.check_circle_outline,
                    color: Color(0xFF00E5FF)),
                tooltip: 'Apply URL',
                onPressed: () {
                  ref
                      .read(meshUrlProvider.notifier)
                      .setUrl(_urlController.text.trim());
                  FocusScope.of(context).unfocus();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Mesh URL updated'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildModelTileForTier({
    required ModelTier tier,
    required String title,
    required String subtitle,
    required String minRam,
    required AsyncValue<HardwareProfile> hardwareAsync,
  }) {
    final downloadState = ref.watch(downloadStateProvider(tier));
    final downloader = ref.read(modelDownloadServiceProvider);

    final bool locked = hardwareAsync.when(
      data: (p) => p.maxAllowedTier.index < tier.index,
      loading: () => true,
      error: (_, __) => true,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _DarkCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: locked ? Colors.grey : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 11),
                      ),
                      if (locked)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '🔒 $minRam',
                            style: const TextStyle(
                                color: Color(0xFFFF5252), fontSize: 11),
                          ),
                        ),
                    ],
                  ),
                ),
                downloadState.when(
                  loading: () => const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (_, __) => const SizedBox(),
                  data: (state) =>
                      _buildDownloadButton(tier, state, downloader, locked),
                ),
              ],
            ),
            downloadState.when(
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
              data: (state) {
                if (state.status == DownloadStatus.complete) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle,
                            color: Color(0xFF69FF47), size: 14),
                        SizedBox(width: 6),
                        Text(
                          'Downloaded • Ready to load',
                          style: TextStyle(
                              color: Color(0xFF69FF47), fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }
                if (state.status == DownloadStatus.downloading ||
                    state.status == DownloadStatus.paused) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: state.progress,
                            backgroundColor: const Color(0xFF2A2D35),
                            color: state.status == DownloadStatus.paused
                                ? Colors.orange
                                : const Color(0xFF00E5FF),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(state.progress * 100).toStringAsFixed(1)}% '
                          '${state.status == DownloadStatus.paused ? '— Paused' : ''}',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 11),
                        ),
                        if (state.errorMessage != null)
                          Text(
                            state.errorMessage!,
                            style: const TextStyle(
                                color: Color(0xFFFF5252), fontSize: 11),
                          ),
                      ],
                    ),
                  );
                }
                if (state.status == DownloadStatus.error) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '⚠️ ${state.errorMessage ?? 'Download error'}',
                      style: const TextStyle(
                          color: Color(0xFFFF5252), fontSize: 11),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadButton(
    ModelTier tier,
    DownloadState state,
    ModelDownloadService downloader,
    bool locked,
  ) {
    if (locked) {
      return const Icon(Icons.lock_outline, color: Colors.grey, size: 20);
    }
    switch (state.status) {
      case DownloadStatus.idle:
      case DownloadStatus.error:
        return IconButton(
          tooltip: 'Download from Mesh',
          icon: const Icon(Icons.download_rounded, color: Color(0xFF00E5FF)),
          onPressed: () => downloader.startDownload(tier),
        );
      case DownloadStatus.downloading:
        return IconButton(
          tooltip: 'Pause',
          icon: const Icon(Icons.pause_circle_outline,
              color: Colors.orange),
          onPressed: () => downloader.pauseDownload(tier),
        );
      case DownloadStatus.paused:
        return IconButton(
          tooltip: 'Resume',
          icon: const Icon(Icons.play_circle_outline,
              color: Color(0xFF00E5FF)),
          onPressed: () => downloader.startDownload(tier),
        );
      case DownloadStatus.complete:
        return IconButton(
          tooltip: 'Delete local file',
          icon: const Icon(Icons.delete_outline, color: Colors.grey),
          onPressed: () => downloader.cancelDownload(tier),
        );
    }
  }

  Widget _buildLoadButton(
    AsyncValue<HardwareProfile> hardwareAsync,
    AsyncValue<void> loaderState,
  ) {
    final isLoading = loaderState.isLoading;
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00E5FF),
          foregroundColor: Colors.black,
          disabledBackgroundColor: const Color(0xFF2A2D35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        icon: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.black),
              )
            : const Icon(Icons.memory),
        label: Text(
          isLoading ? 'Loading model...' : 'Load Best Available Model',
          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        onPressed: isLoading
            ? null
            : () {
                final profile = hardwareAsync.value;
                final tier = profile?.maxAllowedTier ?? ModelTier.base;
                ref.read(modelLoaderProvider.notifier).loadModel(tier);
              },
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFF00E5FF),
        fontWeight: FontWeight.bold,
        fontSize: 11,
        letterSpacing: 1.4,
      ),
    );
  }

  Color _ramColor(double gb) {
    if (gb >= 8) return const Color(0xFF69FF47);
    if (gb >= 6) return Colors.orange;
    if (gb >= 4) return Colors.yellow;
    return const Color(0xFFFF5252);
  }

  Color _tierColor(ModelTier tier) {
    switch (tier) {
      case ModelTier.base:
        return Colors.orange;
      case ModelTier.enhancement1:
        return const Color(0xFF00E5FF);
      case ModelTier.enhancement2:
        return const Color(0xFF69FF47);
    }
  }
}

// ─────────────────────────────────────────────
// Reusable dark-theme widgets
// ─────────────────────────────────────────────

class _DarkCard extends StatelessWidget {
  final Widget child;
  const _DarkCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111318),
        border: Border.all(color: const Color(0xFF2A2D35)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingRow extends StatelessWidget {
  final String label;
  const _LoadingRow({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: Color(0xFF00E5FF)),
        ),
        const SizedBox(width: 12),
        Text(label,
            style: const TextStyle(color: Colors.grey, fontSize: 13)),
      ],
    );
  }
}

class _ErrorRow extends StatelessWidget {
  final String message;
  const _ErrorRow({required this.message});

  @override
  Widget build(BuildContext context) {
    return Text(
      '⚠️ $message',
      style: const TextStyle(color: Color(0xFFFF5252), fontSize: 12),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final InferenceStatus status;
  const _StatusDot({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case InferenceStatus.ready:
        color = const Color(0xFF69FF47);
        label = 'READY';
        break;
      case InferenceStatus.inferring:
        color = const Color(0xFF00E5FF);
        label = 'THINKING';
        break;
      case InferenceStatus.loading:
        color = Colors.orange;
        label = 'LOADING';
        break;
      case InferenceStatus.error:
        color = const Color(0xFFFF5252);
        label = 'ERROR';
        break;
      case InferenceStatus.unloaded:
        color = Colors.grey;
        label = 'UNLOADED';
        break;
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8),
        ),
      ],
    );
  }
}
