# Expense Manager App

Project Flutter quản lý chi tiêu cá nhân, đã setup theo scope UI/UX & Profile.

- `lib/core/theme`: Theme configuration (colors, typography)
- `lib/core/utils`: Formatters & utility functions
- `lib/data/models`: Data models
- `lib/data/services`: Business logic / state
- `lib/presentation/navigation`: Bottom navigation & routing
- `lib/presentation/profile`: Profile & settings screens
- `lib/presentation/shared`: Shared widgets & components
- `lib/presentation/home`: Expense home flow

## Run project

```bash
flutter pub get
flutter run
```

## Team Rules

Chi tiết đầy đủ nằm trong [TEAM_GUIDELINES.md](TEAM_GUIDELINES.md).

Quick rules:

- Rebase thường xuyên, tách file theo folder để giảm conflict.
- Không commit API keys; dùng `.env` hoặc environment variables.
- Chạy `flutter analyze` và `dart fix --apply` trước commit.
- Tuân thủ naming conventions, tránh nested widget sâu.
- Dispose đúng `streams`, `listeners`, `controllers`.
- Tránh operation nặng trong `build()`.

## Communication

- Slack/Teams: Daily standup 9:30 AM
- GitHub Issues: Track bugs & tasks
- Code Review: 24 hour response time
- Weekly sync: Every Friday 3 PM
