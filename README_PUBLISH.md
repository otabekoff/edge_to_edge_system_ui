Publishing checklist

1. Update `pubspec.yaml`: set `publish_to: https://pub.dev` and verify metadata (homepage, repository).
2. Run `flutter pub publish --dry-run` to validate.
3. Run `flutter pub publish` to publish.

Testing locally

- From package root, run `flutter pub get`.
- To run the example: `cd example` then `flutter pub get` and `flutter run`.

Notes

- Ensure you bump the version and add changelog entry before publishing.
- The plugin currently implements Android only.
