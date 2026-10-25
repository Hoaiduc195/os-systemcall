# Phân công công việc – Lab 2: System Call

Tài liệu này giúp ba thành viên chọn một phần việc chính, biết rõ cần làm gì và thống nhất cách ghép các phần. Chưa gán tên thành viên để nhóm tự đăng ký.

## Chọn phần việc

| Phần việc | Người phụ trách | Mức độ tương đối | Nội dung chính |
|---|---|---:|---|
| A. `trace` | __________________ | Trung bình | Theo dõi system call theo mask, kế thừa khi `fork`, viết lệnh user `trace`. |
| B. `sysinfo` | __________________ | Trung bình | Trả về số byte bộ nhớ trống và số tiến trình đang dùng; kiểm tra bằng `sysinfotest`. |
| C. `ptree` / `pstree` | __________________ | Khá cao | Lấy thông tin tiến trình trong kernel và dựng cây cha–con ở user space. |

Mỗi người nhận một phần làm đầu mối. Có thể hỗ trợ nhau đọc code và debug, nhưng cần ghi rõ ai chịu trách nhiệm chính và ai đóng góp phần nào để tổng hợp báo cáo cá nhân cho công bằng.

## A. `trace` – theo dõi system call

**Mục tiêu:** Thêm syscall `trace(mask)` và chương trình user `trace` để chạy một lệnh khác với các syscall đã chọn được ghi ra màn hình. Việc bật trace áp dụng cho tiến trình gọi và các tiến trình con sinh ra sau đó, không ảnh hưởng tiến trình khác.

**Công việc cần làm:**

- Đăng ký số syscall `trace` và nối đầy đủ đường gọi từ user space đến kernel.
- Bổ sung chương trình `user/trace.c`: đọc mask, gọi `trace(mask)`, rồi `exec` chương trình được truyền vào.
- Lưu mask theo từng tiến trình; khởi tạo/reset đúng khi cấp phát và tái sử dụng tiến trình.
- Khi `fork`, sao chép mask từ cha sang con.
- Trong syscall dispatcher, kiểm tra bit tương ứng, tra tên syscall an toàn và in PID, tên syscall cùng giá trị trả về.
- Thêm `_trace` vào `UPROGS` trong `src/Makefile`.

**Các file thường liên quan:** `src/kernel/proc.h`, `proc.c`, `sysproc.c`, `syscall.h`, `syscall.c`, `src/user/user.h`, `usys.pl`, `trace.c`, `src/Makefile`.

**Cách kiểm tra:**

- Trong xv6, chạy `trace 32 grep hello README`; chỉ các lệnh `read` được ghi lại.
- Chạy `trace 2147483647 grep hello README`; các syscall được chọn bởi mask được ghi lại.
- Chạy `grep hello README` bình thường; không có dòng trace.
- Chạy `trace 2 usertests forkforkfork`; kiểm tra trace của `fork` xuất hiện ở các tiến trình con.

**Hoàn thành khi:** các ví dụ trên chạy đúng; mask chỉ ảnh hưởng tiến trình liên quan và được kế thừa qua `fork`.

## B. `sysinfo` – thống kê tài nguyên hệ thống

**Mục tiêu:** Thêm syscall `sysinfo(struct sysinfo *)`, trả về số byte bộ nhớ trống (`freemem`) và số tiến trình có trạng thái khác `UNUSED` (`nproc`).

**Công việc cần làm:**

- Đọc và dùng chung định nghĩa `struct sysinfo` trong `src/kernel/sysinfo.h`.
- Đăng ký syscall `sysinfo` và khai báo/stub ở user space.
- Thêm hàm đếm bộ nhớ trống trong `src/kernel/kalloc.c`, bảo vệ việc duyệt danh sách trang trống bằng lock phù hợp.
- Thêm hàm đếm tiến trình đang dùng trong `src/kernel/proc.c`, đọc trạng thái dưới lock phù hợp.
- Cài đặt `sys_sysinfo`: lấy địa chỉ đối số, thu thập hai số liệu, dùng `copyout()` để chép struct sang user space và trả lỗi nếu con trỏ không hợp lệ.
- Bảo đảm `user/sysinfotest.c` được build như một chương trình user trong `src/Makefile`.

**Các file thường liên quan:** `src/kernel/sysinfo.h`, `kalloc.c`, `proc.c`, `sysproc.c`, `syscall.h`, `syscall.c`, `src/user/user.h`, `usys.pl`, `src/Makefile`.

**Cách kiểm tra:** chạy `sysinfotest` trong xv6; kết quả mong đợi là `sysinfotest: OK`. Bài kiểm tra cũng kiểm tra dữ liệu và con trỏ user không hợp lệ.

**Hoàn thành khi:** `freemem` được tính theo byte, `nproc` không tính tiến trình `UNUSED`, dữ liệu được chép an toàn sang user space và `sysinfotest` báo `OK`.

## C. `ptree` / `pstree` – lấy và hiển thị cây tiến trình

**Mục tiêu:** Thêm syscall `ptree(buf, max)` để trả tối đa `max` bản ghi tiến trình; viết lệnh user `pstree` để dựng quan hệ cha–con theo `ppid` và hiển thị dạng thụt lề.

Mỗi bản ghi cần các trường theo handout: `pid`, `ppid`, `state`, `memsize` (byte bộ nhớ user) và `name`. Syscall trả số bản ghi đã ghi thành công; trả `-1` nếu tham số không hợp lệ hoặc có lỗi.

**Công việc cần làm:**

- Thống nhất một định nghĩa `struct ptreeinfo` để kernel và chương trình user dùng cùng layout.
- Đăng ký syscall `ptree`, khai báo prototype và user stub.
- Trong kernel, duyệt bảng tiến trình, bỏ qua trạng thái `UNUSED`, lấy snapshot các trường cần thiết dưới lock phù hợp, giải phóng lock rồi mới chép dữ liệu sang user space bằng `copyout()`. Đọc `ppid` theo quy ước khóa parent hiện có trong kernel.
- Xử lý `buf` không hợp lệ, `max <= 0`, số tiến trình nhiều hơn `max` và giới hạn kích thước mảng.
- Viết `user/pstree.c`: gọi `ptree`, nhóm bản ghi theo `ppid`, in các root và hậu duệ với mức thụt lề tăng dần.
- Tránh đọc trường tiến trình khi không giữ lock phù hợp; không giữ lock kernel trong lúc in cây ở user space.
- Thêm `_pstree` vào `UPROGS` trong `src/Makefile`.

**Các file thường liên quan:** header mới như `src/kernel/ptree.h`, `src/kernel/proc.c`, `sysproc.c`, `syscall.h`, `syscall.c`, `src/user/user.h`, `usys.pl`, `pstree.c`, `src/Makefile`.

**Cách kiểm tra:** chạy `pstree` trong xv6; kiểm tra PID/PPID thể hiện đúng cây, mỗi tiến trình được hiển thị với các trường yêu cầu và thứ tự cha trước con. Thử thêm các đầu vào lỗi cho syscall nếu có chương trình test riêng.

**Hoàn thành khi:** dữ liệu kernel trả về đúng, các trường hợp lỗi được từ chối an toàn và `pstree` hiển thị quan hệ cha–con hợp lý. PID, state và memsize có thể thay đổi giữa các lần chạy.

## Quy ước phối hợp và tích hợp

Ba phần đều có thể chạm vào các file dùng chung dưới đây; nếu mỗi người tự thêm cùng lúc sẽ dễ trùng syscall number hoặc ghi đè thay đổi:

- `src/kernel/syscall.h` và `src/kernel/syscall.c`
- `src/user/user.h` và `src/user/usys.pl`
- `src/Makefile`
- `src/kernel/sysproc.c` và có thể `src/kernel/proc.c`

Trước khi code, cả nhóm thống nhất syscall number và chữ ký hàm. Chọn một thành viên làm đầu mối tích hợp các file dùng chung. Mỗi người có thể làm phần riêng trên branch riêng, sau đó gửi diff/commit cho đầu mối; tích hợp từng phần một, kiểm tra diff và tránh sửa lại code của thành viên khác khi merge. Không để hai người cùng thêm cùng một syscall entry hoặc cùng một mục `UPROGS`.

**Trình tự đề xuất:**

1. Cả nhóm chốt chữ ký syscall, struct dùng chung và syscall number.
2. Tích hợp `trace`, rồi `sysinfo`; GitHub Actions kiểm tra build và grader cho hai phần này.
3. Tích hợp `ptree`/`pstree`; hiện cần kiểm tra chức năng bằng cách chạy `pstree` trong xv6.
4. Chạy lại build và các kiểm tra của từng phần sau khi ghép tất cả thay đổi; xử lý xung đột ở các file dùng chung.
5. Ghi lại phần việc, các lỗi gặp phải, cách xử lý và kết quả kiểm tra để làm báo cáo.

## Checklist nộp bài theo handout

- Báo cáo ngắn gọn, không chép mã nguồn: `StudentID1_StudentID2_StudentID3_Report.pdf`. Nêu giải pháp, khó khăn và phần nào chưa hoàn thiện.
- Tệp patch/diff thể hiện thay đổi của nhóm: `StudentID1_StudentID2_StudentID3.patch`.
- Tệp ZIP source xv6 sau khi chạy `make clean`.
- Đặt tên gói theo thứ tự Student ID tăng dần: `StudentID1_StudentID2_StudentID3.zip`.
- Nộp trực tiếp trên Moodle theo yêu cầu của môn học.
- Ghi nhận đóng góp của từng người. Handout lưu ý bài làm giống nhau sẽ bị 0 điểm; nhóm cần hiểu và tự hoàn thiện giải pháp của mình.
