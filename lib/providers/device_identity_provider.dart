import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final deviceIdentityProvider = Provider<String>((ref) {
  // Generate a simple random node ID for this session
  final random = Random();
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  return String.fromCharCodes(Iterable.generate(
    8, (_) => chars.codeUnitAt(random.nextInt(chars.length))
  ));
});
