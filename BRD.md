  

# **VIETDIST CORPORATION**

# **BUSINESS REQUIREMENT DOCUMENT**

## **Dự án Tích hợp Dữ liệu & Báo cáo Toàn diện**

*Sales Performance & Distribution Analytics Platform*

# **1\. TỔNG QUAN DỰ ÁN**

## **1.1. Bối cảnh & Mục tiêu**

VietDist Corporation là công ty thương mại – phân phối hàng tiêu dùng nhanh (FMCG) hoạt động trên 3 miền, với đội ngũ hơn 200 nhân viên kinh doanh và mạng lưới hơn 1.500 nhà phân phối/đại lý. Hiện tại, dữ liệu kinh doanh được lưu trữ phân tán tại nhiều nguồn khác nhau bao gồm file Excel gửi qua email, báo cáo thủ công từ phần mềm ERP cũ, và dữ liệu lưu tại Google Drive / OneDrive của từng phòng ban.

Ban lãnh đạo yêu cầu xây dựng một hệ thống báo cáo thống nhất, tự động hóa việc tổng hợp dữ liệu, và cung cấp các báo cáo phân tích hiệu quả kinh doanh theo thời gian thực – phục vụ cho hai bộ phận kinh doanh chính:

* Phòng Kinh doanh Trực tiếp (Branch A – Sales Direct)  
* Phòng Phân phối & Kênh (Branch B – Distribution & Channel)

## **1.2. Phạm vi dự án**

| Hạng mục | Mô tả | Trong phạm vi |
| :---- | :---- | :---- |
| Dữ liệu nguồn | File Excel/CSV trên Google Drive & OneDrive của các phòng ban | Có |
| ETL & Tích hợp | Tự động lấy, làm sạch, và tải dữ liệu lên data warehouse cục bộ | Có |
| Data Warehouse | Triển khai trên localhost (PostgreSQL / DuckDB) | Có |
| Báo cáo & Dashboard | Power BI Desktop – publish to Power BI Service (free tier) | Có |
| Kết nối hệ thống ERP cũ | Xuất file CSV định kỳ từ ERP (không kết nối trực tiếp) | Giới hạn |
| Real-time streaming | Không áp dụng trong giai đoạn 1 | Không |
| Mobile App | Không áp dụng trong giai đoạn 1 | Không |

## **1.3. Các bên liên quan**

| Vai trò | Tên / Bộ phận | Trách nhiệm trong dự án |
| :---- | :---- | :---- |
| Project Sponsor | Giám đốc Kinh doanh | Phê duyệt ngân sách, phê duyệt BRD |
| Business Owner – Branch A | Trưởng phòng Kinh doanh Trực tiếp | Đề xuất yêu cầu báo cáo Sales |
| Business Owner – Branch B | Trưởng phòng Phân phối & Kênh | Đề xuất yêu cầu báo cáo Distribution |
| Data Steward | Phòng Hành chính – Kế toán | Cung cấp dữ liệu nguồn, xác nhận dữ liệu |
| Analytics Engineer | IT / Data Team | Thiết kế, xây dựng và vận hành hệ thống |
| End User | Giám đốc vùng, Trưởng nhóm sales | Sử dụng báo cáo trên Power BI |

# **2\. MÔ TẢ DỮ LIỆU NGUỒN**

Toàn bộ dữ liệu nguồn được lưu trữ dưới dạng file phẳng (flat file) trên các nền tảng lưu trữ đám mây miễn phí. Dữ liệu được cập nhật theo lịch định kỳ bởi các nhân viên phụ trách từng phòng ban.

## **2.1. Danh sách nguồn dữ liệu**

| Mã nguồn | Tên nguồn / File | Nền tảng | Định dạng | Tần suất cập nhật | Phòng ban |
| :---- | :---- | :---- | :---- | :---- | :---- |
| SRC-01 | sales\_transactions | Google Drive | CSV | Hằng ngày (T+1) | Kinh doanh |
| SRC-02 | sales\_target\_plan | OneDrive | XLSX | Đầu năm / Điều chỉnh | Kinh doanh |
| SRC-03 | customer\_master | Google Drive | CSV | Hàng tuần | Kinh doanh |
| SRC-04 | product\_master | OneDrive | XLSM | Hàng tháng | Kế toán |
| SRC-05 | distributor\_orders | Google Drive | XLSB | Hằng ngày (T+1) | Phân phối |
| SRC-06 | distributor\_master | Google Drive | CSV | Hàng tuần | Phân phối |
| SRC-07 | employee\_master | OneDrive | XLSX | Khi có thay đổi | HR |
| SRC-08 | territory\_mapping | OneDrive | XLSX | Hàng quý | Kinh doanh |
| SRC-09 | return\_transactions | Google Drive | CSV | Hằng ngày (T+1) | Kinh doanh |
| SRC-10 | promotion\_program | OneDrive | XLSX | Khi có chương trình | Marketing |

## **2.2. Ghi chú đặc biệt về dữ liệu nguồn**

| ⚠  LƯU Ý QUAN TRỌNG – File Sales Target Plan (SRC-02) File kế hoạch target bán hàng sẽ có NHIỀU PHIÊN BẢN trong năm. Mỗi phiên bản là một sheet riêng hoặc một file riêng được upload lên thư mục tương ứng. Hệ thống phải lưu giữ toàn bộ lịch sử các phiên bản và phải biết phiên bản nào đang có hiệu lực tại từng thời điểm trong năm. Không được ghi đè phiên bản cũ. |
| :---- |

| ⚠  LƯU Ý – Nhân viên thay đổi vùng/nhóm (SRC-07, SRC-08) Nhân viên có thể được chuyển vùng, đổi nhóm, hoặc thay đổi cấp bậc trong năm. Hệ thống cần ghi nhận thông tin nhân viên theo thời gian để đảm bảo báo cáo lịch sử vẫn chính xác theo cấu trúc tổ chức tại thời điểm phát sinh giao dịch. |
| :---- |

# **3\. YÊU CẦU NGHIỆP VỤ – BRANCH A: KINH DOANH TRỰC TIẾP**

**Đầu mối yêu cầu**: Bà Nguyễn Thị Hương – Trưởng phòng Kinh doanh Trực tiếp  
Phòng kinh doanh trực tiếp quản lý đội ngũ hơn 150 nhân viên bán hàng (Sales Representative – SR) được phân chia theo vùng địa lý (Miền Bắc, Miền Trung, Miền Nam) và theo nhóm sản phẩm. Phòng yêu cầu hệ thống báo cáo đáp ứng các nhu cầu sau:

## **3.1. Báo cáo Tổng quan Hiệu suất Kinh doanh (BR-A-01)**

**Mô tả yêu cầu từ phía business:**

| Thuộc tính | Nội dung |
| :---- | :---- |
| **Tên báo cáo** | Sales Performance Overview – Tổng quan KPI Bán hàng |
| **Người yêu cầu** | Trưởng phòng KD, Giám đốc vùng, Ban Giám đốc |
| **Mục đích sử dụng** | Theo dõi tình hình đạt KPI của từng nhân viên, từng nhóm, từng vùng so với kế hoạch đặt ra từ đầu năm hoặc bản kế hoạch điều chỉnh mới nhất |
| **Tần suất xem** | Hằng ngày, hàng tuần, hàng tháng, hàng quý |
| **Cập nhật dữ liệu** | Dữ liệu cập nhật vào sáng sớm hàng ngày (trước 7:00 AM) phản ánh số liệu đến cuối ngày hôm trước |

**Yêu cầu chi tiết từ phía business (nguyên văn ghi nhận):**

* Chúng tôi muốn thấy mỗi nhân viên bán được bao nhiêu, so với chỉ tiêu được giao. Chỉ tiêu ở đây là chỉ tiêu mới nhất, nhưng nếu cần xem thì cũng muốn so sánh được với bản kế hoạch đầu năm.  
* Cần xem so sánh cùng kỳ năm trước – tức là doanh số tháng này so với tháng này năm ngoái, quý này so với quý năm ngoái.  
* Muốn lọc theo vùng, theo nhóm, theo sản phẩm, theo nhân viên.  
* Cần thấy tỷ lệ hoàn thành (% achieve) rõ ràng, màu sắc để dễ nhìn – xanh là đạt, đỏ là không đạt.  
* Nếu nhân viên đang đi đúng hướng thì cần có dự báo là cuối tháng/quý sẽ đạt bao nhiêu phần trăm.

| 📋  GHI CHÚ PHÂN TÍCH – Yêu cầu cần làm rõ "So sánh cùng kỳ năm trước": Business chưa xác định rõ (1) Năm tài chính hay năm dương lịch? (2) Cùng kỳ tháng, quý, hay lũy kế YTD? (3) Cách xử lý khi tháng có số ngày khác nhau (ví dụ tháng 2). Analytics Engineer cần tổ chức buổi họp làm rõ trước khi thiết kế data model. |
| :---- |

| 📋  GHI CHÚ PHÂN TÍCH – Yêu cầu đã làm rõ sau khi bổ sung "So sánh cùng kỳ năm trước": Yêu cầu (1):  Cần có cả 2 loại năm để người dùng sử dụng. Năm tài chính được tính từ 01/09 năm trước đến hết 31/08 năm sau. Năm dương lịch được tính từ 01/01 đến hết 31/12 (2) Cùng kỳ tháng, quý, hay lũy kế YTD: Cần xem được cả theo tháng, quý và luỹ kế YTD (3) Cách xử lý khi tháng có số ngày khác nhau (ví dụ tháng 2): Nếu năm hiện tại có ngày 29, thì năm trước lấy tới ngày 28, không cần lấy ngày 29\. |
| :---- |

**Thông tin chi tiết cần hiển thị trên báo cáo:**

| Chỉ số (Metric) | Mô tả nghiệp vụ | Ghi chú kỹ thuật |
| :---- | :---- | :---- |
| Doanh thu thực tế (Actual Revenue) | Tổng doanh thu từ đơn hàng đã giao thành công, đã trừ hàng trả về | Net Revenue \= Gross Revenue – Returns |
| Chỉ tiêu (Target) | Chỉ tiêu theo phiên bản kế hoạch hiện hành (latest version) | SCD Type 2 / Temporal Fact |
| % Hoàn thành (Achieve %) | Actual / Target × 100% | Cần xử lý chia cho 0 khi Target \= 0 |
| Tăng trưởng YoY (%) | So sánh với cùng kỳ năm trước (cần làm rõ) | Xem ghi chú làm rõ phía trên |
| Dự báo cuối kỳ (Forecast) | Dựa trên tiến độ hiện tại và số ngày còn lại | Phương pháp linear extrapolation trên Power BI.  Confident threshold: 95% |
| Hàng trả về (Return) | Số lượng và giá trị hàng bị trả lại trong kỳ | Kết nối SRC-09 |
| Số khách hàng đã bán (Active Customers) | Số customer distinct đã có giao dịch trong kỳ | COUNT DISTINCT CustomerID |

## **3.2. Báo cáo Phân tích Kế hoạch Bán hàng theo Phiên bản (BR-A-02)**

Đây là yêu cầu đặc biệt quan trọng và phức tạp nhất từ Branch A. Phòng kinh doanh trực tiếp quản lý chỉ tiêu bán hàng theo cơ chế nhiều phiên bản trong năm.

**Cơ chế phiên bản kế hoạch (nguyên văn từ Trưởng phòng KD):**

| Phiên bản | Thời điểm ban hành | Hiệu lực từ | Mô tả |
| :---- | :---- | :---- | :---- |
| **Plan v1** | Tháng 01 đầu năm | 01/01 – 30/06 | Kế hoạch đầu năm cho toàn bộ 12 tháng. Được duyệt bởi BGĐ tại họp chiến lược tháng 1\. |
| **Plan v2** | Tháng 07 (sau kết thúc H1) | 01/07 – 30/09 | Bản điều chỉnh sau khi đánh giá kết quả 6 tháng đầu năm. Chỉ điều chỉnh cho 6 tháng cuối năm. |
| **Plan v3** | Tháng 10 (sau kết thúc Q3) | 01/10 – 31/12 | Bản điều chỉnh lần 2 sau khi đánh giá Q3. Chỉ điều chỉnh cho Q4. |
| **Plan v4+** | Có thể phát sinh | TBD | Hệ thống phải hỗ trợ không giới hạn số phiên bản. Không được thiết kế cứng số lượng version. |

**Yêu cầu hiển thị trên báo cáo (nguyên văn):**

* Muốn so sánh kết quả thực tế với từng phiên bản kế hoạch: thực tế so v1, thực tế so v2 (nếu đã có), thực tế so v3 (nếu đã có).  
* Khi nhìn vào bất kỳ tháng nào trong năm, tôi muốn thấy rõ: tháng đó đang áp dụng kế hoạch phiên bản nào, số chỉ tiêu là bao nhiêu.  
* Chỉ tiêu được phân bổ theo từng nhân viên, theo từng tháng. Mỗi nhân viên sẽ nhận được file chỉ tiêu riêng.  
* Khi có bản điều chỉnh mới, chúng tôi không muốn mất dữ liệu kế hoạch cũ – cần giữ lại lịch sử để kiểm tra.

| ⚠  GHI CHÚ KỸ THUẬT – Temporal Fact Table & SCD Yêu cầu này đòi hỏi thiết kế Temporal Fact Table cho bảng Target: mỗi bản ghi Target cần có các trường (EffectiveDate, ExpiryDate, VersionCode, IsLatest). Khi có phiên bản mới, cần đóng (expire) bản ghi cũ và tạo bản ghi mới. Đây là bài toán Slowly Changing Dimension Type 2 áp dụng cho Fact Table – không phải Dimension Table thông thường. |
| :---- |

## **3.3. Báo cáo Phân tích Khách hàng & Sản phẩm (BR-A-03)**

**Yêu cầu từ Trưởng phòng KD (nguyên văn):**

* Tôi muốn biết sản phẩm nào đang bán chạy, sản phẩm nào đang bị chậm. Xem được theo tháng, theo quý.  
* Muốn xem khách hàng nào mua nhiều nhất – Top 10, Top 20 khách hàng theo doanh thu.  
* Cần thấy có bao nhiêu khách hàng mới trong tháng, bao nhiêu khách hàng cũ quay lại, bao nhiêu khách hàng không mua nữa (churn).  
* Muốn biết nhân viên nào đang phụ trách những khách hàng lớn nhất.  
* Nếu một sản phẩm có chạy chương trình khuyến mãi thì cần thấy rõ doanh thu trong kỳ KM và ngoài kỳ KM.

| 📋  GHI CHÚ PHÂN TÍCH – Định nghĩa cần làm rõ "Khách hàng mới": Cần xác định rõ là khách hàng lần đầu xuất hiện trong hệ thống, hay khách hàng chưa mua trong N tháng gần nhất (lapsed customer quay lại). "Khách hàng churn": Cần định nghĩa số tháng không có giao dịch thì được coi là churn. Business cần thống nhất trước khi thiết kế. |
| :---- |

## **3.4. Báo cáo Hành trình Nhân viên Kinh doanh (BR-A-04)**

**Yêu cầu từ Trưởng phòng KD:**

* Muốn xem lịch sử một nhân viên từ khi vào đến nay: họ đã làm ở vùng nào, nhóm nào, và kết quả bán hàng tương ứng từng giai đoạn.

* Khi nhân viên được chuyển vùng hoặc đổi nhóm, báo cáo của giai đoạn trước không được thay đổi – vẫn phải hiển thị đúng theo cấu trúc cũ.

* Muốn biết nhân viên nào đang có xu hướng tăng trưởng tốt, nhân viên nào đang sa sút.

| ⚠  GHI CHÚ KỸ THUẬT – Slowly Changing Dimension Type 2 (SCD2) Yêu cầu BR-A-04 bắt buộc áp dụng SCD Type 2 cho bảng Employee Dimension. Khi nhân viên thay đổi vùng/nhóm/cấp bậc, cần tạo bản ghi mới với StartDate/EndDate rõ ràng. Fact table phải join với Employee dimension tại thời điểm phát sinh giao dịch (snapshot key hoặc date-based lookup), không phải theo trạng thái hiện tại. |
| :---- |