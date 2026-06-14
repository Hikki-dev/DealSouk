import 'package:dealsouk/core/widgets/avatar_image.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('avatarImageProvider', () {
    test('returns null for null or empty', () {
      expect(avatarImageProvider(null), isNull);
      expect(avatarImageProvider(''), isNull);
    });

    test(
      'returns a NetworkImage for an http(s) URL (Google photo / uploaded)',
      () {
        final p = avatarImageProvider(
          'https://lh3.googleusercontent.com/a/x.jpg',
        );
        expect(p, isA<NetworkImage>());
        expect(
          (p as NetworkImage).url,
          'https://lh3.googleusercontent.com/a/x.jpg',
        );

        expect(
          avatarImageProvider('http://example.com/a.png'),
          isA<NetworkImage>(),
        );
      },
    );

    test('returns a FileImage for a local path (on-device demo avatar)', () {
      // Tests run on the Dart VM (not web), so local file paths resolve to FileImage.
      final p = avatarImageProvider('/var/mobile/tmp/avatar.jpg');
      expect(p, isA<FileImage>());
      expect((p as FileImage).file.path, '/var/mobile/tmp/avatar.jpg');
    });
  });
}
