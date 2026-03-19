# Team Guidelines

## 1) Git Workflow

- `main`: production only, no direct push.
- `develop`: integration branch.
- `feature/{name}/{feature-name}`: feature development.
- `fix/{name}/{bug-name}`: bug fixing.
- Commit format: `[TYPE] (name): short description`.

## 2) Branch Strategy (UI/UX Owner)

- `feature/theme-design-system`
- `feature/profile-settings`
- `feature/shared-components`

## 3) File Organization Ownership

```text
lib/
├── data/
│   ├── models/
│   ├── services/
│   └── repositories/
├── providers/
└── presentation/
    ├── auth/
    ├── transactions/
    ├── statistics/
    ├── ai_advice/
    ├── profile/
    ├── navigation/
    ├── shared/
    └── theme/
```

Rule: mỗi người chủ yếu làm trong folder ownership của mình, tránh sửa chéo không PR.

## 4) Coding Standards

- Public API cần doc comments.
- Function nên ngắn, ưu tiên tách nhỏ nếu quá dài.
- Line length tối đa 100 ký tự.
- Imports được tổ chức rõ ràng.
- Error handling bắt buộc với async/network code.
- Chạy trước commit:
  - `flutter analyze`
  - `dart fix --apply`

## 5) PR Flow (Bắt buộc)

1. Tạo branch từ `develop`.
2. Commit + push branch feature.
3. Tạo PR vào `develop`.
4. Code review 1-2 người.
5. Merge bằng `Squash and merge`.
6. Xóa branch cũ.

## 6) Conflict Resolution

- Luôn pull `develop` mới nhất.
- Rebase feature branch lên `develop`.
- Resolve conflict, `git rebase --continue`.
- Force push chỉ cho feature branch (`--force-with-lease`).
- Không rebase `main` hoặc `develop`.

## 7) Dependency Management

- Không update dependencies tùy tiện.
- Cần update thì trao đổi team lead trước.
- Kiểm tra bằng:
  - `flutter pub get`
  - `flutter pub outdated`

## 8) Security

- Không commit API keys/secrets.
- Dùng `.env`, Remote Config, hoặc environment variables.
- Bảo vệ các file nhạy cảm bằng `.gitignore`.

## 9) Testing & Quality

- Có test cho business logic.
- Lint sạch trước khi mở PR.

## 10) Code Review Checklist

- Code style đúng naming/import/line length.
- Feature đúng spec, xử lý edge cases.
- Không memory leak, không loop vô hạn.
- Không hardcode dữ liệu nhạy cảm.
- README/documentation cập nhật khi cần.

## Timeline & Milestone

| Week | Milestone | Owner |
|---|---|---|
| 1 | Project setup, Firebase config | TÙNG |
| 1-2 | Auth screens & logic | TÙNG |
| 2 | Transaction CRUD | AN |
| 2-3 | Charts & Statistics | AN |
| 3 | AI Chatbot integration | LINH |
| 3-4 | Chatbot UI & animations | HÙNG |
| 4 | Profile & Settings | KIỆT |
| 4-5 | Integration & Testing | ALL |
| 5 | Bug fixes & Polish | ALL |
| 5-6 | Deployment & Release | TÙNG |

## Communication

- Slack/Teams: Daily standup 9:30 AM
- GitHub Issues: Track bugs & tasks
- Code Review SLA: 24 hours
- Weekly sync: Friday 3 PM

## Common Pitfalls

| Problem | Solution |
|---|---|
| Merge conflicts | Rebase thường xuyên, tách file theo folder |
| API key leak | Dùng `.env`, Remote Config, hoặc environment variables |
| Unused imports | Chạy `dart fix --apply` trước commit |
| Inconsistent naming | Follow naming conventions chặt chẽ |
| Deep widget nesting | Extract widgets thành separate classes |
| Memory leaks | Dispose streams, listeners, controllers đúng cách |
| UI lag | Tránh phép tính nặng trong `build()` |
