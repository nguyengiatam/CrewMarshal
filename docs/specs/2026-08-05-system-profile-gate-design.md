# System Profile Gate (concept-briefing v2) — Design

**Goal:** Sửa lại phase lấy concept của Conductor, hai việc:

1. Bổ sung **hồ sơ hệ thống** — hệ thống lớn hay nhỏ, bao nhiêu người dùng, có
   cần scale không, khi hai yêu cầu xung đột thì ưu tiên cái nào. Đây là thứ
   quyết định lựa chọn phương án code, và nó phải được **chốt với người dùng**,
   không phải suy đoán từ repo. Hiện `concept-briefing` không có gì tương đương.
2. Biến kết quả đo quy mô request thành **quyết định định tuyến** — bậc đo được
   phải quyết định quy trình phía sau chạy những bước nào. Hiện phép đo chỉ sinh
   ra một dòng chữ rồi mọi request vẫn đi qua đúng một đường ống: spec → plan →
   executor, kể cả những việc đơn giản, ít thay đổi.
3. **Chia phase cho việc lớn**: dựng roadmap đi từ nền tảng tới kết quả cuối
   cùng, mỗi phase là một tầng đứng trên phase trước và gom các việc liên quan
   vào một chỗ; plan chi tiết chỉ viết khi tới lượt từng phase. Tránh tình trạng
   một task lớn dính thành một khối không biết bắt đầu từ đâu và không có mốc nào
   để dừng lại nghiệm thu.

## Problem

`concept-briefing` hiện tại (v0.2.0) sinh ra `concept-brief.md` với ba dòng: quy
mô ước lượng, mức độ nghiệp vụ, kỳ vọng người yêu cầu. Cả ba đều nói về **request**,
không nói gì về **hệ thống đang được sửa**. Hệ quả:

- Khi `brainstorming` chọn giữa hai phương án (ví dụ: cache trong process vs
  Redis; xử lý đồng bộ vs queue), nó không có căn cứ nào để quyết — không biết
  hệ thống phục vụ 200 người nội bộ hay 50k người ngoài, không biết có được phép
  làm mỏng hay không.
- Executor ngoài (Codex/agy) hoàn toàn mù bối cảnh này. Prompt handoff hiện chỉ
  trích dòng calibration quy mô request, nên executor mặc định over-engineer hoặc
  under-engineer theo thói quen của nó.
- `adversarial-review-to-go` không phân biệt được rủi ro thật với rủi ro giả —
  bắt lỗi scale trên một hệ thống nội bộ 200 user là nhiễu, bỏ qua nó trên hệ
  thống công khai là thảm hoạ.
- Cùng một thông tin bối cảnh bị hỏi lại (hoặc tệ hơn: bị đoán lại, khác đi) ở
  mỗi request mới, vì không có chỗ nào lưu.

Vấn đề thứ hai, độc lập với hồ sơ: **phép đo hiện tại không dẫn tới hành động
nào.** `concept-brief.md` ghi "quy mô: nhỏ" rồi arc vẫn chạy nguyên vẹn — vẫn
dựng spec, vẫn dựng file plan, vẫn qua vòng executor đầy đủ. Kết quả là những
việc rất đơn giản, ít thay đổi vẫn phải trả toàn bộ chi phí nghi thức, khiến
chính phép đo trở thành thủ tục thừa. Một phép đo chỉ có giá trị nếu nó thay đổi
được cái gì đó phía sau.

## Scope

**In scope:**
1. Một artifact mới, sống lâu, một-lần-mỗi-project:
   `docs/superpowers/system-profile.md`.
2. Cơ chế lập hồ sơ: Claude suy nháp từ repo → **người dùng chốt** → mới được đi
   tiếp. Đây là **gate cứng**.
3. Sửa `concept-briefing` thành skill hai bước (bước 0 đảm bảo hồ sơ, bước 1 đo
   quy mô request **và định tuyến** quy trình phía sau).
4. Bậc thang bốn mức T0–T3 quyết định bước nào chạy, bước nào bỏ.
5. Phân tầng kế hoạch: việc có nhiều tầng phụ thuộc nhau thì dựng `roadmap.md`
   đi từ nền tảng lên trước, plan chi tiết từng phase viết khi tới lượt.
6. Cập nhật các skill hạ nguồn để đọc hồ sơ: `orchestrating-executors`,
   `adversarial-review-to-go`; cập nhật `using-conductor` và `README`.

**Out of scope:**
- Không đụng vào `checkpoint-verification`, `convention-commit-gate`.
- Không tách thành skill riêng — hai việc nằm chung trong `concept-briefing`
  (xem "Đóng gói" bên dưới).
- Hồ sơ không chứa kiến trúc, vocabulary, hay task dependency — những thứ đó vẫn
  thuộc spec/plan do `brainstorming`/`writing-plans` sinh ra.

## Hai artifact, hai vòng đời

| | `system-profile.md` | `concept-brief.md` |
|---|---|---|
| Phạm vi | Cả project | Một request |
| Vòng đời | Nhiều tháng, sửa khi hệ thống đổi | Một lần dùng rồi thôi |
| Trả lời câu hỏi | "Hệ thống này là loại gì, ưu tiên gì?" | "Việc này to tới đâu → chạy những bước nào?" |
| Nguồn sự thật | **Người dùng chốt** | Claude ước lượng, người dùng xác nhận khi có bước bị bỏ |
| Vị trí | `docs/superpowers/system-profile.md` (không gắn ngày) | `docs/superpowers/plans/YYYY-MM-DD-<topic>-concept-brief.md`, **chỉ sinh từ T2 trở lên** |

Lý do tách: hai thứ có vòng đời khác hẳn nhau. Gộp chung sẽ khiến bối cảnh hệ
thống bị chép lại ở mỗi request và trôi lệch dần giữa các bản.

## Nội dung `system-profile.md`

```markdown
# System Profile: <tên hệ thống>

**Cập nhật:** YYYY-MM-DD
**Trạng thái:** CHƯA CHỐT (nháp Claude suy từ repo) | ĐÃ CHỐT — user xác nhận YYYY-MM-DD
**Ký hiệu:** `~` = Claude suy từ repo, chưa ai xác nhận · `✓` = user đã chốt

## Quy mô & tải
- Người dùng: <số lượng, nội bộ hay công khai>
- Tải: <req/s hoặc job/ngày, dung lượng dữ liệu>
- Tăng trưởng 12 tháng tới: <ổn định | tăng dần | nhân nhiều lần>
- Scale: <1 instance đủ | cần scale ngang | đã scale ngang>

## Ưu tiên khi tradeoff
Xếp hạng, dùng khi hai yêu cầu xung đột (1 = cao nhất):
1. <vd: đúng đắn số liệu>
2. <vd: tốc độ ra tính năng>
3. <vd: hiệu năng>
4. <vd: chi phí hạ tầng>

**Không đánh đổi:** <ranh giới cứng, vd: không được sai số liệu kỳ đã chốt>

## Định hướng code
- Mức trừu tượng: <trực tiếp ít lớp | có lớp mở rộng sẵn>
- Mức test kỳ vọng: <smoke | unit cho logic nghiệp vụ | phủ cao>
- Bị coi là over-engineering ở đây: <mô tả cụ thể>

## Ràng buộc vận hành
- Môi trường deploy: <...>
- Uptime / cửa sổ downtime cho phép: <...>
- Ai vận hành, mức giám sát: <...>

## Dữ liệu & tuân thủ
- Dữ liệu nhạy cảm: <...>
- Audit / backup / lưu vết: <...>

## Biên hệ thống
- Hợp đồng KHÔNG được phá: <API công khai, schema, job, consumer ngoài>
- Phụ thuộc ngoài: <...>
```

Toàn bộ prose bằng tiếng Việt, khớp ngôn ngữ làm việc của project.

Ký hiệu `~` / `✓` tồn tại để một suy đoán của máy không bao giờ đóng băng thành
"sự thật" rồi lan xuống mọi prompt phía sau. Mỗi dòng phải mang đúng một trong
hai ký hiệu.

## Gate cứng: hồ sơ phải được người dùng chốt

Đây là điểm trung tâm của thiết kế, không phải chi tiết phụ.

Gate áp dụng **từ bậc T2 trở lên** (xem "Phân bậc và định tuyến"). Với T0 gate
không áp dụng, với T1 chỉ gợi ý — vì hồ sơ tồn tại để định hướng *lựa chọn phương
án*, mà T0/T1 theo định nghĩa không có lựa chọn nào để định hướng. Ép lập hồ sơ ở
đó chính là kiểu cứng nhắc thiết kế này muốn bỏ.

- `concept-briefing` **không được kết thúc** khi công việc từ T2 trở lên mà
  `system-profile.md` còn ở trạng thái `CHƯA CHỐT`.
- `superpowers:brainstorming` **không được bắt đầu chọn phương án** khi hồ sơ
  chưa chốt (chỉ áp dụng khi brainstorming thật sự chạy, tức T2+). Khác hẳn fallback mềm mà `orchestrating-executors` đang dùng cho
  `concept-brief.md` — ở đây là chặn cứng, vì lựa chọn phương án code phụ thuộc
  nặng vào hồ sơ.
- **Bốn dòng bắt buộc người dùng trả lời trực tiếp**, Claude tuyệt đối không được
  tự điền rồi coi là xong:
  1. Người dùng thật (số lượng, nội bộ hay công khai)
  2. Nhu cầu scale
  3. Thứ tự ưu tiên khi tradeoff
  4. Cái không được đánh đổi

  Các dòng còn lại Claude điền nháp, người dùng xác nhận theo lô.
- **Im lặng không phải là đồng ý.** Không có đường tắt "user không phản đối nên
  coi như chốt".
- Nếu người dùng chưa quyết được một dòng: ghi `CHƯA CHỐT` ngay tại dòng đó,
  không chốt cả file bằng một dòng treo. Cấm mọi quyết định kiến trúc dựa trên
  dòng đó; khi công việc chạm tới nó thì phải quay lại hỏi.

## Đóng gói: một skill, hai bước

`concept-briefing` giữ nguyên tên và vị trí trong arc. Bên trong chia hai bước.

### Bước 0 — Đảm bảo hồ sơ hệ thống

1. Tìm `docs/superpowers/system-profile.md`.
2. **Đã có và ĐÃ CHỐT** → đọc. Kiểm tra tính tươi bằng **mâu thuẫn quan sát
   được**, không bằng ngưỡng thời gian cứng: repo nói khác hồ sơ (ví dụ hồ sơ ghi
   "1 instance đủ" nhưng repo vừa thêm HPA / thêm worker), hoặc chính request
   đang xử lý ngụ ý khác (ví dụ yêu cầu "chịu 10k user đồng thời" trên hồ sơ ghi
   200 user nội bộ). Có mâu thuẫn → hỏi đúng một dòng xác nhận cho dòng đó, không
   mở lại toàn bộ bảng hỏi. Không mâu thuẫn → dùng luôn, không hỏi gì.
3. **Đã có nhưng CHƯA CHỐT** → tiếp tục vòng chốt đang dở, không đi tiếp.
4. **Chưa có** → Claude quét repo để điền nháp: `README`, `CLAUDE.md`,
   `docker-compose` / manifest k8s, file config, thư mục migration, cấu hình CI,
   manifest package, số lượng service. Mọi dòng suy được đánh `~`. Sau đó trình
   cho người dùng **một lượt gộp** gồm: bốn dòng bắt buộc + những dòng nháp có độ
   tin cậy thấp. Ghi file với trạng thái `ĐÃ CHỐT`, commit.

Nguyên tắc: hỏi theo lô, không hỏi sáu vòng. Chi phí của bước này là một lần cho
cả project, nên chấp nhận được — nhưng vẫn phải gọn.

### Bước 1 — Đo quy mô request và định tuyến

Giữ cơ chế hỏi hiện tại (1–3 câu hỏi nhẹ, hoặc không hỏi gì với request hiển
nhiên nhỏ), nhưng đầu ra không còn là một dòng mô tả — đầu ra là **một bậc T0–T3
quyết định các bước tiếp theo**. Nội dung bối cảnh hệ thống không lặp lại ở đây,
chỉ tham chiếu tới `system-profile.md`.

Xem section "Phân bậc và định tuyến quy trình" bên dưới.

## Phân bậc và định tuyến quy trình

### Tiêu chí phân bậc

Phân bậc theo **số quyết định phải ra**, cố ý **không đếm số dòng code**. Sửa 300
dòng lặp lại một khuôn vẫn là T1; sửa 10 dòng đổi cách tính một số liệu đã chốt
là T3.

| Bậc | Dấu hiệu nhận biết |
|---|---|
| **T0 — cơ học** | Không có lựa chọn phương án nào: typo, đổi hằng số, rename, bump version, sửa comment |
| **T1 — nhỏ, rõ** | Đúng một cách làm hiển nhiên; 1–3 file; không chạm biên hệ thống, không chạm schema/dữ liệu |
| **T2 — vừa** | Có từ 2 phương án đáng cân nhắc trở lên, hoặc chạm schema/API, hoặc thêm thành phần mới |
| **T3 — lớn / business-critical** | Chạm dữ liệu tiền hoặc số liệu đã chốt, phá biên hệ thống, hoặc trải trên nhiều subsystem |

### Bậc quyết định chạy gì

| Bậc | system-profile | spec | file plan | executor | checkpoint-verification | convention-commit-gate | adversarial-review-to-go |
|---|---|---|---|---|---|---|---|
| T0 | miễn | không | không | không (Claude làm thẳng) | không | **có** | không |
| T1 | gợi ý, không chặn | không | không (checklist vài dòng trong hội thoại) | có | **có** | **có** | không |
| T2 | **gate cứng** | có, ngắn | có | có | **có** | **có** | chỉ khi chạm vùng rủi ro |
| T3 | **gate cứng** | có | có | có | **có** | **có** | **có** |

`convention-commit-gate` và `checkpoint-verification` không bao giờ bị bỏ khi có
code thật được viết — bỏ chúng là bỏ phần kiểm chứng, khác hẳn với bỏ phần giấy
tờ. T0 miễn `checkpoint-verification` vì Claude tự viết và tự thấy thay đổi, không
có bàn giao nào để kiểm.

### Cổng xác nhận trước khi bỏ bước

Claude **không tự ý bỏ bước**. Khi phép đo ra T0 hoặc T1, Claude dừng và hỏi
**đúng một lần, gộp mọi thứ vào một message**, ví dụ:

> "Việc này tôi xếp T1 (chỉ đổi cách format ngày ở 2 file, không có phương án
> nào khác) → đề xuất bỏ spec và file plan, làm thẳng qua executor rồi
> checkpoint. Project chưa có system-profile — T1 không bắt buộc, lập luôn hay để
> sau? Ok thì tôi chạy."

Gộp cả câu hỏi bậc lẫn câu hỏi hồ sơ vào một lượt, để việc nhỏ không bị chẻ thành
nhiều vòng chờ — đúng thứ đang cần tránh.

Với T2/T3 (chạy đủ bước) thì không cần hỏi: mặc định an toàn không tốn gì của
người dùng.

### Sinh artifact theo bậc

- **T0:** không sinh file nào. Bậc được nói trong hội thoại rồi thôi.
- **T1:** không sinh `concept-brief.md`. Bậc + checklist nằm trong hội thoại. Ghi
  một file brief cho việc T1 chính là loại nghi thức thiết kế này muốn bỏ.
- **T2/T3:** sinh `concept-brief.md` như hiện tại, cộng thêm dòng bậc và các bước
  đã quyết định chạy.

### Nâng và hạ bậc giữa chừng

- **Nâng bậc:** đang làm T1 mà phát hiện có lựa chọn phương án thật, hoặc chạm
  schema/biên hệ thống → **dừng ngay**, nâng bậc, chạy các bước mà bậc mới yêu
  cầu — kể cả lập `system-profile.md` nếu nâng lên T2 mà chưa có. Không được
  "đằng nào cũng làm gần xong rồi" mà đi tiếp.
- **Hạ bậc:** chỉ khi có bằng chứng cụ thể (ví dụ: đọc code thấy phương án thứ hai
  không khả thi, chỉ còn một đường). Không hạ bậc vì muốn đi nhanh.
- Mỗi lần đổi bậc phải nói cho người dùng biết lý do, một dòng.

## Phân tầng kế hoạch: chia phase cho việc lớn

### Roadmap là gì

**Một lộ trình đi từ nền tảng tới kết quả cuối cùng**, chia thành các phase mà
phase sau đứng trên phase trước — giống cách xây nhà từ móng lên, hoặc cách học
từng bước. Không phải danh sách việc rời rạc xếp cạnh nhau.

Khuôn mẫu tham chiếu: roadmap dựng lại một dịch vụ báo cáo định kỳ — P0 khung
service → P1 định danh/phân quyền → P2 nạp dữ liệu → P3 danh mục chỉ tiêu và
engine → P4 rollup ngày → P5 mẫu báo cáo → P6 vòng đời → P7 xuất file (**mốc dùng
được**) → P8 lịch → P9 cổng ngoài và chuyển đổi. Mỗi phase mở khoá phase kế;
không có P2 thì P3 không có gì để tính.

Hai điều roadmap đó làm đúng và phải giữ trong khuôn chung:

- **Nó là plan lộ trình, không phải implementation plan.** Plan chi tiết của mỗi
  phase chỉ được viết khi bắt đầu phase đó, vì hiểu biết thay đổi sau mỗi phase.
- **Có mốc dùng được ở giữa lộ trình**, không phải chỉ ở cuối. Hết P7 là hệ thống
  đã dùng thật được, P8/P9 là tự động hoá và tích hợp thêm.

### Vấn đề cần giải

Một việc lớn không chia phase thì mọi thứ dính vào nhau: không biết bắt đầu từ
đâu, không biết cái gì phải xong trước cái gì, không có mốc nào để dừng lại
nghiệm thu. Chia phase là để **nhóm các việc liên quan lại với nhau và xếp chúng
theo thứ tự nền móng**, nhờ đó quản lý được: mỗi lúc chỉ phải giữ trong đầu một
tầng, và mỗi tầng xong là có thứ chạy được để kiểm.

Bậc T0–T3 không giải được việc này: bậc đo **mức rủi ro của quyết định** trong một
việc, còn phase trả lời **việc này gồm mấy tầng và xây theo thứ tự nào**.

### Điều kiện kích hoạt

Dựng roadmap khi công việc **có nhiều tầng phụ thuộc nhau** — nghĩa là có thứ phải
xong trước thứ khác mới làm được, và tổng thể không nắm hết trong một plan.

Dấu hiệu:
- Có nền móng phải dựng trước khi làm được tính năng (khung service, mô hình dữ
  liệu, đường nạp dữ liệu).
- Trả lời được câu "cái gì mở khoá cái gì" bằng một cây phụ thuộc.
- Có thể chỉ ra một mốc dùng được nằm trước điểm cuối.
- Nhóm việc tự nhiên tách thành các cụm theo vùng chức năng.

Áp dụng cho T2 và T3; T0/T1 theo định nghĩa không bao giờ chạm ngưỡng này.

**Một phase không bị giới hạn trong một phiên.** Phase P3 của report service chạy
11 task qua 6 đợt executor — nhiều phiên là bình thường. Kích thước phase được
quyết định bởi *nó có phải một tầng có nghĩa hay không*, không phải bởi sức chứa
context. Việc nối tiếp giữa các phiên là việc của skill con trỏ, không phải lý do
để cắt vụn roadmap.

### Artifact

`docs/superpowers/plans/YYYY-MM-DD-<topic>-roadmap.md`, dùng chung slug với spec
và plan.

Khuôn dưới đây rút từ roadmap report service. Phần **bắt buộc** đánh dấu rõ; phần
còn lại thêm khi dự án có nhu cầu.

```markdown
# Lộ trình <tên công việc>

> **Đây là plan lộ trình, không phải implementation plan.** Plan chi tiết của mỗi
> phase viết riêng khi bắt đầu phase đó. Không viết trước — hiểu biết sẽ thay đổi
> sau mỗi phase.

**Ngày lập:** YYYY-MM-DD  ·  **Căn cứ:** <tài liệu yêu cầu>
**Hồ sơ hệ thống:** docs/superpowers/system-profile.md
**Mục tiêu:** <1–2 câu, kết quả cuối cùng>

## Phạm vi                                          [BẮT BUỘC]
Cái gì được sửa, cái gì CẤM đụng vào. Nếu một phase phát hiện cần đổi hợp đồng
với phần cấm đụng thì dừng lại và báo.

## Định hướng đã chốt                                [BẮT BUỘC]
Các quyết định xuyên suốt mọi phase, mỗi cái 1–2 dòng kèm lý do.

## Bản đồ phase                                      [BẮT BUỘC]
Cây phụ thuộc, thấy ngay cái gì mở khoá cái gì:

P0 <nền móng>
   └─> P1 <...>
        └─> P2 <...>
             ├─> P3 <...>
             └─> P4 <...>   ← MỐC DÙNG ĐƯỢC

**Mốc dùng được:** hết P<n> — <mô tả người dùng làm được gì tại mốc này>.

## Chi tiết từng phase                               [BẮT BUỘC]
### P<n> — <tên>
- **Mục tiêu:** <1 câu>
- **Phạm vi:** <những gì nằm trong phase này>
- **Tái sử dụng:** <copy/tham khảo từ đâu, hoặc "viết mới">
- **Đã chốt:** <quyết định đã ra, để phiên sau không lật lại>
- **Định nghĩa hoàn thành:** <quan sát được — không phải "code chạy">

## Những gì loại bỏ hẳn                              [nếu có]
Bảng: bỏ cái gì | lý do. Ngăn phase sau vô tình làm lại.

## Bẫy kỹ thuật bắt buộc mang theo                   [nếu có]
Bảng: bẫy | hệ quả nếu quên | thuộc phase nào.

## Rủi ro                                            [nếu có]
Bảng: rủi ro | mức | cách xử lý.

## Cách làm việc theo phase                          [nếu có]
Ai viết plan, ai thực thi, ai kiểm — nếu khác mặc định của Conductor.
```

Roadmap **không chứa trạng thái tiến độ**. Đang ở phase nào, phase trước để lại
gì, việc kế tiếp là gì — tất cả thuộc **skill con trỏ**, xem mục "Ranh giới với
skill con trỏ phiên" bên dưới. Hai thứ trộn vào nhau thì roadmap bị sửa liên tục
vì lý do tiến độ, và phần định hướng ổn định bị lẫn với phần thay đổi mỗi phiên.

### Nguyên tắc cấm phân tích sớm

Ở giai đoạn roadmap, **không** thiết kế API, không chọn phương án, không bóc task
cho những phase chưa tới lượt. Lý do đã được roadmap report service ghi ngay dòng
đầu: hiểu biết thay đổi sau mỗi phase. Phân tích sớm là phân tích sẽ bị vứt — và
tệ hơn, phân tích cũ vẫn nằm đó trông như còn hiệu lực.

Roadmap chỉ cần đủ chi tiết để trả lời: có bao nhiêu phase, mỗi phase đạt được gì,
cái gì mở khoá cái gì.

### Ranh giới phase

Một phase là **một tầng có nghĩa**, thoả cả ba:

1. **Đứng trên nền đã có và tạo nền cho phase sau.** Trả lời được: phase này cần
   gì đã xong trước, và nó mở khoá cái gì.
2. **Nhóm các việc liên quan vào cùng một chỗ.** Việc chạm cùng module, xoay quanh
   cùng mô hình dữ liệu, hoặc lặp cùng một khuôn (5 endpoint cùng dạng) thì nằm
   chung một phase — làm liền mạch nhanh hơn hẳn rải ra nhiều phase, vì bối cảnh
   đã nằm sẵn trong đầu. Ngược lại, việc chạm vùng hoàn toàn khác nhau thì tách,
   dù mỗi việc nhỏ.
3. **Có định nghĩa hoàn thành quan sát được.** "Pod chạy trên k3s dev, `/health`
   trả 200, CI xanh" là định nghĩa hoàn thành; "xong phần khung service" thì không.

**Kích thước không phải tiêu chí.** Một phase có thể kéo dài nhiều phiên và nhiều
đợt executor — P3 của report service chạy 11 task qua 6 đợt. Đừng cắt vụn một tầng
có nghĩa chỉ vì nó lớn; nếu nó lớn thì chia nhỏ **bên trong plan chi tiết** của
phase đó, chứ không phá cấu trúc tầng của roadmap.

Dấu hiệu chia sai:
- Phase không nói được nó mở khoá cái gì → nó là danh sách việc, không phải tầng.
- Hai phase liên tiếp sửa cùng một chỗ code → nên gộp.
- Một phase chạm bốn vùng chẳng liên quan gì nhau → nên tách.
- Không có mốc dùng được nào trước phase cuối → lộ trình đang dồn hết giá trị về
  cuối, xếp lại thứ tự.

### Thứ tự các phase

Xếp theo **thứ tự nền móng**: cái gì phải tồn tại trước để cái sau làm được. Đây
là ràng buộc cứng, đọc thẳng từ cây phụ thuộc.

Khi có nhiều phase cùng sẵn sàng (không cái nào chặn cái nào), ưu tiên:
1. Phase gỡ bất định lớn nhất — chưa chắc làm được, hoặc chưa rõ cách làm.
2. Phase kéo được **mốc dùng được** lên sớm hơn.

### Phase phát sinh giữa chừng

Roadmap là kế hoạch sống. Khi một phase đang làm lộ ra việc phải xử lý trước khi
đi tiếp, thêm phase mới vào đúng vị trí phụ thuộc thay vì nhét vào phase hiện tại
— report service làm đúng vậy với P3b (hiệu chỉnh chỉ tiêu theo yêu cầu mới, phát
sinh sau P3, phải xong trước P4). Ghi rõ ngày phát sinh và lý do, để phiên sau
hiểu vì sao nó có mặt.

### Vòng lặp thực thi

```
concept-briefing (bước 0: hồ sơ) → bước 1: đo bậc + phát hiện nhiều tầng phụ thuộc
  → brainstorming ở mức ranh giới (chia tầng, xếp thứ tự nền móng, không đi sâu)
  → roadmap.md → CHỐT VỚI USER
  → với mỗi phase, theo thứ tự phụ thuộc:
       đo bậc riêng cho phase đó (có thể chỉ là T1 → bỏ spec/plan)
       → spec/plan chi tiết CHỈ VIẾT LÚC NÀY, không viết trước
       → executor → checkpoint-verification → convention-commit-gate
       → điều học được ảnh hưởng phase sau → cập nhật roadmap nếu đổi định hướng
  → adversarial-review-to-go (sau mỗi phase rủi ro cao, hoặc một lần ở cuối)
  → finishing-a-development-branch
```

Hai điểm mấu chốt:

- **Plan chi tiết viết đúng lúc tới lượt phase đó**, không viết trước cả loạt.
- **Mỗi phase được đo bậc lại độc lập.** Một lộ trình lớn hoàn toàn có thể gồm
  phần lớn là các phase T1 — khi đó chúng đi đường tắt của T1, không ai bắt viết
  spec cho từng phase.

### Chốt roadmap với user

Roadmap phải được người dùng chốt trước khi bắt đầu phase 1, vì nó quyết định thứ
tự giao hàng — thứ Claude không được tự quyết. Nhẹ hơn gate hồ sơ: chỉ cần xác
nhận danh sách phase và thứ tự, không rà từng dòng.

Hồ sơ hệ thống phải có trước roadmap: mọi việc có roadmap đều là T2+, nên gate
cứng đã áp dụng sẵn.

### Ranh giới với skill con trỏ phiên

Một lộ trình nhiều phase chạy qua rất nhiều phiên, nên phải có chỗ ghi "đang ở
đâu". Nhưng **cơ chế con trỏ là một skill riêng, không nằm trong spec này**. Ranh
giới:

- **Spec này (`concept-briefing`)**: quyết định *có bao nhiêu phase, ranh giới ở
  đâu, thứ tự nền móng nào* — thứ ổn định, sửa khi định hướng đổi.
- **Skill con trỏ (spec riêng)**: *phiên mới nạp lại bối cảnh bằng cách nào* —
  đang ở phase nào, task nào đang dở, quyết định vừa ra và lý do, cạm bẫy vừa
  gặp, việc kế tiếp. Thứ thay đổi mỗi phiên.

Lý do tách: con trỏ hữu ích cả khi không có roadmap (bất kỳ công việc nhiều phiên
nào cũng cần bàn giao), nên gắn cứng vào `concept-briefing` là đặt sai chỗ. Đây
cũng là cách report service đang làm — roadmap và `STATUS.md` là hai file khác
nhau, sửa vì hai lý do khác nhau.

### Quan hệ với `superpowers:brainstorming`

`brainstorming` vốn đã có bước "nếu quá lớn thì tách sub-project", nhưng nó tách
theo *subsystem độc lập* — các mảnh nằm ngang nhau. Roadmap tách theo *tầng phụ
thuộc*: cái gì phải xong trước để cái sau làm được. Phần này bổ sung trục thiếu
đó, biến bước tách thành artifact có thật với cây phụ thuộc và mốc dùng được, thay
vì để là một dòng khuyến nghị dễ bị bỏ qua.

Khi roadmap được kích hoạt, `brainstorming` chạy **hai lần ở hai độ sâu**: một
lần ở mức ranh giới để chia phase, rồi một lần đầy đủ cho từng phase khi tới lượt
(nếu bậc của phase đó yêu cầu).

## Tác động xuống hạ nguồn

- **`superpowers:brainstorming`**: đọc cả hai. Hồ sơ quyết định *chọn phương án
  nào* (được phép làm mỏng tới đâu, có cần lớp mở rộng không); brief quyết định
  *đào sâu tới đâu* (bao nhiêu approach, hỏi bao nhiêu câu).
- **`orchestrating-executors`**: prompt handoff trích thẳng từ hồ sơ ba thứ —
  thứ tự ưu tiên tradeoff, biên không được phá, mức test kỳ vọng. Đây là chỗ giá
  trị nhất, vì executor ngoài hoàn toàn mù bối cảnh này. Bullet hiện có về
  `concept-brief.md` giữ nguyên, thêm bullet mới cho hồ sơ.
- **`adversarial-review-to-go`**: reviewer nhận hồ sơ để phân biệt rủi ro thật
  với rủi ro giả, và để biết đâu là ranh giới không được phá.
- **`checkpoint-verification`, `convention-commit-gate`**: không đổi.

## Cập nhật hồ sơ về sau

- Khi phát hiện thực tế lệch hồ sơ (ví dụ hoá ra hệ thống có 50k user, không phải
  200), Claude sửa file và đổi ngày cập nhật, không chờ được yêu cầu.
- Khi một dòng bị sửa, Claude **chủ động rà lại** các quyết định kiến trúc đã dựa
  trên dòng cũ và báo lại cho người dùng — không im lặng đi tiếp. Một hồ sơ đổi
  giữa chừng có thể làm vô hiệu phương án đã chọn.
- Dòng sửa bởi người dùng giữ `✓`; dòng Claude tự sửa từ quan sát mới quay về `~`
  cho tới khi người dùng xác nhận.

## Các file phải sửa

| File | Thay đổi |
|---|---|
| `skills/concept-briefing/SKILL.md` | Viết lại: hai bước, gate cứng theo bậc, template hồ sơ, quy tắc `~`/`✓`, bảng phân bậc T0–T3 + bảng định tuyến, cổng xác nhận trước khi bỏ bước, quy tắc nâng/hạ bậc, kích hoạt roadmap + template roadmap + nguyên tắc cấm phân tích sớm, cập nhật Red Flags |
| `skills/orchestrating-executors/SKILL.md` | Thêm bullet vào Handoff Prompt Checklist: trích ưu tiên tradeoff + biên không được phá + mức test từ hồ sơ |
| `skills/adversarial-review-to-go/SKILL.md` | Reviewer đọc hồ sơ để hiệu chỉnh cái gì đáng coi là finding |
| `skills/using-conductor/SKILL.md` | Cập nhật arc: arc đầy đủ là đường của T2/T3, kèm bảng định tuyến rút gọn cho T0/T1; cập nhật bảng "When to Use Which Skill" |
| `README.md` | Cập nhật mô tả `concept-briefing` + arc, nêu rõ arc co giãn theo bậc |
| `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json` | Bump `0.2.0` → `0.3.0` |

## Edge cases

- **Repo nghèo dấu vết** (không README, không compose): Claude điền được rất ít,
  phần lớn dòng để trống và hỏi. Chấp nhận — thà hỏi còn hơn đoán bừa.
- **Conductor áp dụng giữa chừng, chưa từng có hồ sơ**: gate vẫn cứng — lập hồ sơ
  trước khi brainstorming. Đây là lần duy nhất phải trả chi phí này.
- **Request cực nhỏ (sửa typo) trên project chưa có hồ sơ**: T0 miễn hồ sơ, làm
  thẳng. Hồ sơ chỉ bị đòi khi công việc thật sự có quyết định kiến trúc để định
  hướng (T2+), hoặc được gợi ý không chặn ở T1.
- **Việc T1 nhưng người dùng muốn có spec**: người dùng luôn thắng phép đo. Cổng
  xác nhận tồn tại chính vì thế — Claude đề xuất bậc, người dùng có thể nâng.
- **Làm phase 1 xong thì phase 3 hết cần thiết**: xoá khỏi roadmap và nói lý do.
  Roadmap là kế hoạch sống, không phải cam kết phải làm đủ.
- **Giữa chừng lộ ra phase mới**: thêm vào đúng vị trí trong cây phụ thuộc (như
  P3b của report service), ghi ngày phát sinh và lý do, báo người dùng một dòng.
- **Không có tầng phụ thuộc nào, chỉ là một đống việc ngang nhau**: không dựng
  roadmap giả. Đó là một phase duy nhất với nhiều task — xử lý bằng plan chi tiết
  thường của T2/T3.
- **Phase quá nhỏ**: nếu roadmap sinh ra 8 phase mà phase nào cũng không nói được
  nó mở khoá cái gì thì đang chia vụn theo danh sách việc. Gộp lại theo tầng.
- **Phase kéo dài quá lâu**: đây không phải lỗi của roadmap. Chia nhỏ bên trong
  plan chi tiết của phase, giữ nguyên ranh giới tầng.
- **Nhiều hệ thống trong một repo (monorepo)**: một `system-profile.md` cho mỗi
  đơn vị triển khai độc lập, đặt cạnh đơn vị đó; nếu cả monorepo triển khai chung
  thì một file ở gốc.
- **Người dùng từ chối trả lời**: không có đường vòng. Ghi `CHƯA CHỐT` tại dòng
  đó và dừng phần công việc phụ thuộc vào nó; các phần khác vẫn chạy được.

## Verification Plan

Thay đổi này là file skill/doc, không phải code ứng dụng, nên verify bằng dry run
thật:

1. Chạy `concept-briefing` trên một project thật chưa có hồ sơ →
   xác nhận Claude sinh được bản nháp từ repo, hỏi đúng bốn dòng bắt buộc theo
   một lượt gộp, và **không đi tiếp** khi chưa được chốt.
2. Chạy lại trên project đã có hồ sơ ĐÃ CHỐT → xác nhận không hỏi lại, chỉ đọc.
3. Kiểm tra một prompt handoff do `orchestrating-executors` sinh ra có thật sự
   chứa thứ tự ưu tiên tradeoff và biên không được phá.
4. Xác nhận bốn skill còn lại không đổi hành vi ngoài các mục đã liệt kê ở bảng
   trên.
5. Chạy trên một việc T1 thật (ví dụ đổi format hiển thị ở vài file) → xác nhận
   Claude đề xuất bỏ spec/plan, hỏi **một lần duy nhất** gộp cả bậc lẫn hồ sơ, và
   sau khi được đồng ý thì đi thẳng tới executor mà không sinh file spec/plan/brief
   nào.
6. Chạy trên một việc T0 (sửa typo) → xác nhận không đòi hồ sơ, không sinh file
   nào, nhưng vẫn qua `convention-commit-gate` khi commit.
7. Dựng tình huống nâng bậc: bắt đầu như T1 rồi lộ ra thay đổi schema → xác nhận
   Claude dừng, nâng lên T2, và lúc đó mới đòi lập `system-profile.md`.
8. Chạy trên một việc nhiều tầng → xác nhận Claude dựng `roadmap.md` có cây phụ
   thuộc và mốc dùng được, chỉ ở mức ranh giới (**không** thiết kế chi tiết phase
   2, 3), chốt với người dùng, rồi đo bậc lại cho riêng phase đầu.
9. Đối chiếu khuôn roadmap sinh ra với khuôn mẫu tham chiếu: các mục bắt buộc
   (phạm vi, định hướng đã chốt, bản đồ phase, chi tiết phase với định nghĩa hoàn
   thành quan sát được) phải có mặt, và roadmap **không** chứa trạng thái tiến độ.
