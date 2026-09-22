# CrewMarshal: tên plugin, quy ước dự án, ba hook và monitor bất đồng bộ

**Ngày:** 2026-09-22
**Trạng thái:** ĐÃ TRIỂN KHAI 2026-09-23 (0.11.0 → 0.14.0). Giữ làm hồ sơ; mục 9
ghi các quyết định đã chốt và phần còn mở.
**Phạm vi tài liệu:** Mô tả hành vi và nghiệm thu, không phải kế hoạch triển khai.

## 1. Mục tiêu

Chuẩn bị plugin để phân phối công khai với định danh riêng, bổ sung quy ước
làm việc theo dự án và cơ chế đưa đúng ngữ cảnh vào đúng thời điểm. Ba nhu cầu
chính là: thiết kế dựa trên system profile, thực thi theo quy ước đã thống nhất,
và duy trì pointer đủ mới để tiếp tục công việc qua các phiên.

Bổ sung yêu cầu giao việc bất đồng bộ: coordinator gắn monitor ngay khi giao
task cho executor bên ngoài, rồi làm việc độc lập hoặc chờ sự kiện; không liên
tục kiểm tra tiến độ bằng các lượt gọi tool.

Plugin tiếp tục tập trung vào điều phối, giao việc, review và kiểm chứng; không
mở rộng thành bộ quản lý backlog, nghiên cứu hay reviewer persona toàn diện.

## 2. Định danh CrewMarshal

Tên đích đang được đề xuất là **CrewMarshal**, slug `crewmarshal`, thay cho
Conductor. Người dùng đã yêu cầu khảo sát đổi tên và ghi nhận phạm vi; cần chốt
tên phát hành trước khi áp dụng đổi định danh. Chưa có bảo đảm tên này chưa được
ai sử dụng chỉ từ kết quả tìm kiếm công khai.

Nếu chọn tên này:

- Đồng bộ định danh plugin trong manifest và marketplace của Claude Code và Codex.
- Đồng bộ tên hiển thị, mô tả thương hiệu, namespace được tài liệu tham chiếu và
  hướng dẫn cài đặt, cập nhật, gỡ bỏ.
- Đề xuất đổi marketplace thành `crewmarshal-marketplace`, skill giới thiệu từ
  `using-conductor` thành `using-crewmarshal`.
- Giữ tên và chức năng các skill còn lại, trừ thay đổi tích hợp được nêu trong spec.
- Cung cấp hướng dẫn chuyển cài đặt cũ sang mới, tránh bật đồng thời hai bản
  có các skill trùng chức năng. Không giả định đổi tên sẽ tự nâng cấp bản cũ.
- Đồng bộ version khi phát hành. Việc đổi repo GitHub là lựa chọn riêng;
  chỉ đổi URL khi repo đích thực sự tồn tại.
- Spec/plan lịch sử có thể giữ tên cũ; tài liệu vận hành hiện hành phải nhất quán.

## 3. Skill quản lý quy ước làm việc theo dự án

Tên đề xuất: **`project-working-agreement`**.

Skill giúp xây dựng, đọc, áp dụng và cập nhật quy ước chung cho mọi vai trò.
Quy ước phải được lưu bền vững trong dự án, không chỉ nằm trong hội thoại hoặc
bộ nhớ riêng của một agent.

### Khởi tạo và thay đổi

- Tìm quy ước có sẵn trước khi hỏi hoặc tạo tài liệu mới. Nếu dự án đã dùng
  `AGENTS.md`, `CLAUDE.md` hoặc tài liệu tương đương, tích hợp với nguồn đó.
- Hỏi những lựa chọn còn thiếu, theo nhóm ngắn; không hỏi lại điều người dùng
  đã quyết định trong phiên hoặc đã ghi trong dự án.
- Phân biệt quy tắc đã được người dùng chốt với đề xuất hoặc suy luận chưa chốt.
- Cho phép người dùng sửa quy ước về sau. Yêu cầu hiện tại của người dùng được
  áp dụng trong phạm vi nó điều chỉnh; chỉ ghi thành quy ước lâu dài khi đó là
  ý định của người dùng. Quy ước dự án không vượt các chỉ dẫn có ưu tiên cao hơn.

### Các nhóm quy ước

| Nhóm | Nội dung cần xác lập |
|---|---|
| Nhịp làm việc | Dừng sau mỗi task hay tiếp tục trong phạm vi đã thống nhất |
| Coordinator | Trách nhiệm thiết kế, phân rã, giao việc, giải quyết phụ thuộc, nghiệm thu và duy trì trạng thái |
| Executor | Phạm vi thực thi, quyền quyết định chi tiết, kiểm chứng và báo cáo |
| Reviewer | Phạm vi review, bằng chứng finding, hướng sửa và trách nhiệm khi bất đồng |
| Quyền quyết định | Việc tự quyết được, việc cần hỏi, xử lý phần bị chặn |
| Quy ước đặc thù | Ngôn ngữ, plan, commit/PR, môi trường thao tác, báo tiến độ và các ràng buộc riêng |

Đây là các nhóm để hỏi và ghi nhận, không phải bộ vai trò cứng áp đặt giống nhau
cho mọi dự án. Các ranh giới kiểm chứng của plugin vẫn phải được giữ.

### Lựa chọn nhịp làm việc

Khi khởi tạo cần hỏi rõ, ít nhất đưa ra hai phương án:

1. **Dừng sau mỗi task:** hoàn thành và kiểm chứng task, báo kết quả rồi chờ
   người dùng trước khi chuyển sang task tiếp theo.
2. **Làm liên tục:** tiếp tục trong phạm vi đã thống nhất; chỉ hỏi khi thiếu
   thông tin hoặc quyền quyết định cần thiết. Khi một phần bị chặn, tiếp tục
   phần độc lập còn lại nếu có.

Không mặc định phương án thứ hai từ ví dụ của người dùng. Cần làm rõ đơn vị
“task” theo workflow dự án; một lượt gọi tool không mặc nhiên là một task.
Làm liên tục không đồng nghĩa tự mở rộng phạm vi hoặc bỏ kiểm chứng.

### Một nguồn cho mỗi loại thông tin

| Tài liệu | Trách nhiệm |
|---|---|
| Working agreement | Vai trò, quyền hạn và cách phối hợp |
| System profile | Quy mô, ưu tiên đánh đổi và ràng buộc hệ thống |
| Executor context | Hướng dẫn thực thi dùng chung và tham chiếu quy ước liên quan |
| Pointer | Trạng thái hiện tại, việc đang dở và bước tiếp theo |
| Lessons | Bài học và bằng chứng từ công việc trước |

Không nhân bản quy tắc vào nhiều nguồn có thể lệch nhau. Quy ước lập kế hoạch
đã nằm trong system profile cần được tham chiếu hoặc di chuyển có chủ ý, không
tạo hai bản có thẩm quyền ngang nhau.

## 4. Hook: nhắc ở điểm bắt buộc đi qua

> **Sửa 2026-09-23.** Bản đầu đề xuất ba hook nạp ngữ cảnh (design context,
> working agreement) và một bộ đếm task đã nghiệm thu. User chốt lại: mục đích
> hook là để agent **không bỏ qua thao tác quan trọng**, và **một lời nhắc là
> đủ** — model hiện nay không cần bị chặn cứng. Phần dưới thay cho bản đầu.

**Nguyên tắc.** Hook chỉ gắn vào thao tác để lại dấu vết kiểm được (một lệnh,
một file, một commit) và nhắc đúng lúc thao tác đó xảy ra. Thao tác không để lại
dấu vết — "đã đọc system profile trước khi thiết kế" — thuộc về luật trong skill;
hook nhắc chúng chỉ tốn context mỗi phiên mà không thêm gì.

**Nhắc, không chặn.** Coordinator có lý do chính đáng để làm khác (thử executor,
kiểm quota). Hook không từ chối lệnh; lỗi trong hook không làm hỏng phiên.

| Thao tác hay bị bỏ | Điểm nhắc | Dấu vết |
|---|---|---|
| Dispatch executor mà không chạy nền | Trước khi chạy lệnh Bash khởi chạy executor | Lệnh khớp mẫu và không bật chạy nền |
| Không cập nhật pointer khi công việc đã tiến | Lúc kết thúc lượt | HEAD vượt lần cập nhật pointer gần nhất từ 3 commit, pointer không có sửa đang dở; nhắc tối đa một lần mỗi HEAD |
| Version lệch giữa ba manifest (riêng repo này) | Git pre-commit | So chuỗi version |

**Chưa làm:** nhắc trước commit khi task chưa nghiệm thu — cần định nghĩa dấu
nghiệm thu mà `checkpoint-verification` ghi lại trước.

**Bỏ hẳn:** hook nạp system profile/working agreement (4.1, 4.2 bản đầu) và bộ
đếm task đã nghiệm thu nhiều phiên (4.3 bản đầu) — luật đã nằm trong skill, và
bộ đếm không quan sát được "nghiệm thu".

## 5. Monitor khi giao task bất đồng bộ

### Hiện trạng và khoảng trống

`orchestrating-executors` đã yêu cầu gắn monitor ngay khi dispatch từ commit
`fe26ffa` (2026-08-05), ưu tiên background task của harness, lưu BASE commit
và không được tuyên bố có monitor khi chưa chạy. `executor-roster` mô tả các
tín hiệu quan sát theo executor.

Khi thêm hỗ trợ Codex, commit `0168a1e` bổ sung phương án dự phòng coordinator
polling ở lượt sau nếu không có monitor. Repo hiện chưa đóng gói script monitor
dùng chung hoặc kênh gửi kết quả về phiên. Quy tắc chưa nói rõ coordinator phải
chuyển sang việc độc lập và tránh kiểm tra thường xuyên sau dispatch.

Yêu cầu này làm chặt skill hiện có, không tạo skill monitor riêng và không thêm
một trách nhiệm hook thứ tư. Công cụ hỗ trợ cụ thể được chọn ở bước triển khai.

### Hợp đồng dispatch

- Mỗi task giao executor bên ngoài phải được khởi chạy bất đồng bộ cùng monitor.
- Chỉ coi dispatch hoàn tất khi có bằng chứng executor đã khởi chạy, monitor
  đã hoạt động và kênh gửi kết quả được gắn với đúng task, lần chạy và phiên
  coordinator. Một PID hoặc lời hứa “sẽ theo dõi” là chưa đủ.
- Monitor chịu trách nhiệm chờ và báo sự kiện; coordinator chịu trách nhiệm
  quyết định, xử lý kết quả và nghiệm thu.
- Sau dispatch, coordinator tiếp tục công việc độc lập trong phạm vi và nhịp
  làm việc đã được cho phép. Nếu không còn việc độc lập, dùng cơ chế chờ sự
  kiện của harness; không tạo vòng lặp hỏi trạng thái thường xuyên.
- Không đọc log, kiểm PID hoặc hỏi executor định kỳ chỉ để biết “đã xong chưa”.
  Kiểm tra thủ công khi có tín hiệu bất thường, nghi monitor mất liên lạc hoặc
  người dùng yêu cầu tiến độ. Script monitor được phép kiểm tra định kỳ nội bộ;
  việc đó không đòi coordinator/LLM thức dậy theo mỗi chu kỳ.

### Trạng thái task và thông tin trong pointer

Thống nhất ý nghĩa trạng thái để coordinator, monitor và pointer không dùng
“xong” cho các mốc khác nhau:

| Trạng thái | Ý nghĩa |
|---|---|
| Đã giao | Đã phát yêu cầu thực thi; chưa đủ bằng chứng executor đang chạy và monitor đã gắn thành công |
| Đang chạy | Executor đã khởi chạy và hợp đồng monitor đã được xác nhận |
| Chờ nghiệm thu | Executor trả kết quả để kiểm chứng; coordinator chưa xác nhận đạt yêu cầu |
| Hoàn tất | Coordinator đã kiểm chứng và các gate áp dụng đều đạt |
| Bị chặn | Thiếu quyết định, thông tin hoặc điều kiện cần để tiếp tục |
| Thất bại | Có bằng chứng lần thực thi không đạt; cần quyết định sửa hoặc giao lại |
| Đã hủy | Task/lần chạy đã được xác nhận hủy theo quyền hạn được giao |

Luồng bình thường: **Đã giao → Đang chạy → Chờ nghiệm thu → Hoàn tất**.
Executor kết thúc với kết quả cần kiểm chứng đưa task sang chờ nghiệm thu;
kết thúc lỗi có bằng chứng được ghi là thất bại. Process biến mất, im lặng hay
exit code 0 không tự chứng minh task hoàn tất.

Coordinator xác minh sự kiện và cập nhật trạng thái. Nghiệm thu không đạt thì
ghi rõ thất bại hoặc điều kiện đang chặn và bước xử lý; khi thực thi lại phải
phân biệt lần chạy mới với lần cũ. Chỉ chuyển sang **Hoàn tất** mới được tính
vào ngưỡng số task hoàn tất của pointer; không đếm lại do thông báo gửi lặp.

Pointer là nơi ghi task đang chạy và task chờ nghiệm thu để tiếp tục công việc
qua phiên. Với mỗi task đang dở, ghi ngắn gọn: task, trạng thái, executor, mã
lần chạy, nơi nhận/đọc kết quả và bước coordinator cần làm khi kết quả về.
Nếu executor đã chạy nhưng monitor gặp lỗi, ghi đúng hai sự kiện đó; không để
nhãn trạng thái che khuất process còn hoạt động hoặc dẫn đến giao trùng.

Coordinator có thể cập nhật pointer trong lúc chờ subagent làm việc. Đây là
cơ hội cập nhật sớm, không phải đợi đủ ngưỡng task hoàn tất; cũng không cần
liên tục đánh thức coordinator chỉ để ghi lại trạng thái không đổi. Pointer
vẫn ngắn, phản ánh hiện trạng thay vì giữ toàn bộ lịch sử chuyển trạng thái.

Yêu cầu này chỉ làm rõ trạng thái và nội dung pointer; không bổ sung một lớp
phục hồi phiên riêng hoặc một hệ thống quản lý task mới.

### Thông báo và bằng chứng

- Monitor báo khi executor kết thúc, thất bại, yêu cầu quyết định hoặc vượt
  ngưỡng thời gian được cấu hình. Im lặng quá ngưỡng là cảnh báo cần xem xét,
  không tự kết luận process đã treo hoặc task đã thất bại.
- Thông báo phải nhận diện được task/lần chạy, trạng thái quan sát được và nơi
  đọc báo cáo/log; kèm exit code nếu thu được. Không cần đưa toàn bộ log vào
  ngữ cảnh coordinator.
- Có commit mới hoặc file thay đổi là bằng chứng tiến triển, không phải điều
  kiện tự đánh dấu task hoàn tất. Process thoát với mã 0 cũng chưa phải nghiệm thu.
- Sau thông báo kết thúc, coordinator thực hiện `checkpoint-verification` và
  các gate áp dụng trước khi đánh dấu task hoàn tất hoặc tính vào ngưỡng pointer.
- Kết quả phải còn truy xuất được nếu gửi thông báo lỗi hoặc phiên tạm không
  nhận được. Gửi lại không được khiến coordinator nghiệm thu hay giao task kế
  tiếp nhiều lần; sự kiện của lần chạy cũ không được nhận nhầm thành lần mới.

### Khả năng theo harness và nhịp làm việc

- Ưu tiên cơ chế background task có thông báo sẵn của harness. Với executor
  ngoài harness, phải kiểm chứng đường thông báo quay về coordinator thực tế.
- Trên Codex, `codex queue` là ứng viên đã thấy trong CLI local 0.155.1; mới
  kiểm tra help, chưa kiểm chứng giao nhận. Không coi đây là giải pháp đã chốt
  hoặc bảo đảm cho mọi phiên bản/giao diện Codex.
- Nếu không có kênh báo về hoặc monitor không khởi chạy được, nêu rõ dispatch
  chưa đáp ứng hợp đồng bất đồng bộ. Không âm thầm chuyển sang polling thường
  xuyên; áp dụng phương án dự phòng đã được dự án cho phép, hoặc hỏi lựa chọn
  nếu chưa có. Tránh khởi chạy trùng executor khi xử lý lỗi gắn monitor.
- Chế độ “dừng sau mỗi task” vẫn dừng sau nghiệm thu; không đòi coordinator ngồi
  canh executor. Quy tắc bất đồng bộ không tự cấp quyền giao thêm task hay chạy
  song song nếu working agreement chưa cho phép.

## 6. Ràng buộc chung

- Hook chỉ gắn vào thao tác để lại dấu vết kiểm được; không dò từ khóa để đoán
  agent đang thiết kế hay thực thi.
- Hook nhắc, không chặn; lỗi trong hook không làm hỏng phiên (fail open), không
  tạo vòng lặp. Một lời nhắc không phải bằng chứng agent đã làm theo.
- Giữ nguyên kiểm chứng thực tế, xác minh finding và cấm bịa kết quả.
- Skill cài được trên Claude Code và Codex; hook hiện chỉ cho Claude Code, không
  tuyên bố chạy trên Codex.
- Không đưa đường dẫn, tài khoản hoặc thông tin nội bộ của tác giả vào ví dụ
  công khai.

## 7. Đã thay đổi

| Commit | Nội dung |
|---|---|
| `2030f76`, `45772de` | Đổi tên plugin, marketplace, `using-crewmarshal`; URL repo `nguyengiatam/CrewMarshal` |
| `627626a` | `orchestrating-executors`: dispatch bất đồng bộ, cấm poll, bảng trạng thái task; roster, `pointer-handoff`, README |
| `f598cb9` | Skill `project-working-agreement`; quy ước độ chi tiết plan chuyển từ system profile sang working agreement |
| `8357604` | Hook nhắc dispatch chạy nền và cập nhật pointer; pre-commit kiểm version; profile cập nhật "có mã chạy" |

## 8. Tiêu chí nghiệm thu

Tiêu chí của bản đầu về bộ đếm pointer và hook nạp ngữ cảnh (cũ 3–7) bị bỏ cùng
thiết kế đó (xem §4). Còn lại:

| Tiêu chí | Trạng thái |
|---|---|
| Đổi tên: manifest nhất quán, cài mới chạy, skill dưới định danh mới | ✓ `claude plugin validate`; cài lại thật trên Claude Code và Codex (0.14.0) |
| Hook nhắc dispatch: lệnh vẫn chạy, model nhận lời nhắc | ✓ phiên thật `claude -p --plugin-dir .` + 17 test script |
| Hook pointer: nhắc một lần mỗi HEAD, không lặp, không nhắc khi pointer đang sửa | ✓ phiên thật + test script |
| Dự án mới được hỏi nhịp làm việc; lựa chọn dùng lại ở phiên sau | Chưa dogfood |
| Dừng từng task / làm liên tục hành xử đúng | Chưa dogfood |
| Dispatch kèm monitor, coordinator không poll, nhận kết quả đúng task/phiên | Chưa dogfood |
| Executor lỗi, exit 0, thông báo lặp không tự đánh dấu nghiệm thu | Chưa dogfood |
| Pointer ghi task đang chạy/chờ nghiệm thu trong lúc chờ | Chưa dogfood |

## 9. Quyết định

**Đã chốt:** tên CrewMarshal, marketplace `crewmarshal-marketplace`, repo đã đổi
tên · chỉ tác giả dùng, không cần migration · working agreement ở
`docs/superpowers/working-agreement.md`, nhận luôn quy ước độ chi tiết plan ·
hook chỉ Claude Code, nhắc chứ không chặn · ngưỡng pointer 3 commit, một lần mỗi
HEAD.

**Còn mở:** nhịp làm việc của chính repo này · hook nhắc commit khi task chưa
nghiệm thu (cần dấu nghiệm thu) · kênh báo kết quả dispatch trên Codex · hook
trên Codex · trần số skill.

## 10. Ngoài phạm vi

Không tự publish lên hub, đổi repo GitHub, sửa cài đặt của người dùng hoặc
triển khai hook hoặc monitor chỉ từ việc tạo spec này. Không tự commit/push pointer khi
chưa có quy ước tương ứng. Không bổ sung các workflow lớn ngoài ba trách nhiệm
hook, skill quy ước và việc làm chặt dispatch bất đồng bộ nêu trên.
