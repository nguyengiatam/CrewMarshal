# System Profile: CrewMarshal (Claude Code plugin)

**Cập nhật:** 2026-09-23
**Trạng thái:** ĐÃ CHỐT — user xác nhận 2026-08-05
**Ký hiệu:** `~` = Claude suy từ repo, chưa ai xác nhận · `✓` = user đã chốt

## Quy mô & tải
- **Người dùng:** ✓ **repo công khai trên GitHub, nhưng chỉ tác giả dùng** —
  user chốt 2026-09-23. Không phải lo migration hay tương thích ngược cho người
  cài khác khi đổi tên/namespace. Vì repo vẫn công khai, hệ quả cứng giữ
  nguyên: mọi ví dụ trong skill phải **tự giải thích**, không được giả định
  bất kỳ project nội bộ nào của tác giả — không tên dự án, không số liệu vận
  hành thật; lệnh theo máy chỉ nằm trong `executor-roster.md`.
- Tải: ~ không có runtime. "Tải" duy nhất là **context Claude phải nạp** mỗi lần
  skill kích hoạt — đó mới là tài nguyên khan hiếm ở đây.
- **Scale hiện tại:** ✓ không áp dụng — plugin là file markdown, không có gì để
  scale.

## Quy mô DỰ KIẾN (user trả lời — không suy từ repo, không mang dấu `~`)
- **Mốc thời gian:** CHƯA CHỐT
- **Số skill dự kiến tại mốc đó:** CHƯA CHỐT — đây là con số quyết định thật:
  mỗi skill thêm vào là thêm chi phí nạp context cho **mọi** phiên, nên trần số
  skill là ràng buộc thiết kế, không phải chuyện tăng trưởng tự nhiên.
- **Thiết kế cho mốc nào:** CHƯA CHỐT

> Dòng "Tăng trưởng 12 tháng tới: ~ số skill tăng dần" trước đây mang dấu `~` —
> tức Claude tự suy. Đúng loại lỗi mà luật mới cấm: repo không chứa tương lai.
> Giữ `CHƯA CHỐT` cho tới khi user trả lời.

## Ưu tiên khi tradeoff
**Xếp hạng, dùng khi hai yêu cầu xung đột (1 = cao nhất):**

1. ✓ **Luật mà bỏ sót sẽ gây hậu quả thật → viết thẳng trong `SKILL.md`.**
   Không đẩy sang references, không rút gọn cho đẹp.
2. ✓ **Phần còn lại → đẩy sang `references/`,** đọc khi cần.
3. Skill ngắn, dễ đọc.

Nói cách khác: độ dài không phải mục tiêu, **hậu quả của việc bỏ sót** mới là
tiêu chí phân loại. Một luật quan trọng nằm trong file phụ mà Claude không mở là
luật không tồn tại.

**Không đánh đổi:** ✓ bốn ranh giới cứng, mọi skill phải giữ

1. **Kiểm chứng thật** — test xanh không bao giờ là bằng chứng hoàn thành; phải
   soi call-site và chạy đường vận hành thật.
2. **Quyết định thuộc người dùng** — Claude không tự quyết việc bỏ bước, đánh đổi
   nghiệp vụ, hay thứ tự giao hàng.
3. **Tự phản biện finding** — mọi finding của reviewer/executor phải kiểm lại trên
   mã thật trước khi áp dụng; không bao giờ áp mù.
4. **Không bịa đặt kết quả** — không báo xong khi chưa chạy; không bịa số liệu
   hay trạng thái chưa đo.

## Định hướng code
- ~ Không có mã chạy. "Chất lượng" ở đây đo bằng: skill có làm Claude **hành xử
  đúng** không, và có bị lách bằng lý lẽ không.
- ~ Mức trừu tượng: viết trực tiếp, mệnh lệnh. Bảng Red Flags ("Thought" vs
  "Reality") là cách chính để chặn đường lách — giữ khuôn đó.
- ~ Kiểm chứng skill: dogfood trên việc thật, không có test tự động.

## Ràng buộc vận hành
- ~ Phân phối qua GitHub marketplace. **Sửa file trong repo làm việc chưa tới tay
  ai** — phải push, rồi người dùng chạy `/plugin marketplace update` (Claude Code)
  hoặc `codex plugin marketplace upgrade` (Codex).
- ✓ **Cài được trên hai harness**: Claude Code đọc `.claude-plugin/`, Codex đọc
  `.codex-plugin/plugin.json` + `.agents/plugins/marketplace.json`. Cả hai trỏ
  vào cùng `skills/`.
- ~ Version nằm ở **ba** file, phải khớp: `.claude-plugin/plugin.json`,
  `.claude-plugin/marketplace.json`, `.codex-plugin/plugin.json`.
- ~ Không có CI, không có test tự động. Kiểm bằng dogfood; phía Codex kiểm thêm
  bằng `validate_plugin.py` của skill `plugin-creator`.

## Dữ liệu & tuân thủ
- ~ Không có dữ liệu người dùng, không PII, không secret trong repo.
- ~ Rủi ro duy nhất theo hướng này: **rò rỉ chi tiết nội bộ** (đường dẫn, tên
  service, số liệu MSS) vào skill công khai. Ví dụ phải được viết lại cho trung
  tính trước khi commit.

## Biên hệ thống
- **Hợp đồng KHÔNG được phá:**
  - Tên skill trong frontmatter — người dùng gọi bằng tên, đổi là phá cách gọi.
    Chỉ đổi khi user quyết định có chủ ý (2026-09-23: plugin đổi tên
    `conductor` → `crewmarshal`, `using-conductor` → `using-crewmarshal`).
  - `references/executor-roster.md` là **chỗ duy nhất** chứa lệnh theo máy; thân
    skill phải bất khả tri về agent.
  - CrewMarshal là **delta trên superpowers**, không thay thế: `brainstorming`,
    `writing-plans`, `finishing-a-development-branch` vẫn là của superpowers.
- ~ Phụ thuộc ngoài: superpowers (bookend), các CLI executor (Codex, agy, …) chỉ
  qua roster.
