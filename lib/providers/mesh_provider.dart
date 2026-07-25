import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/mesh/mesh_service.dart';

final meshServiceProvider = Provider<MeshService>((ref) {
  final service = MeshService();
  
  // Cleanup when provider is disposed
  ref.onDispose(() {
    service.stopAll();
  });
  
  return service;
});

// A simple state class to represent what the Mesh is doing
class MeshState {
  final bool isReady;
  final bool isAdvertising;
  final bool isScanning;
  final int connectedPeersCount;

  MeshState({
    this.isReady = false,
    this.isAdvertising = false,
    this.isScanning = false,
    this.connectedPeersCount = 0,
  });

  MeshState copyWith({
    bool? isReady,
    bool? isAdvertising,
    bool? isScanning,
    int? connectedPeersCount,
  }) {
    return MeshState(
      isReady: isReady ?? this.isReady,
      isAdvertising: isAdvertising ?? this.isAdvertising,
      isScanning: isScanning ?? this.isScanning,
      connectedPeersCount: connectedPeersCount ?? this.connectedPeersCount,
    );
  }
}

class MeshStateNotifier extends StateNotifier<MeshState> {
  final MeshService _meshService;

  MeshStateNotifier(this._meshService) : super(MeshState()) {
    _meshService.connectedPeerCount.addListener(_onPeerCountChanged);
  }

  void _onPeerCountChanged() {
    state = state.copyWith(connectedPeersCount: _meshService.connectedPeerCount.value);
  }

  @override
  void dispose() {
    _meshService.connectedPeerCount.removeListener(_onPeerCountChanged);
    super.dispose();
  }

  Future<void> initializeMesh() async {
    await _meshService.initializeAndStart();
    // For MVP, we assume it started successfully if no exceptions were thrown.
    // In production, we would listen to state streams from the service.
    state = state.copyWith(
      isReady: true,
      isAdvertising: true, // Assuming permissions were granted
      isScanning: true,
    );
  }

  Future<void> stopMesh() async {
    await _meshService.stopAll();
    state = state.copyWith(
      isReady: false,
      isAdvertising: false,
      isScanning: false,
      connectedPeersCount: 0,
    );
  }
}

final meshStateProvider = StateNotifierProvider<MeshStateNotifier, MeshState>((ref) {
  final meshService = ref.watch(meshServiceProvider);
  return MeshStateNotifier(meshService);
});
