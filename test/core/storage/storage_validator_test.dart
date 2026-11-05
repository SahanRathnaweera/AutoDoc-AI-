import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:autodoc_ai/core/error/exceptions.dart';
import 'package:autodoc_ai/core/storage/storage_validator.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('storage_test_');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('StorageValidator.validateImage', () {
    test('returns image/jpeg for .jpg and .jpeg files', () {
      final file = File('${tempDir.path}/car.jpg')..writeAsBytesSync([1, 2, 3]);
      expect(StorageValidator.validateImage(file), 'image/jpeg');
    });

    test('returns image/png for .png files', () {
      final file = File('${tempDir.path}/car.png')..writeAsBytesSync([1, 2, 3]);
      expect(StorageValidator.validateImage(file), 'image/png');
    });

    test('throws StorageException for invalid extension', () {
      final file = File('${tempDir.path}/car.exe')..writeAsBytesSync([1, 2, 3]);
      expect(
        () => StorageValidator.validateImage(file),
        throwsA(isA<StorageException>().having((e) => e.code, 'code', 'invalid-mime-type')),
      );
    });

    test('throws StorageException if file does not exist', () {
      final file = File('${tempDir.path}/missing.jpg');
      expect(
        () => StorageValidator.validateImage(file),
        throwsA(isA<StorageException>().having((e) => e.code, 'code', 'object-not-found')),
      );
    });
  });

  group('StorageValidator.validateAudio', () {
    test('returns audio/wav for .wav file', () {
      final file = File('${tempDir.path}/engine.wav')..writeAsBytesSync([1, 2, 3]);
      expect(StorageValidator.validateAudio(file), 'audio/wav');
    });

    test('returns audio/mpeg for .mp3 file', () {
      final file = File('${tempDir.path}/engine.mp3')..writeAsBytesSync([1, 2, 3]);
      expect(StorageValidator.validateAudio(file), 'audio/mpeg');
    });

    test('throws StorageException for unsupported audio', () {
      final file = File('${tempDir.path}/engine.txt')..writeAsBytesSync([1, 2, 3]);
      expect(
        () => StorageValidator.validateAudio(file),
        throwsA(isA<StorageException>().having((e) => e.code, 'code', 'invalid-mime-type')),
      );
    });
  });

  group('StorageValidator.validateDocument', () {
    test('returns application/pdf for .pdf files', () {
      final file = File('${tempDir.path}/reg.pdf')..writeAsBytesSync([1, 2, 3]);
      expect(StorageValidator.validateDocument(file), 'application/pdf');
    });

    test('throws StorageException for invalid document type', () {
      final file = File('${tempDir.path}/doc.zip')..writeAsBytesSync([1, 2, 3]);
      expect(
        () => StorageValidator.validateDocument(file),
        throwsA(isA<StorageException>().having((e) => e.code, 'code', 'invalid-mime-type')),
      );
    });
  });
}
