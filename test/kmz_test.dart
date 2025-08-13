import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:test/test.dart';

void main() async {
  group('kmz', () {
    test('decode encode', () async {
      final archive = ZipDecoder().decodeStream(
          InputMemoryStream(File('test/_data/kmz/test.kmz').readAsBytesSync()));

      final zipBytes = ZipEncoder().encodeBytes(archive);

      final archive2 = ZipDecoder().decodeBytes(zipBytes);

      expect(archive.length, archive2.length);
    });
  });
}
