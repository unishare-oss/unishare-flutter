import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'guest_mode_provider.g.dart';

@Riverpod(keepAlive: true)
class GuestMode extends _$GuestMode {
  @override
  bool build() => false;

  void enter() => state = true;

  void exit() => state = false;
}
