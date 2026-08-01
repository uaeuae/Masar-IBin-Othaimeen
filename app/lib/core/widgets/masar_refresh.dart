import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';

/// What a pull actually achieved, so the app can say so.
enum RefreshOutcome { upToDate, updated, failed }

/// Reloads the catalog and rebuilds every query hanging off it.
///
/// There is no server to ask: the catalog is a bundled asset, so this can never
/// bring down lessons that were not already in the build. `meta.json` exists in
/// the publish pipeline and the app has never fetched it — see
/// RELEASE-CHECKLIST. What a pull *can* do is recover a screen that has gone
/// wrong, and that is not hypothetical. A drift stream that throws is delivered
/// to the UI as **absent data**, not as an error, so a single broken query looks
/// exactly like an empty library and stays that way for the life of the process
/// — as one did, when «مساراتي» went blank for everyone who upgraded into a
/// schema that was missing a column. Rebuilding [catalogRepositoryProvider]
/// re-subscribes every stream derived from it.
Future<RefreshOutcome> refreshCatalog(WidgetRef ref) async {
  try {
    final repository = ref.read(catalogRepositoryProvider);
    final before = await repository.currentVersion();
    // Re-imports only if the bundled snapshot is newer than what is stored,
    // which after an app update whose first import failed is the whole point.
    await repository.ensureLoaded();
    final after = await repository.currentVersion();

    ref.invalidate(catalogRepositoryProvider);
    ref.invalidate(catalogVersionProvider);
    ref.invalidate(downloadsProvider);
    return after > before ? RefreshOutcome.updated : RefreshOutcome.upToDate;
  } catch (error) {
    debugPrint('refresh failed: $error');
    return RefreshOutcome.failed;
  }
}

/// Pull-to-refresh, with the outcome said out loud.
///
/// The message is not decoration. «Nothing new» is the *normal* answer here —
/// the catalog ships with the app — and a spinner that simply stops is how a
/// refresh that worked and a refresh that failed look identical.
class MasarRefresh extends ConsumerWidget {
  const MasarRefresh({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    return RefreshIndicator(
      color: scheme.primary,
      backgroundColor: scheme.surfaceContainerLow,
      onRefresh: () async {
        final outcome = await refreshCatalog(ref);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(switch (outcome) {
                RefreshOutcome.updated => 'تم تحديث المحتوى',
                RefreshOutcome.upToDate => 'المحتوى لديك هو الأحدث',
                RefreshOutcome.failed => 'تعذّر التحديث',
              }),
              duration: const Duration(seconds: 2),
            ),
          );
      },
      child: child,
    );
  }
}

/// Makes a state with nothing to scroll pullable anyway.
///
/// [RefreshIndicator] needs overscroll from a scrollable descendant, and the
/// states that most need refreshing — an error, an empty list — are precisely
/// the ones with no list in them. Without this the gesture would work
/// everywhere except where it matters.
class RefreshableMessage extends StatelessWidget {
  const RefreshableMessage({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: child,
      ),
    ),
  );
}
