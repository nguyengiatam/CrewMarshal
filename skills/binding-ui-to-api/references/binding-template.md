# Binding UI–API — Template

A section of the FE spec (`docs/specs/YYYY-MM-DD-<topic>-fe-design.md` or wherever
the FE spec lives), not a file of its own. Prose in the project's working
language. Row ids (`B1`) are what plan tasks cite — keep them stable once agreed.

---

````markdown
## Ghép UI–API

**Luồng UX:** docs/specs/<...>-ux-flow.md  ·  **Thiết kế:** <link, công cụ bất kỳ>
**Contract:** <mục contract trong spec BE | API có sẵn: tài liệu/schema + môi trường gọi thử>

### Bảng ghép
| Id | Điểm chạm · phần tử | Thao tác | Kích hoạt | Đang chờ | Thành công | Lỗi → hiển thị | Nguồn |
|----|---------------------|----------|-----------|----------|------------|----------------|-------|
| B1 | S2 · mở màn hình | lấy đơn theo id | vào trang, deep link | khung xương | hiện đơn | không tìm thấy → trang 404 · không quyền → về S1 + thông báo | flow J1 |
| B2 | S2 · nút Hủy đơn | hủy đơn | bấm, có hỏi lại | khóa nút | trạng thái *đã hủy*; S1 cập nhật | đã giao → báo "không hủy được, đơn đã giao" · lỗi hệ thống → thử lại | flow quy tắc R2 · ~ |

Nguồn: thiết kế / flow (id) / `~` coordinator tự quyết cơ chế / `CHƯA CHỐT` (đã đưa về flow).

### Dữ liệu hiển thị
| Điểm chạm · dữ liệu | Lấy từ | Ghi chú |
|---------------------|--------|---------|
| S2 · tổng tiền | `order.total` | VND, đã gồm thuế |
| S1 · "còn 2 ngày" | suy ra từ `order.dueAt` theo giờ VN | |

### Quy tắc chỉ UI chặn            (chỉ khi có)
| Quy tắc | Vì sao API không chặn | User đã quyết |
|---------|-----------------------|---------------|

### Bằng chứng API có sẵn          (chỉ khi API đã có)
| Thao tác | Ý nghĩa nghiệp vụ đã xác minh | Tác dụng phụ | Lỗi quan sát được | Bằng chứng |
|----------|-------------------------------|--------------|-------------------|------------|
| hủy đơn | chuyển *chờ giao* → *đã hủy*; trạng thái khác trả 409 | hoàn kho, gửi email | 409 `{code: ORDER_SHIPPED}` · 403 | gọi thử staging 2026-.. · `orders/service.go:142` |

### Khoảng trống                   (chỉ khi có)
| Điểm chạm cần | API có | Lựa chọn | Quyết định |
|---------------|--------|----------|------------|
| S1 lọc theo cửa hàng | không có tham số lọc | sửa API / lọc ở client (sai số đếm, trang thiếu) / bỏ khỏi flow | CHƯA CHỐT |
````
