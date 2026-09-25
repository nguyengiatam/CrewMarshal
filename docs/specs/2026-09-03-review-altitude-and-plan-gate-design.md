# Độ cao phản biện & cổng plan — Design

**Ngày:** 2026-09-03 · **Trạng thái:** đã chốt với user

Ba sửa đổi, rút ra từ một đợt giao việc thật (spec + plan + 2 cổng review), không
phải từ suy đoán. Mỗi mục dưới đây có số đo kèm theo ở phần Phụ lục.

## Goal

1. `adversarial-review-to-go` hiện dạy chu trình hội tụ-về-0 như **luật phổ quát**
   và chỉ hiệu chỉnh reviewer theo **mức nghiêm trọng**. Bổ sung trục thứ hai —
   **độ cao** — và nói rõ chu trình chỉ chạy được trên bề mặt hữu hạn.
2. Không có chỗ nào trong plugin nói **plan phải trông thế nào trước khi rời tay
   coordinator**. Thêm một skill làm cổng đó.
3. `concept-briefing` bắt user tự trả lời bốn dòng, nhưng **quy mô tương lai
   không nằm trong bốn dòng ấy** — nên nó bị suy từ repo, trong khi repo không
   chứa tương lai.

## Problem

**Phản biện.** Chu trình "5 → 2 → 1 → 0" giả định bề mặt soi là hữu hạn. Trên
diff mã điều đó đúng. Trên tài liệu thì mỗi bản vá lại **đẻ ra bề mặt mới**: đo
được 10 → 11 phát hiện qua hai vòng, trong đó 6/11 phát hiện vòng 2 do chính bản
vá vòng 1 gây ra, tài liệu phình 300 → 720 dòng. Skill không có luật dừng nào cho
tình huống này, nên chỉ dẫn hiện tại là "chạy thêm vòng" — chính xác việc không
nên làm.

Gốc của thất bại là **prompt sai độ cao**: reviewer nhận danh sách file nguồn kèm
"kiểm trên mã" trong khi đối tượng soi là **spec**. Đó là lời mời phát hiện tầng
cài đặt. Mục "Calibrate the Reviewer" chỉ nói về `system-profile` — tức mức
nghiêm trọng — và im lặng hoàn toàn về độ cao.

**Cổng plan.** Trên Claude Code, bước lập kế hoạch là `superpowers:writing-plans`.
Skill đó bắt viết code block đầy đủ ở mọi bước và xếp *"steps that describe what
to do without showing how"* vào mục **plan failures**; Self-Review của nó kiểm ba
thứ: spec coverage, placeholder, type consistency. Không phép nào bắt được loại
lỗi làm executor **đi sai hướng mà không biết** — đồ thị phụ thuộc sai, nghiệm
thu đo cái dễ nhất, quyết định chưa chốt trá hình thành bước. Một vòng phản biện
trên plan của đợt vừa rồi bắt 12 phát hiện thuộc đúng nhóm này.

**Quy mô tương lai.** Template có dòng "Tăng trưởng 12 tháng tới" nhưng không in
đậm; SKILL liệt kê bốn dòng bắt buộc user trả lời và không có nó. Hệ quả quan sát
được qua nhiều phiên: agent chụp trạng thái **hiện tại** từ repo, đánh dấu `~`,
rồi con số đoán ấy đóng băng thành "fact" và lan vào mọi prompt downstream — đúng
thứ ký hiệu `~`/`✓` sinh ra để chặn. Chính template cũng viết "Nothing in the repo
tells you the growth expectation", nhưng luật bắt buộc lại bỏ sót nó.

## Quyết định

**D1 — Hội tụ-về-0 là luật có điều kiện, không phổ quát.** Nó áp dụng cho bề mặt
hữu hạn (diff mã). Trên tài liệu: **một vòng rồi dừng**. Kèm luật dừng chung: số
phát hiện không giảm sau hai vòng ⇒ **dừng và xét lại độ cao**, không chạy thêm
vòng.

*Vì sao:* chạy thêm vòng trên bề mặt tự sinh là vòng lặp không có điểm dừng, và
chi phí của nó rơi hết vào tài liệu phình ra — thứ sau đó khoá tay executor.

**D2 — Hiệu chỉnh reviewer có hai trục, không phải một.** Mức nghiêm trọng đến từ
`system-profile`; **độ cao đến từ loại tài liệu đang soi**. Ba khuôn prompt tách
hẳn nhau: soi spec · soi plan · soi diff. Khuôn soi spec **cấm** kèm danh sách
file nguồn; khuôn soi plan **cấm** bàn cơ chế; chỉ khuôn soi diff mới đúng chỗ cho
danh sách file.

*Vì sao:* có bằng chứng đối chứng — cùng model, cùng nội dung tài liệu, chỉ đổi
prompt sang khoá độ cao: 0 phát hiện tầng cài đặt (trước đó phần lớn), 3/10 phát
hiện là "cắt đi, thuộc plan", tài liệu 283 → 339 dòng thay vì 300 → 720.

**D3 — Khuôn soi diff bắt buộc gieo đột biến.** Reviewer phải gieo ít nhất một
đột biến cho **mỗi ràng buộc mà task tuyên bố đạt được**, và báo cáo đột biến nào
**không** bị bắt.

*Vì sao:* test xanh chỉ chứng minh mã chạy được, không chứng minh test canh đúng
chỗ. Ở một cổng thật, phép này bắt 4/4 đột biến — trong đó có đúng cái bẫy mà bản
giao việc mô tả là "cách hỏng kinh điển".

**D4 — Thêm một skill làm cổng plan trước khi dispatch**, chạy từ bậc T2 (nơi có
file plan). Nó giữ: ranh giới spec/plan, luật độ chi tiết của plan, chín phép
kiểm cấu trúc, phân công [E]/[C], và cổng phản biện giữa các giai đoạn.

**D5 — Độ chi tiết plan là quyết định của DỰ ÁN, không phải luật của plugin.**
Skill đọc quy ước từ `system-profile.md`; không có thì suy từ tiền lệ plan cũ
trong repo và xin xác nhận; không có cả hai thì **hỏi user một lần** rồi ghi vào
profile. `system-profile.md` mọc thêm mục **Quy ước lập kế hoạch**.

*Vì sao:* mặc định của `writing-plans` (chép đủ code) và luật "trỏ, không chép"
đều đúng trong hoàn cảnh của chúng — cái quyết định là ai thực thi và năng lực đã
chứng minh của họ. Đóng đinh một trong hai vào plugin là lặp lại đúng lỗi mà
`concept-briefing` sinh ra để sửa: đoán thay cho hỏi, rồi đoán ấy hoá thành luật.

**D6 — Mọi dòng nói về tương lai phải do user trả lời; cấm mang dấu `~`.** Dòng
bắt buộc thứ năm: quy mô dự kiến **kèm mốc thời gian**. Thêm một dòng hiển thị
**thiết kế cho mốc nào** — hiện tại hay mục tiêu.

## Ràng buộc

- Không đổi tên và không đổi hành vi của các skill ngoài ba mảng trên.
- Giữ nguyên "Golden Rule" của `adversarial-review-to-go` — tự kiểm mọi phát hiện
  trên nguồn trước khi vá. Nó chạy đúng: 21/21 phát hiện được xác nhận, 0 bác bỏ.
- Mọi skill phải tiếp tục chạy **standalone** (Codex không có superpowers).
- Ví dụ và số liệu giữ nguyên con số, **gỡ hết danh tính**: không tên dự án, tên
  service, đường dẫn nội bộ.
- Version xuất hiện ở ba file manifest và phải khớp nhau.

## Ngoài phạm vi

- Không sửa plugin superpowers. Chỗ nào cần khác đi thì skill của Conductor nói
  rõ nó đang đè lên luật nào.
- `orchestrating-executors`, `checkpoint-verification`, `lessons-ledger`,
  `executor-context`, `convention-commit-gate` không đổi, trừ dây nối tới skill
  mới.

## Definition of Done

- `adversarial-review-to-go` nêu được điều kiện áp dụng, luật dừng khi không hội
  tụ, và trỏ tới ba khuôn prompt tách biệt.
- Ba khuôn prompt tồn tại thành file đọc được, mỗi khuôn tự nói ra cái nó **cấm**.
- Skill cổng plan tồn tại, có đủ chín phép kiểm, và mục độ chi tiết plan **bắt
  đầu bằng việc tra profile**, không bắt đầu bằng một luật.
- `system-profile-template.md` có mục Quy ước lập kế hoạch, và dòng quy mô tương
  lai in đậm tách khỏi dòng quy mô hiện tại.
- `concept-briefing` nói "năm dòng", và cấm `~` trên dòng nói về tương lai.
- Arc map trong `using-conductor` và bảng skill trong README có skill mới.
- Ba file manifest cùng version.

## Phụ lục — số đo (một đợt giao việc thật)

| Đo | Số |
|---|---|
| Phản biện tài liệu, hai vòng | 10 → 11 phát hiện (không hội tụ) |
| Phát hiện vòng 2 do bản vá vòng 1 gây ra | 6/11 |
| Tài liệu, prompt cũ | 300 → 720 dòng |
| Tài liệu, prompt khoá độ cao | 283 → 339 dòng |
| Phát hiện tầng cài đặt sau khi khoá độ cao | 0 |
| Phát hiện dạng "cắt đi, thuộc plan" | 3/10 |
| Gieo đột biến ở cổng diff | 4/4 bị bắt |
| Tự kiểm phát hiện trên nguồn | 21/21 xác nhận, 0 bác bỏ |
| Vòng phản biện đầu trên plan | 12 phát hiện cấu trúc |
