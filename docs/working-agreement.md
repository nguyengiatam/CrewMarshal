# Quy ước làm việc: CrewMarshal

**Cập nhật:** 2026-09-23
**Ký hiệu:** `✓` = user đã chốt · `~` = đề xuất/suy luận, chưa chốt · `CHƯA CHỐT` = còn mở

## Nhịp làm việc
- **Chế độ:** ✓ **làm liên tục** — user chốt 2026-09-23. Tiếp tục trong phạm vi
  đã thống nhất, commit và push từng phần xong, chỉ hỏi khi thiếu quyết định.
- **Một "task" là:** ~ một phần việc hoàn chỉnh có commit riêng (một skill, một
  hook, một lượt dọn dẹp).

## Quy ước riêng
- **Độ chi tiết plan:** ✓ **plan trỏ, không chép** — user chốt 2026-09-03. Plan
  nêu mục tiêu, ràng buộc, nghiệm thu; phần chữ để người viết skill nghĩ. Đây là
  thay đổi **có chủ ý** so với tiền lệ duy nhất trong repo
  (`docs/plans/2026-07-24-concept-briefing.md`: 481 dòng, code viết
  sẵn từng bước) — plan cũ không phải khuôn mẫu cho plan sau.
- **Khi nào có plan/roadmap:** ✓ chỉ khi việc thật sự phức tạp; sửa skill
  Markdown thì sửa thẳng, không file plan, không roadmap — user chốt 2026-09-23.
- Ai thực thi phần lớn task: ~ coordinator viết thẳng; repo này là tài liệu, mỗi
  file là một luật phải cân từng chữ.
- Nơi đặt spec/plan: ✓ `docs/specs/` và `docs/plans/` — user chốt 2026-09-25 bỏ
  thư mục `superpowers/`.
- Commit: ~ một dòng tiếng Việt không dấu, dạng `<vùng>: <mô tả>`, kèm footer
  `Co-Authored-By`; bump version ở ba file manifest khi skill đổi.
- Push: ✓ commit xong mỗi phần thì push luôn — user chốt 2026-09-23.
