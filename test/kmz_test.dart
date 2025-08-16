// ignore_for_file: avoid_print

import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() async {
  final kmzDataDir = 'test/_data/kmz';
  final kmzOutDir = '$kmzDataDir/_out';
  List<String> kmzTestFiles = ['test.kmz', 'test2.kmz'];
  List<String> kmzOutFiles = [];

  setUpAll(() async {
    if (await Directory('$kmzOutDir').exists()) {
      await Directory('$kmzOutDir').delete(recursive: true);
    }
    // extract all test files
    for (int i = 0; i < kmzTestFiles.length; i++) {
      final kmzTestDir =
          "$kmzOutDir/${p.basenameWithoutExtension(kmzTestFiles[i])}";
      final archive = ZipDecoder().decodeBytes(
          File('$kmzDataDir/${kmzTestFiles[i]}').readAsBytesSync());

      // extract files and directories from kmz
      for (final file in archive) {
        final filename = file.name;
        if (file.isFile) {
          final data = file.content as List<int>;
          File('$kmzTestDir/' + filename)
            ..createSync(recursive: true)
            ..writeAsBytesSync(data);
        } else {
          await Directory('$kmzTestDir/' + filename).create(recursive: true);
        }
      }
    }
  });

  tearDownAll(() async {
    print(
        'Create a map at: https://www.google.com/maps/d/ and test importing $kmzOutFiles.');
  });

  group('kmz', () {
    test('can be encoded and decoded', () async {
      final archive = ZipDecoder().decodeStream(InputMemoryStream(
          File('$kmzDataDir/${kmzTestFiles[0]}').readAsBytesSync()));

      final kmzBytes = ZipEncoder().encodeBytes(archive);

      final archive2 = ZipDecoder().decodeBytes(kmzBytes);

      expect(archive.length, archive2.length);
    });

    test('can recreate same file', () async {
      for (int i = 0; i < kmzTestFiles.length; i++) {
        final newKmzFile = '$kmzOutDir/${kmzTestFiles[i]}';
        final kmzTestDir =
            "$kmzOutDir/${p.basenameWithoutExtension(kmzTestFiles[i])}";

        final originalArchive = ZipDecoder().decodeBytes(
            File('$kmzDataDir/${kmzTestFiles[i]}').readAsBytesSync());

        // zip extracted directory
        var encoder = ZipFileEncoder();
        await encoder.zipDirectory(Directory('$kmzTestDir'),
            filename: '$newKmzFile');

        // decode the archive we just encoded
        final newArchive = ZipDecoder()
            .decodeBytes(File('$newKmzFile').readAsBytesSync(), verify: true);

        expect(newArchive.length, equals(originalArchive.length));
        for (var i = 0; i < newArchive.length; ++i) {
          expect(newArchive[i].name, equals(originalArchive[i].name));
          expect(newArchive[i].size, equals(originalArchive[i].size));
        }

        kmzOutFiles.add(newKmzFile);
      }
    });

    test('can recreate same file with no directories', () async {
      final newKmzFile = '$kmzOutDir/test3.kmz';
      final kmzTestDir =
          "$kmzOutDir/${p.basenameWithoutExtension(kmzTestFiles[0])}";

      final originalArchive = ZipDecoder().decodeBytes(
          File('$kmzDataDir/${kmzTestFiles[0]}').readAsBytesSync());

      // zip extracted directory without directories
      var encoder = ZipFileEncoder();
      await encoder.zipDirectory(Directory('$kmzTestDir'),
          filename: '$newKmzFile',
          filter: (entity, _) => entity is Directory
              ? ZipFileOperation.skip
              : ZipFileOperation.include);

      // decode the archive we just encoded
      final newArchive = ZipDecoder()
          .decodeBytes(File('$newKmzFile').readAsBytesSync(), verify: true);

      expect(newArchive.length, equals(originalArchive.length - 1));

      kmzOutFiles.add(newKmzFile);
    });
  });
}
