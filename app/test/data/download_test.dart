import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:masar/data/download_manager.dart';
import 'package:masar/data/download_repository.dart';

import '../support/test_db.dart';

/// Exercises the real HttpClient against a loopback server rather than a hand
/// -rolled fake — the parts worth testing (streaming, progress, the .part
/// rename) all live in that interaction.
void main() {
  late Directory tempDir;
  late HttpServer server;
  late DownloadRepository repository;
  var payload = List<int>.generate(300 * 1024, (i) => i % 256);
  var statusCode = HttpStatus.ok;
  var stallAfterBytes = -1;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('masar-downloads-');
    statusCode = HttpStatus.ok;
    stallAfterBytes = -1;
    payload = List<int>.generate(300 * 1024, (i) => i % 256);

    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      request.response.statusCode = statusCode;
      if (statusCode == HttpStatus.ok) {
        request.response.headers.contentLength = payload.length;
        if (stallAfterBytes >= 0) {
          request.response.add(payload.sublist(0, stallAfterBytes));
          await request.response.flush();
          // Leave the response open: mimics a connection that dies mid-file.
          await Future<void>.delayed(const Duration(milliseconds: 300));
        } else {
          request.response.add(payload);
        }
      }
      await request.response.close();
    });

    repository = DownloadRepository(
      openTestDatabase(),
      directory: () async => tempDir,
    );
  });

  tearDown(() async {
    await server.close(force: true);
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  String url() => 'http://${server.address.address}:${server.port}/lesson.mp3';

  DownloadManager managerAllowing(bool allowed) => DownloadManager(
    repository: repository,
    allowedOnCurrentNetwork: () async => allowed,
  );

  Future<void> settle(DownloadManager manager) async {
    for (var i = 0; i < 200; i++) {
      final status = await repository.status('l1');
      if (status != null && !status.isActive) return;
      await Future<void>.delayed(const Duration(milliseconds: 25));
    }
    fail('download did not settle');
  }

  test('downloads a lesson and reports it as playable offline', () async {
    final manager = managerAllowing(true);
    await manager.download(videoId: 'l1', seriesSlug: 's1', url: url());
    await settle(manager);

    final status = await repository.status('l1');
    expect(status!.state, DownloadState.done);
    expect(status.receivedBytes, payload.length);

    final path = await repository.localPathFor('l1');
    expect(path, isNotNull);
    expect(File(path!).lengthSync(), payload.length);
    // Nothing half-written left behind.
    expect(File('$path.part').existsSync(), isFalse);
  });

  test('refuses to start on a disallowed network', () async {
    final manager = managerAllowing(false);
    await expectLater(
      manager.download(videoId: 'l1', seriesSlug: 's1', url: url()),
      throwsA(isA<DownloadBlockedException>()),
    );
    expect(await repository.status('l1'), isNull);
  });

  test('a server error is recorded, not silently swallowed', () async {
    statusCode = HttpStatus.notFound;
    final manager = managerAllowing(true);
    await manager.download(videoId: 'l1', seriesSlug: 's1', url: url());
    await settle(manager);

    final status = await repository.status('l1');
    expect(status!.state, DownloadState.failed);
    expect(status.error, contains('404'));
    // A failed download must not look playable.
    expect(await repository.localPathFor('l1'), isNull);
  });

  test('deleting removes both the row and the file', () async {
    final manager = managerAllowing(true);
    await manager.download(videoId: 'l1', seriesSlug: 's1', url: url());
    await settle(manager);
    final path = await repository.localPathFor('l1');

    await repository.remove('l1');

    expect(await repository.status('l1'), isNull);
    expect(File(path!).existsSync(), isFalse);
  });

  test('a vanished file stops being reported as downloaded', () async {
    final manager = managerAllowing(true);
    await manager.download(videoId: 'l1', seriesSlug: 's1', url: url());
    await settle(manager);
    File((await repository.fileFor('l1')).path).deleteSync();

    // The row alone must not convince the player to open a missing file.
    expect(await repository.localPathFor('l1'), isNull);
    expect(await repository.status('l1'), isNull);
  });

  test('a series download runs lessons one at a time', () async {
    final manager = managerAllowing(true);
    final added = await manager.downloadAll([
      (videoId: 'l1', seriesSlug: 's1', url: url()),
      (videoId: 'l2', seriesSlug: 's1', url: url()),
      (videoId: 'l3', seriesSlug: 's1', url: url()),
    ]);
    expect(added, 3);

    for (var i = 0; i < 400; i++) {
      final done = await repository.allDone();
      if (done.length == 3) break;
      await Future<void>.delayed(const Duration(milliseconds: 25));
    }
    final done = await repository.allDone();
    expect(done.map((d) => d.videoId).toSet(), {'l1', 'l2', 'l3'});
    expect(await repository.bytesOnDisk(), payload.length * 3);
  });

  test('queueing a lesson twice does not duplicate the work', () async {
    final manager = managerAllowing(true);
    await manager.download(videoId: 'l1', seriesSlug: 's1', url: url());
    await settle(manager);
    final added = await manager.downloadAll([
      (videoId: 'l1', seriesSlug: 's1', url: url()),
    ]);
    expect(added, 0);
  });
}
