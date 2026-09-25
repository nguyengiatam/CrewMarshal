# Roadmap — Template

Copy to `docs/plans/YYYY-MM-DD-<topic>-roadmap.md`. Sections marked
**[REQUIRED]** always appear; the rest are added when the project needs them.

Prose stays in the project's working language.

---

```markdown
# Lộ trình <tên công việc>

> **Đây là plan lộ trình, không phải implementation plan.** Plan chi tiết của mỗi
> phase viết riêng khi bắt đầu phase đó. Không viết trước — hiểu biết sẽ thay đổi
> sau mỗi phase.

**Ngày lập:** YYYY-MM-DD  ·  **Căn cứ:** <tài liệu yêu cầu>
**Hồ sơ hệ thống:** docs/system-profile.md
**Mục tiêu:** <1–2 câu, kết quả cuối cùng>

## Phạm vi                                            [REQUIRED]
Cái gì được sửa, cái gì CẤM đụng vào. Nếu một phase phát hiện cần đổi hợp đồng
với phần cấm đụng thì dừng lại và báo — không tự sửa.

## Định hướng đã chốt                                  [REQUIRED]
Các quyết định xuyên suốt mọi phase, mỗi cái 1–2 dòng kèm lý do.

## Bản đồ phase                                        [REQUIRED]

P0 <nền móng>
   └─> P1 <...>
        └─> P2 <...>
             ├─> P3 <...>
             └─> P4 <...>        ← MỐC DÙNG ĐƯỢC

**Mốc dùng được:** hết P<n> — <người dùng làm được gì tại mốc này>.

## Chi tiết từng phase                                 [REQUIRED]

### P<n> — <tên>
- **Mục tiêu:** <1 câu>
- **Phạm vi:** <những gì nằm trong phase này>
- **Tái sử dụng:** <copy/tham khảo từ đâu, hoặc "viết mới">
- **Đã chốt:** <quyết định đã ra, để phiên sau không lật lại>
- **Định nghĩa hoàn thành:** <quan sát được — không phải "code chạy">

## Những gì loại bỏ hẳn                                [nếu có]
Bảng: bỏ cái gì | lý do. Ngăn phase sau vô tình làm lại.

## Bẫy kỹ thuật bắt buộc mang theo                     [nếu có]
Bảng: bẫy | hệ quả nếu quên | thuộc phase nào.

## Rủi ro                                              [nếu có]
Bảng: rủi ro | mức | cách xử lý.

## Cách làm việc theo phase                            [nếu có]
Ai viết plan, ai thực thi, ai kiểm — chỉ ghi khi khác mặc định của CrewMarshal.
```

---

## A worked example

Rebuilding a scheduled-reporting service — foundation upward, with the usable
milestone deliberately placed before the end:

```text
P0 Service skeleton
   └─> P1 Identity, permissions, audit trail, file storage
        └─> P2 Data ingestion from the source system
             └─> P3 Metric catalogue + compute engine
                  └─> P3b Metric revisions from updated requirements  ← ADDED after P3
                       ├─> P4 Daily rollup
                       ├─> P5 Report templates
                       └─> P6 Report lifecycle + snapshots
                            └─> P7 Export + signing      ← USABLE MILESTONE
                                 ├─> P8 Scheduling + reminders
                                 └─> P9 External gateway + cutover
```

Read what that structure gets right:

- **Every phase unlocks the next.** Without P2 there is no data for P3's engine to
  compute; without P3's catalogue there is nothing for P5's templates to bind to.
- **The usable milestone sits at P7, not P9.** By then people create reports,
  figures aggregate, files export signed. P8/P9 are automation and integration —
  valuable, but the system already earns its keep without them.
- **P3b appeared mid-flight** — updated requirements changed metric definitions
  P3 had just implemented, and it had to land before P4 aggregated them. It was
  inserted at its dependency position with its origin date recorded, not stuffed
  into the running phase.
- **One phase ran a dozen tasks across several executor rounds.** Phases are not
  session-sized; that one spanned many sessions and stayed a single layer.

A phase entry at the level of detail that belongs in a roadmap — and no more:

> ### P0 — Service skeleton
>
> **Goal:** the new repo runs, has a health check, deploys to the dev cluster.
>
> **Scope:** repo init; language/lint config; database connection; logger; health
> endpoint; shared module (centralized enums, error codes, i18n messages);
> container image; deployment chart; CI script.
>
> **Reuse:** shared module, config, database, logging, chart and image definitions
> from the existing service — rename, and drop enums no longer used.
>
> **Definition of done:** pod running on dev, `/health` returns 200, CI green.

Note what is absent: no file list, no interface sketches, no task breakdown. Those
belong in P0's detailed plan, written when P0 starts.
