# Lane Files — Templates

All four live in `<project-root>/.crewmarshal/lanes/<name>/`. Prose stays in the
project's working language. Each file has one writer.

## charter.md — Chief writes

```markdown
# Lane: <tên>

**Cập nhật:** YYYY-MM-DD
**Project root:** <đường dẫn tuyệt đối> · **Nhánh:** lane/<tên>
**Cách chạy:** <headless | tương tác — phiên Chief: <tên trong ListAgents>; Chief cập nhật dòng này khi mở phiên mới>
**Repo và worktree:**
- <repo> @<sha main lúc mở> → <project-root>/.crewmarshal/worktrees/<tên>/<repo>

## Phạm vi
- Được ghi: <repo>/<thư mục>
- Chỉ đọc: <thư mục>
- Commons (xin Chief, không tự sửa): <lockfile, CI, lib chung, contract…>

## Contract
- Cung cấp: <file contract>
- Dùng: <file contract>

## Tài liệu chung cần đọc
- <file> — <mục nào>   ← chỉ phần lane cần, không nạp tất cả

## Luật riêng của lane (chỉ siết thêm so với working-agreement)
- <vd: mọi task qua adversarial review>

## Executor pool
- <agent> — <vai trò>   ← tập con của team.md

## Lệnh
- Test: <lệnh> · Build: <lệnh>
```

## STATUS.md — lane writes

The `pointer-handoff` format, plus one line at the top:

```markdown
**Inbox đã xử lý tới:** #<n>
```

*Đang dở* lists every detached job: `id · task · executor · jobs/<id>.exit`.

## inbox.md — Chief writes, append only

```markdown
## #<n> · YYYY-MM-DD · <giao việc | trả lời #<outbox n> | contract đổi | tài liệu chung đổi | tìm điểm dừng>
<nội dung; với thay đổi tài liệu chung/contract: đổi gì, @sha nếu có version>
```

## outbox.md — lane writes, append only

```markdown
## #<n> · YYYY-MM-DD · <sẵn sàng tích hợp | câu hỏi | escalation | quyết định | đề xuất bài học | chờ job | reset>
<sẵn sàng: <repo>@sha cho từng repo, test x/y
 câu hỏi: câu hỏi, các phương án, đề xuất của lane
 escalation: cần gì, bằng chứng
 quyết định (lane tương tác): user chốt gì trong cửa sổ lane, ảnh hưởng tới đâu
 đề xuất bài học: theo mẫu lessons-ledger
 chờ job: danh sách id
 reset: lý do>
```

## Lane-run prompt — what the Chief hands each run

```
Bạn là coordinator của lane <tên>, chạy headless, không có người dùng.
Làm theo skill multi-lane-coordination, mục "A Lane Run".
Charter: $CREWMARSHAL_PROJECT_ROOT/.crewmarshal/lanes/$CREWMARSHAL_LANE/charter.md
Gặp quyết định vượt charter: ghi outbox, dừng — không đoán.
```

Interactive lanes — the prompt inside `launch.sh`:

```
Bạn là coordinator của lane <tên>, chạy trong cửa sổ riêng, user có thể xem và trả lời.
Làm theo skill multi-lane-coordination, mục "A Lane Run" và "Interactive Lanes".
Charter: $CREWMARSHAL_PROJECT_ROOT/.crewmarshal/lanes/$CREWMARSHAL_LANE/charter.md
Câu hỏi trong charter: hỏi user ở đây, rồi ghi outbox "quyết định".
Vượt charter: ghi outbox, nhắn Chief số mục, chờ — không đoán.
```

`launch.sh`:

```bash
#!/bin/bash
cd "<worktree đầu tiên của lane>"
export CREWMARSHAL_PROJECT_ROOT="<project root>"
export CREWMARSHAL_LANE="<tên>"
exec claude -n "lane-<tên>-r<run>" <cờ permission giống Chief> "$(cat "$CREWMARSHAL_PROJECT_ROOT/.crewmarshal/lanes/<tên>/prompt.txt")"
```

The prompt sits in `prompt.txt` beside it, so no layer of quoting touches it.
