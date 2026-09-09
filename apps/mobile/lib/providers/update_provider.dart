import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/updates/github_release_source.dart';
import '../core/updates/update_models.dart';
import '../core/updates/update_service.dart';

final updateServiceProvider = Provider<UpdateService>((_) => UpdateService(const GithubReleaseSource()));
final updateStateProvider = StateProvider<UpdateState>((_) => const UpdateState(UpdateStatus.idle));

final updateControllerProvider = Provider<UpdateController>((ref) => UpdateController(ref));

class UpdateController {
  UpdateController(this.ref);
  final Ref ref;
  Future<UpdateState> check({bool force = false}) async {
    ref.read(updateStateProvider.notifier).state = const UpdateState(UpdateStatus.checking);
    final state = await ref.read(updateServiceProvider).checkForUpdate(force: force);
    ref.read(updateStateProvider.notifier).state = state;
    return state;
  }
}
