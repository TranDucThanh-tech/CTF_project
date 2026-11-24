# Logbook - Đồ án thực hành CTF Jeopardy (UET.CN3124)
 
- **Chủ đề chính:** Mật mã học (Crypto)
- **Challenge:** `chinese-lazy-theorem-1` và `chinese-lazy-theorem-2` (LA CTF 2023, UCLA ACM)
- **Nguồn challenge:** https://github.com/uclaacm/lactf-archive (thư mục `2023/crypto/`)
- **Môi trường:** Ubuntu 26.04.1 LTS, Docker 29.10.0, Python 3.12 (trong container)
- **Repo cá nhân:** https://github.com/TranDucThanh-tech/CTF_project
---
 
## Mục 1. Kiểm tra hệ điều hành
 
- **Thời gian:** 21/11
- **Mục tiêu:** Ghi lại thông tin hệ điều hành để mô tả môi trường thực nghiệm trong báo cáo.
- **Lệnh đã chạy:**
```bash
lsb_release -a
uname -r
```
- **Kết quả:** Ubuntu 26.04.1 LTS (codename `resolute`), nhân Linux `7.0.0-43-generic`.
- **Bằng chứng:** `evidence/01-ubuntu-26-04-kernel-check.png`
- **Nhận xét:** Ubuntu 26.04 là bản rất mới, nên trước khi cài Docker cần kiểm tra kho Docker chính thức đã hỗ trợ codename `resolute` hay chưa.
---
 
## Mục 2. Cài đặt Docker
 
- **Thời gian:** 21/11
- **Mục tiêu:** Có môi trường container sạch, dễ tái hiện, thay vì cài thư viện trực tiếp lên hệ thống.
### Quyết định kỹ thuật
- Chọn **Docker** thay vì VirtualBox vì hai bài chỉ cần Python và thư viện toán/mật mã, không cần giao diện đồ họa. Dockerfile đóng vai trò tài liệu hóa môi trường và giúp chạy lại từ đầu bằng một lệnh.
- Docker được cài ở mức hệ thống (qua `apt`), không cài trong venv, vì Docker là một dịch vụ hệ thống (daemon) chứ không phải thư viện Python.
- Dùng **một image chung** cho cả hai bài vì cùng chủ đề (RSA/CRT) và cùng bộ thư viện.
### Sự cố 1: thiếu `curl`
- **Hiện tượng:** `Command 'curl' not found`.
- **Nguyên nhân:** Máy chưa cài `curl`.
- **Cách khắc phục:** `sudo apt-get update && sudo apt-get install -y curl`.
- **Bằng chứng:** `evidence/02-apt-update-curl-repo-check.png`
- **Học được:** Cấu trúc một dòng lệnh gồm quyền hạn (`sudo` = chạy bằng quyền root), chương trình (`apt-get`), hành động (`install`), tùy chọn (`-y`) và đối tượng (`curl`). `curl` là công cụ gọi URL từ terminal, độc lập với `apt` và `sudo`.
### Sự cố 2: `newgrp` không có trên Ubuntu 26.04
- **Hiện tượng:** Sau `sudo usermod -aG docker $USER`, lệnh `newgrp docker` báo `Command 'newgrp' not found`.
- **Nguyên nhân:** Trên bản Ubuntu mới, `newgrp` nằm trong gói tách riêng `util-linux-extra`.
- **Cách khắc phục:** Không cài thêm gói, mà **đăng xuất rồi đăng nhập lại** để nhóm `docker` có hiệu lực. Kiểm tra bằng `groups` thấy có `docker`.
- **Học được:** Việc thêm người dùng vào nhóm chỉ có hiệu lực với phiên đăng nhập mới.
### Kết quả
- `docker --version` cho `Docker version 29.10.0`.
- `docker run hello-world` chạy thành công, in ra `Hello from Docker!`. Lần đầu Docker tự tải image `hello-world` từ Docker Hub.
- **Bằng chứng:** `evidence/03-docker-gpg-repo-install-start.png`, `evidence/04-docker-packages-installed.png`, `evidence/05-docker-hello-world-verify.png`
---
 
## Mục 3. Tạo cấu trúc dự án và lấy challenge
 
- **Thời gian:** 21/11
- **Mục tiêu:** Có thư mục làm việc gọn gàng, tách riêng đề bài, script, bằng chứng và báo cáo.
- **Lệnh đã chạy:**
```bash
mkdir -p ~/Documents/CTF_Project/{challenges,scripts,evidence,report}
cd ~/Documents/CTF_Project
touch logbook.md
cd challenges
git clone https://github.com/uclaacm/lactf-archive.git
find lactf-archive -type d -name "chinese-lazy-theorem*"
```
- **Kết quả:** Hai bài nằm tại
  - `lactf-archive/2023/crypto/chinese-lazy-theorem-1`
  - `lactf-archive/2023/crypto/chinese-lazy-theorem-2`
- **Bằng chứng:** `evidence/06-ctf-project-workspace-init.png`, `evidence/07-git-clone-lactf-chinese-lazy-theorem.png`
### Sự cố 3: gõ nguyên dấu `<...>` trong lệnh `cp`
- **Hiện tượng:** `bash: /.: Is a directory`.
- **Nguyên nhân:** Tôi gõ cả dấu `<` `>` của phần hướng dẫn. Trong bash, `<` là toán tử chuyển hướng đầu vào, còn `<đường-dẫn>` trong tài liệu chỉ là chỗ để thay bằng giá trị thật. Ngoài ra tôi còn nhầm bài 2 vào thư mục `clt1`.
- **Cách khắc phục:** Dùng đường dẫn thật, đúng bài đúng thư mục:
```bash
mkdir -p clt1 clt2
cp -r lactf-archive/2023/crypto/chinese-lazy-theorem-1/. clt1/
cp -r lactf-archive/2023/crypto/chinese-lazy-theorem-2/. clt2/
ls -R clt1 clt2
```
- **Học được:** `cp -r` copy đệ quy thư mục; đuôi `/.` nghĩa là copy nội dung bên trong (kể cả file ẩn) mà không tạo thêm một tầng thư mục; `ls -R` chỉ để kiểm tra.
- **Quyết định:** Làm việc trên bản copy `clt1`, `clt2`, không sửa trực tiếp repo `lactf-archive` để repo gốc luôn sạch.
---
 
## Mục 4. Git và GitHub
 
- **Thời gian:** 21/11
- **Mục tiêu:** Lưu lịch sử làm việc làm bằng chứng quá trình, đồng thời sao lưu lên GitHub.
- **Lệnh đã chạy:**
```bash
git init
echo "challenges/lactf-archive/" > .gitignore
git add .
git commit -m "Khoi tao du an CTF: Dockerfile, scripts, logbook"
```
 
### Quyết định kỹ thuật
- Không đưa `challenges/lactf-archive/` lên repo của mình, vì đó là repo của người khác (có `.git` riêng, dung lượng lớn, và cần tôn trọng quyền tác giả). Ai muốn tái hiện chỉ cần clone lại theo link trong README.
- Giữ repo ở chế độ Private cho tới khi nộp bài.
### Sự cố 4: nhầm `git clone` với `git remote add`
- **Hiện tượng:** Chạy `git clone` repo GitHub trống ngay trong thư mục dự án, tạo ra thư mục lồng `CTF_project`.
- **Nguyên nhân:** Repo cục bộ đã có sẵn (do `git init`), cái cần làm là **kết nối** nó với GitHub chứ không phải tải một repo mới về.
- **Cách khắc phục:**
```bash
rm -rf CTF_project
git branch -M main
git remote add origin https://github.com/TranDucThanh-tech/CTF_project.git
```
 
### Sự cố 5: xác thực GitHub thất bại
- **Hiện tượng:** `remote: Invalid username or token. Password authentication is not supported for Git operations.`
- **Nguyên nhân:** Lần đầu nhập sai Username (đúng phải là tên tài khoản GitHub), và GitHub không còn chấp nhận mật khẩu tài khoản cho thao tác Git qua HTTPS.
- **Cách khắc phục:** Tạo Personal Access Token (Fine-grained, chỉ cấp quyền Contents: Read and write cho repo `CTF_project`) và dùng token thay cho mật khẩu.
- **Lưu ý an toàn:** Token là bí mật, không ghi vào logbook, không đưa vào ảnh chụp màn hình.
- **Học được:** Git chạy cục bộ (`init`, `add`, `commit`), còn GitHub là nơi lưu trữ từ xa. `remote` đặt tên (`origin`) cho địa chỉ, `push` gửi commit lên, và cần bước xác thực (token hoặc SSH key).
### Việc cần kiểm tra
- [ ] Hai file PDF trong `report/` (`Lựa_chọn.pdf`, `Định_lý_số_dư_trung_hoa.pdf`) là tài liệu do tôi tự viết hay tài liệu của người khác? Nếu của người khác thì gỡ khỏi Git (`git rm --cached`) và ghi nguồn.
- [ ] Ảnh trong `evidence/` có lộ thông tin nhạy cảm không.
---
 
## Mục 5. Dựng môi trường Docker cho bài Crypto
 
- **Thời gian:** 24/11
- **Mục tiêu:** Có image `ctf-crypto` chứa Python và các thư viện cần cho RSA/CRT.
- **Dockerfile:**
```dockerfile
FROM python:3.12-slim
 
RUN pip install --no-cache-dir pycryptodome sympy gmpy2
 
WORKDIR /work
CMD ["bash"]
```
- **Lệnh build và chạy:**
```bash
docker build -t ctf-crypto .
docker run -it --rm -v "$PWD":/work ctf-crypto
```
  `-v "$PWD":/work` gắn thư mục dự án vào container; `--rm` xóa container khi thoát nên mỗi lần chạy đều là môi trường sạch.
 
### Sự cố 6: Dockerfile bị chèn dòng rác
- **Hiện tượng:** `ERROR: Invalid requirement: 'python:3.12-slim'`, dòng lỗi `Dockerfile:2` là `RUN pip install --no-cache-dir pycrytodomeFROM python:3.12-slim`.
- **Nguyên nhân:** Khi soạn trong nano, nội dung bị chèn lẫn (thiếu chữ `p` trong `pycryptodome` và dính liền với dòng `FROM`). Pip hiểu `python:3.12-slim` là tên một gói.
- **Cách khắc phục:** Sửa lại file cho đúng nội dung ở trên (ghi lại bằng `cat > Dockerfile << 'EOF'` hoặc sửa trong trình soạn thảo).
- **Học được:** Khi `docker build` lỗi, đọc đoạn có dấu `>>>` trước tiên vì nó chỉ đúng dòng sai.
### Sự cố 7: `pull access denied for ctf-crypto`
- **Hiện tượng:** `docker run ... ctf-crypto` báo `repository does not exist or may require 'docker login'`.
- **Nguyên nhân:** Image chưa được build (lần build trước thất bại, sau khi sửa Dockerfile tôi chưa build lại). Docker không tìm thấy image cục bộ nên đi tìm trên Docker Hub.
- **Cách khắc phục:** Chạy lại `docker build -t ctf-crypto .`, kiểm tra bằng `docker images`.
- **Học được:** Sửa Dockerfile không tự cập nhật image. Image là bản đóng gói tại thời điểm build, Dockerfile chỉ là công thức, nên mỗi lần sửa phải build lại.
### Sự cố 8: image thừa do gõ sai tên
- **Hiện tượng:** `docker images` hiện cả `ctf-crypto` và `ctf-cryto`.
- **Nguyên nhân:** Lần build trước tôi gõ sai tên thành `ctf-cryto`.
- **Cách khắc phục:** `docker rmi ctf-cryto`.
### Kết quả
- Build thành công image `ctf-crypto:latest` (~324MB dung lượng đĩa, ~74MB nội dung nén).
- Dòng `CACHED [2/3] RUN pip install ...` cho thấy Docker dùng lại layer đã build ở lần trước, đúng với cơ chế layer.
- **Bằng chứng:** [điền tên ảnh `docker build` và `docker images` trong `evidence/`]
---
 
## Mục 6. Phân tích sơ bộ bài 1 (`chinese-lazy-theorem-1`)
 
- **Thời gian:** 24/11
- **Trạng thái:** Chưa thực hiện.
- **Việc cần làm:**
  1. Chạy `ls -la` và `cat chall.py` trong `challenges/clt1`.
  2. Tự trả lời bằng lời của mình:
     - Chương trình sinh dữ liệu / mã hóa như thế nào?
     - Tôi được cho những giá trị nào (n, e, c, ...)?
     - Flag đang được giấu ở đâu, và cần tìm đại lượng nào để lấy ra?
  3. Ghi giả thuyết ban đầu, kể cả khi sau này sai.
### Giả thuyết ban đầu
_(điền sau khi đọc đề)_
 
---
 
## Mục 7. Giải bài 1
 
_(điền sau)_
 
## Mục 8. Giải bài 2
 
_(điền sau)_
 
## Mục 9. Phần tùy biến / mở rộng
 
_(điền sau: ví dụ viết lại script tổng quát, tái hiện cục bộ, so sánh hai cách giải, đề xuất biện pháp phòng thủ)_
 
## Mục 10. Tài liệu tham khảo đã dùng
 
| Nguồn | Dùng để làm gì | Đã diễn giải bằng lời của mình? |
|---|---|---|
| LA CTF 2023 archive (uclaacm/lactf-archive) | Lấy file challenge | - |
| CTFtime event 1732 | Thông tin cuộc thi | - |
| _(thêm writeup, blog, tài liệu khác nếu xem)_ | | |
 
---
 
## Tổng hợp thời gian làm việc
 
| Mục | Số giờ |
|---|---|
| 1-5. Thiết lập môi trường, Git, Docker | [số giờ] |
| 6-8. Phân tích và giải bài | |
| 9. Mở rộng | |
| Viết báo cáo | |
| **Tổng** | |
 
