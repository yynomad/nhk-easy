import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nhk_easy/data/demo_news.dart';

void main() {
  test(
    'every offline demo audio is playable PCM WAV with nonzero duration',
    () {
      for (final news in demoNews) {
        final file = File(news.assetAudio!);
        expect(file.existsSync(), isTrue, reason: news.id);
        final bytes = file.readAsBytesSync();
        expect(String.fromCharCodes(bytes.sublist(0, 4)), 'RIFF');
        expect(String.fromCharCodes(bytes.sublist(8, 12)), 'WAVE');
        final data = ByteData.sublistView(bytes);
        int? byteRate;
        int? audioBytes;
        for (var offset = 12; offset + 8 <= bytes.length;) {
          final tag = String.fromCharCodes(bytes.sublist(offset, offset + 4));
          final length = data.getUint32(offset + 4, Endian.little);
          expect(offset + 8 + length, lessThanOrEqualTo(bytes.length));
          if (tag == 'fmt ') {
            expect(data.getUint16(offset + 8, Endian.little), 1);
            byteRate = data.getUint32(offset + 16, Endian.little);
          }
          if (tag == 'data') audioBytes = length;
          offset += 8 + length + (length % 2);
        }
        expect(byteRate, isNotNull);
        expect(audioBytes, isNotNull);
        expect(audioBytes! / byteRate!, inInclusiveRange(5, 60));
      }
    },
  );
}
