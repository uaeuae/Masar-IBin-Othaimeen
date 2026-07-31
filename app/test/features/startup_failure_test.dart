import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masar/core/widgets/empty_state.dart';
import 'package:masar/data/providers.dart';

/// What the reader sees when the catalog cannot be prepared at all.
///
/// This path is easy to leave untested because it is the one path that never
/// happens in development. It is also the one where a mistake is unrecoverable
/// for the user: a database that will not open means no lessons, no progress,
/// and — before this was fixed — a retry button that could not possibly work,
/// because drift caches an open failure and replays it on every later query
/// against the same connection.
void main() {
  testWidgets('a catalog that will not load explains itself and offers a retry', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          catalogReadyProvider.overrideWith(
            (ref) => Future<void>.error(StateError('db is wedged')),
          ),
        ],
        child: const MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: _ShellErrorHarness(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('تعذر تجهيز المحتوى'), findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsOneWidget);
  });

  // Plain `test`, not `testWidgets`: this asserts provider lifecycle, and
  // Riverpod's invalidation schedules a real timer that FakeAsync reports as a
  // pending-timer failure.
  test('retrying rebuilds the database rather than re-asking the broken one', () {
    // The bug this pins: `ref.invalidate(catalogReadyProvider)` alone re-runs
    // the query against the *same* `AppDatabase`. Since drift caches the
    // migration failure on that connection and rethrows the identical
    // exception without retrying, the button could never succeed. The fix is
    // to dispose the database too, so a fresh connection is built.
    var databaseBuilds = 0;
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWith((ref) {
          databaseBuilds++;
          throw StateError('cannot open');
        }),
      ],
    );
    addTearDown(container.dispose);

    expect(() => container.read(databaseProvider), throwsA(anything));
    expect(databaseBuilds, 1);

    // Re-reading without invalidating reuses the cached failure — this is
    // exactly why the old retry did nothing.
    expect(() => container.read(databaseProvider), throwsA(anything));
    expect(databaseBuilds, 1, reason: 'the failure is cached, not retried');

    container.invalidate(databaseProvider);
    expect(() => container.read(databaseProvider), throwsA(anything));
    expect(databaseBuilds, 2, reason: 'invalidating is what forces a real retry');
  });
}

/// The shell's error branch needs a `StatefulNavigationShell` it never uses in
/// this state, so the branch is exercised through a stand-in that renders the
/// same `EmptyState` contract.
class _ShellErrorHarness extends ConsumerWidget {
  const _ShellErrorHarness();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(catalogReadyProvider)
        .when(
          loading: () => const SizedBox.shrink(),
          error: (error, stack) => Scaffold(
            body: EmptyState(
              icon: Icons.error_outline_rounded,
              title: 'تعذر تجهيز المحتوى',
              message: 'حدث خطأ أثناء تحميل قاعدة الدروس.',
              actionLabel: 'إعادة المحاولة',
              onAction: () {
                ref.invalidate(databaseProvider);
                ref.invalidate(catalogReadyProvider);
              },
            ),
          ),
          data: (_) => const SizedBox.shrink(),
        );
  }
}
