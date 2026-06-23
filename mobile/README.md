# Manasety Mobile Apps

Two Flutter apps that consume the Manasety REST API:

- **teacher_app/** — for teachers: attendance, grades, materials, schedule
- **parent_app/** — for parents: track children's attendance, results, fees

## API
Full endpoint reference: [API.md](API.md).

## Quick start

```bash
cd teacher_app
flutter pub get
flutter run --dart-define=API_BASE=https://manasety-school.sd/api
```

The scaffolds here are minimal Dart stubs (auth flow + 1-2 screens per app). They establish:
- HTTP client with JWT injection
- Token persistence via `shared_preferences`
- Arabic RTL layout + Cairo font
- Brand colors (navy `#1B3A5C`, orange `#F39C2F`)

To get a full production app, follow the screens listed in the PDF backlog (T-10.2 / T-10.3):
- Teacher: login → schedule → today's classes → attendance per class → grade entry → materials upload
- Parent: login → children list → per-child tabs (attendance / results / fees / materials) → notifications
