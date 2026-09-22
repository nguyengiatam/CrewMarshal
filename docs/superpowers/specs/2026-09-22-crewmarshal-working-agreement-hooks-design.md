# CrewMarshal: tên plugin, quy ước dự án, ba hook và monitor bất đồng bộ

**Ngày:** 2026-09-22
**Trạng thái:** Ghi nhận yêu cầu từ trao đổi; các lựa chọn chưa chốt được liệt kê riêng.
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

## 4. Ba hook theo trách nhiệm

“Ba hook” dưới đây là ba trách nhiệm người dùng yêu cầu. Việc ánh xạ sang bao
nhiêu sự kiện kỹ thuật phụ thuộc khả năng của harness và được chốt ở plan.

### 4.1. Design context — trước khi thiết kế

**Kết quả cần đạt:** agent đã đọc system profile hiện hành trước khi đưa ra
quyết định thiết kế chịu ảnh hưởng của quy mô, ưu tiên và ràng buộc.

- Áp dụng khi bắt đầu thiết kế và khi thay đổi thiết kế trong quá trình làm.
- Nếu thiếu profile hoặc thiếu thông tin quyết định, hướng agent bổ sung qua
  `concept-briefing`; không tự suy quy mô tương lai hay ưu tiên nghiệp vụ.
- Nếu profile thay đổi hoặc ngữ cảnh phiên bị mất, phải nạp lại trước quyết
  định liên quan tiếp theo.
- Không buộc việc cơ học không có quyết định thiết kế đi qua toàn bộ quy trình.

### 4.2. Working agreement — trước khi thực hiện công việc

**Kết quả cần đạt:** agent biết quy ước áp dụng trước khi thực thi hoặc giao việc.

- Nạp quy ước hiện hành, đặc biệt chế độ dừng/tiếp tục và giới hạn từng vai trò.
- Nếu chưa có quy ước, khởi tạo các lựa chọn cần thiết bằng skill mới.
- Thay đổi quy ước phải có hiệu lực ở bước liên quan tiếp theo, không giữ bản cũ
  chỉ vì đã đọc đầu phiên.
- Khi giao việc, coordinator truyền hoặc cung cấp đường truy cập phần quy ước
  liên quan cho executor/reviewer, kể cả agent ngoài harness. Hook ở phiên
  coordinator không chứng minh agent được giao việc đã nhận quy ước.

### 4.3. Pointer checkpoint — sau một lượng tiến độ

**Kết quả cần đạt:** pointer được cập nhật định kỳ khi công việc tiến triển,
không phụ thuộc hoàn toàn vào việc agent nhớ ghi lúc kết thúc.

- Có ngưỡng cấu hình theo số task hoàn tất; chỉ đếm task đã qua nghiệm thu
  theo workflow, không coi executor tự báo xong là bằng chứng nghiệm thu.
- Có thể bổ sung ngưỡng dự phòng khi không dùng task tracking, nhưng tín hiệu
  dự phòng không được diễn giải thành số task hoàn tất.
- Khi tới ngưỡng, yêu cầu agent cập nhật pointer bằng trạng thái và bằng chứng
  đang có. Script quản lý tín hiệu và bộ đếm; agent tổng hợp nội dung.
- Kiểm tra yêu cầu cập nhật còn chờ ở thời điểm chuẩn bị kết thúc lượt trả lời.
  Đây không phải giả định rằng mọi lượt trả lời là kết thúc cả phiên.
- Giữ đường dẫn pointer dự án đã chọn; mặc định hiện có là
  `docs/superpowers/STATUS.md`. Không tạo pointer thứ hai.
- Pointer phản ánh trạng thái hiện tại, ngắn và có bằng chứng; không tích lũy
  thành nhật ký. Không reset chỉ vì đã phát lời nhắc hoặc agent nói đã cập nhật.
- Duy trì quy tắc ghi ngay khi có phát hiện quan trọng; ngưỡng định kỳ không
  thay thế quy tắc này.
- Chống đếm trùng sự kiện, nhắc lặp, và vòng lặp do chính việc viết pointer.
  Tách trạng thái theo project/session; phải xét trường hợp nhiều phiên cùng
  dùng một pointer để tránh ghi đè trạng thái của nhau.

Ngưỡng **3 task**, dự phòng **30 lượt tool**, và chế độ **nhắc mềm** từng được
đề xuất nhưng chưa được người dùng chốt thành mặc định.

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

- Gắn hook với điểm vào workflow quan sát được; không chỉ dò từ khóa tự do để
  kết luận agent đang thiết kế hoặc thực thi.
- Tránh nạp lại toàn bộ tài liệu sau mỗi tool call. Phải cân bằng việc tái sử
  dụng ngữ cảnh còn hiệu lực với việc nạp lại khi tài liệu hoặc phiên thay đổi.
- Phân biệt “hook đã chạy”, “agent đã nhận ngữ cảnh” và “agent đã tuân thủ”.
  Một thông báo nhắc không phải bằng chứng đã đọc hay đã cập nhật.
- Không tạo vòng lặp vô hạn nếu thiếu file, không có quyền ghi hoặc gặp lỗi.
  Báo đúng trạng thái chưa hoàn thành, không tuyên bố đã bảo đảm checkpoint.
- Giữ nguyên kiểm chứng thực tế, xác minh finding và cấm bịa kết quả.
- Skill dùng chung tiếp tục cài được trên Claude Code và Codex. Hook cần ánh
  xạ và kiểm chứng riêng theo harness; không tuyên bố hook Claude Code tự chạy
  trên Codex. Phạm vi hook cho bản đầu còn cần chốt.
- Không đưa đường dẫn, tài khoản hoặc thông tin nội bộ riêng của tác giả vào
  ví dụ công khai.

## 7. Tác động lên bộ hiện tại

- Bổ sung skill quy ước và tích hợp vào bản đồ workflow, tài liệu sử dụng.
- Phối hợp với `concept-briefing` để tránh hỏi lặp và lẫn quy ước với profile.
- Phối hợp với `executor-context`, `orchestrating-executors` để chuyển quy ước
  đúng vai trò; với `checkpoint-verification` để xác định tiến độ đã nghiệm thu.
- Bổ sung hành vi pointer định kỳ vào `pointer-handoff`.
- Sửa `orchestrating-executors` về hợp đồng dispatch, chờ sự kiện và ngoại lệ
  kiểm tra thủ công; đồng bộ vòng lặp workflow, `executor-roster`, skill giới
  thiệu và README. Phân biệt rõ tiến triển, executor kết thúc và task nghiệm thu.
- Cập nhật system profile của chính plugin khi triển khai: các nhận định hiện
  tại “chỉ Markdown”, “không có mã chạy” và “không có test tự động” sẽ cần xét
  lại do hook có trạng thái và mã thực thi.
- Nếu đổi tên, ghi nhận thay đổi tương thích của namespace và skill giới thiệu;
  không âm thầm bỏ ràng buộc giữ tên skill trong profile hiện tại.

## 8. Tiêu chí nghiệm thu

1. Dự án mới được hỏi nhịp làm việc; lựa chọn được lưu và dùng lại ở phiên sau
   mà không hỏi lặp. Dự án có quy ước sẵn không nhận thêm bản mâu thuẫn.
2. Chế độ dừng từng task thực sự dừng sau nghiệm thu; chế độ liên tục chuyển
   tiếp trong phạm vi cho phép, vẫn hỏi khi thiếu quyết định cần thiết.
3. Một thiết kế có đánh đổi được chứng minh đã dùng profile trước khi quyết
   định; trường hợp thiếu profile dẫn tới bổ sung, không suy đoán âm thầm.
4. Khi profile hoặc quy ước thay đổi giữa phiên, bước liên quan tiếp theo dùng
   bản mới. Executor/reviewer nhận đúng quy ước theo vai trò.
5. Đạt ngưỡng tiến độ sinh yêu cầu cập nhật pointer; nội dung cập nhật chứa
   trạng thái, bằng chứng và bước tiếp theo đúng với công việc đã quan sát.
6. Sự kiện lặp, nhiều phiên, thao tác cập nhật pointer và task chưa nghiệm thu
   không làm bộ đếm hoặc nội dung pointer sai lệch.
7. Không có lời nhắc liên tục khi chưa phát sinh tiến độ mới. Lỗi đọc/ghi không
   gây lặp vô hạn hoặc báo sai rằng checkpoint đã hoàn thành.
8. Kiểm chứng qua phiên thực tế cho các điểm vào workflow được hỗ trợ, ngoài
   kiểm tra script riêng lẻ; tài liệu nêu rõ phạm vi hỗ trợ mỗi harness.
9. Nếu áp dụng đổi tên: manifest nhất quán, cài mới hoạt động, skill xuất hiện
   dưới định danh mới và hướng dẫn chuyển từ bản cũ có thể thực hiện được.
10. Trong phiên thực tế, coordinator dispatch executor kèm monitor, chuyển
    sang việc độc lập hoặc chờ sự kiện, rồi nhận kết quả đúng task/phiên mà
    không liên tục gọi tool kiểm PID/log. Kiểm cả lúc coordinator đang làm
    việc và lúc đang chờ trên từng harness được tuyên bố hỗ trợ.
11. Executor kết thúc lỗi, yêu cầu quyết định và vượt ngưỡng thời gian tạo đúng
    thông báo; commit mới và exit code 0 không tự đánh dấu task đã nghiệm thu.
12. Mất kênh báo, monitor không khởi chạy, thông báo lặp và sự kiện từ lần chạy
    cũ không gây báo thành công giả, mất kết quả hoặc dispatch trùng. Chế độ
    dừng từng task vẫn được giữ khi nhận kết quả bất đồng bộ.
13. Pointer ghi được task đang chạy và task chờ nghiệm thu cùng executor,
    mã lần chạy, nơi đọc kết quả và bước tiếp theo ngay trong lúc chờ subagent,
    trước khi đạt ngưỡng task hoàn tất. Task chỉ được tính hoàn tất sau nghiệm
    thu; nghiệm thu không đạt và thông báo lặp không làm tăng sai bộ đếm.

## 9. Lựa chọn cần chốt trước phần triển khai tương ứng

- Tên phát hành CrewMarshal, tên marketplace và có đổi repo GitHub hay không.
- Tên cuối cùng và nơi lưu mặc định của working agreement.
- Hook bản đầu dành cho Claude Code hay phải hỗ trợ thêm Codex ngay.
- Ngưỡng pointer, có dùng tín hiệu dự phòng không, và nhắc mềm hay bắt buộc
  xử lý trước khi chuyển việc/kết thúc lượt.
- Các điểm vào workflow được hỗ trợ và cách xử lý đường đi không qua skill.
- Kênh thông báo monitor cho từng harness, ngưỡng cảnh báo và phương án dự
  phòng khi không hỗ trợ bất đồng bộ; kiểm chứng khả năng trước khi chốt.

## 10. Ngoài phạm vi

Không tự publish lên hub, đổi repo GitHub, sửa cài đặt của người dùng hoặc
triển khai hook hoặc monitor chỉ từ việc tạo spec này. Không tự commit/push pointer khi
chưa có quy ước tương ứng. Không bổ sung các workflow lớn ngoài ba trách nhiệm
hook, skill quy ước và việc làm chặt dispatch bất đồng bộ nêu trên.
