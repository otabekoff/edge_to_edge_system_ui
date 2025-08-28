## Publishing Checklist

1. **Update `pubspec.yaml`**
    - Set `publish_to: https://pub.dev`
    - Verify metadata: `homepage`, `repository`, etc.
    - Bump the version and update the changelog.

2. **Validate Package**
    - Run: `flutter pub publish --dry-run`

3. **Publish**
    - Run: `flutter pub publish`

---

## Local Testing

- Run `flutter pub get` from the package root.
- To test the example:
  1. `cd example`
  2. `flutter pub get`
  3. `flutter run`

---

## Notes

- **Android only** is supported.
- Document all changes in the changelog before publishing.

---

## Publishing Notes

Before publishing:

- Ensure `doc/getting_started.md` is present and current (included for pub.dev users).
- Generate API docs with `dart doc` (output to `doc/api`).  
  *Do not check generated docs into source control.*
- Verify the example builds:  
  `cd example && flutter pub get && flutter run`
