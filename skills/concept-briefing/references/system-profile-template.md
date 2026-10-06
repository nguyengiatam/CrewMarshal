# System Profile — Template

Copy to `docs/system-profile.md`. Prose stays in the project's working
language; the headings below are Vietnamese because that is this project's.

The profile has two parts: **a short core** that every project answers, and **one
section per lens** that fits what is being built — chosen from
[profile-lenses.md](profile-lenses.md). A CLI tool gets no scale section; a
backend service gets no design-source section.

Every line carries exactly one marker: `~` inferred by Claude from the repo,
`✓` confirmed by the user. The markers exist so a machine guess never freezes
into "fact" and then propagates into every downstream prompt.

Every **bold** line must be answered by the user directly. Draft the rest and have
them confirmed in one batch.

Anything about the future — where the project is heading, expected users or load
— is user-answered without exception: the repo contains no future, so a `~` there
is not an inference, it is a guess wearing an evidence marker. If the user cannot
answer yet, leave the line `CHƯA CHỐT`.

---

```markdown
# System Profile: <tên dự án>

**Cập nhật:** YYYY-MM-DD
**Trạng thái:** CHƯA CHỐT (nháp Claude suy từ repo) | ĐÃ CHỐT — user xác nhận YYYY-MM-DD
**Ký hiệu:** `~` = Claude suy từ repo, chưa ai xác nhận · `✓` = user đã chốt
**Loại:** <các lens đã chọn, vd: Frontend / UI + Service / backend>

## Lõi
- Là gì, để làm gì: <một hai câu>
- **Ai dùng, trong hoàn cảnh nào:** <bản thân | team n người | khách hàng | công khai>
- **Hướng tới:** <mốc thời gian + sẽ thành gì> — hoặc CHƯA CHỐT

**Ưu tiên khi tradeoff (1 = cao nhất):**
1. <vd: đúng đắn số liệu>
2. <vd: tốc độ ra tính năng>
3. <...>

**Không đánh đổi:** <ranh giới cứng, vd: không được sai số liệu kỳ đã chốt>

## Định hướng code
- Mức trừu tượng: <trực tiếp ít lớp | có lớp mở rộng sẵn>
- Mức test kỳ vọng: <smoke | unit cho logic nghiệp vụ | phủ cao>
- Bị coi là over-engineering ở đây: <mô tả cụ thể>

## <Tên lens> — một mục cho mỗi lens đã chọn
- <các dòng của lens đó trong profile-lenses.md, bỏ dòng không thể ảnh hưởng dự án này>
```

---

## What to draft from the repo

| Section | Look at |
|---------|---------|
| Lõi — là gì | README, CLAUDE.md, package manifest |
| Định hướng code | Existing abstraction depth, test directory size and style, lint config |
| Lens sections | The *(hints)* on each line in profile-lenses.md |

Nothing in the repo tells you who really uses it, where it is heading, or which
priority wins a conflict. Those are the questions worth the user's time —
questions, never inferences.

Working rules — cadence, role limits, plan detail — don't belong here; they live
in the working agreement (`project-working-agreement`).

## What a good one reads like

Concrete, no hedging — the shape to aim for (a small backend service):

> Service **rất ít người dùng, quy mô nhỏ, gần như không bao giờ scale**. Mọi
> quyết định thiết kế phải chọn phương án đơn giản hơn khi hai phương án cùng
> đáp ứng yêu cầu.
>
> | Hạng mục | Số đo được |
> |---|---|
> | Người dùng hệ thống | <số thật, nội bộ hay công khai> |
> | Quy mô dự kiến | <số tại mốc nào — user chốt, không suy> |
> | Số bản chạy service | <n replica> |
> | Ca dùng nặng nhất | <mô tả — thứ phải thiết kế để chịu được> |

And for a UI: *"Làm theo Figma <link>, đã duyệt; chỉ desktop Chrome/Edge; người
duyệt giao diện là PO qua screenshot; dùng component library sẵn có, không tự
thêm style."* — four facts that settle most UI arguments before they start.

**Specifics beat adjectives.** "Nhỏ" or "đẹp, hiện đại" is arguable and gets
re-litigated every phase; "1 replica, 200 internal users" or "theo Figma đã duyệt"
is not.
