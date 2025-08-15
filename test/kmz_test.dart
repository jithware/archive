// ignore_for_file: avoid_print

import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() async {
  group('kmz', () {
    String kmzDataDir = 'test/_data/kmz';
    List<String> kmzTestFiles = ['test.kmz', 'test2.kmz'];

    test('decode and encode file', () async {
      final archive = ZipDecoder().decodeStream(InputMemoryStream(
          File('$kmzDataDir/${kmzTestFiles[0]}').readAsBytesSync()));

      final kmzBytes = ZipEncoder().encodeBytes(archive);

      final archive2 = ZipDecoder().decodeBytes(kmzBytes);

      expect(archive.length, archive2.length);
    });

    test('extract and recreate same file', () async {
      final kmzOutDir = '$kmzDataDir/_out';
      if (await Directory('$kmzOutDir').exists()) {
        await Directory('$kmzOutDir').delete(recursive: true);
      }

      for (int i = 0; i < kmzTestFiles.length; i++) {
        final kmzOutFile = '$kmzOutDir/${kmzTestFiles[i]}';
        final kmzTestDir =
            "$kmzOutDir/${p.basenameWithoutExtension(kmzTestFiles[i])}";

        final kmzBytes =
            File('$kmzDataDir/${kmzTestFiles[i]}').readAsBytesSync();
        final archive = ZipDecoder().decodeBytes(kmzBytes);

        // extract files from kmz
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

        // zip extracted directory
        var encoder = ZipFileEncoder();
        await encoder.zipDirectory(Directory('$kmzTestDir'),
            filename: '$kmzOutFile');

        // decode the archive we just encoded
        final outBytes = File('$kmzOutFile').readAsBytesSync();
        final archive2 = ZipDecoder().decodeBytes(outBytes, verify: true);

        expect(archive2.length, equals(archive.length));
        for (var i = 0; i < archive2.length; ++i) {
          expect(archive2[i].name, equals(archive[i].name));
          expect(archive2[i].size, equals(archive[i].size));
        }

        print(
            'Create a map at: https://www.google.com/maps/d/ and import $kmzOutFile.');
      }
    });
  });
}
