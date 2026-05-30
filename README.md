# 🏪 Otaku Store - Mini ERP

Hệ thống quản lý bán hàng (Mini ERP) dành cho cửa hàng "Otaku Store". Dự án hỗ trợ Quản lý kho, hệ thống POS bán hàng và phân quyền bảo mật (RBAC) chặt chẽ giữa Admin và Employee.

## 🚀 Live Demo & Tài khoản Test

Sản phẩm đã được triển khai thực tế trên môi trường Staging:
- **Đường dẫn hệ thống:** [https://task-hamsa.web.app](https://task-hamsa.web.app)

**Tài khoản kiểm thử (Test Accounts):**
| Vai trò (Role) | Email | Mật khẩu (Password) | Phân quyền (Permissions) |
| :--- | :--- | :--- | :--- |
| **Admin** | `admin@otakustore.com` | `admin123456` | Toàn quyền (Quản lý User, Product, Order) |
| **Employee** | `chien@gmail.com` | `123456` | Xem kho, Tạo đơn hàng, Cập nhật thông tin cá nhân |

## 🛠️ Ngăn xếp Công nghệ (Built With)

- **Frontend:** [Flutter](https://flutter.dev/) (Web)
- **Backend (BaaS):** [Firebase](https://firebase.google.com/)
  - **Database:** Cloud Firestore
  - **Authentication:** Firebase Auth
  - **Hosting:** Firebase Hosting

## 📋 Yêu cầu hệ thống (Prerequisites)

Để chạy dự án ở môi trường Local, bạn cần cài đặt sẵn:
- [Flutter SDK](https://docs.flutter.dev/get-started/install) 
- [Node.js & npm](https://nodejs.org/)
- [Firebase CLI](https://firebase.google.com/docs/cli) (Cài qua lệnh `npm install -g firebase-tools`)

## 💻 Hướng dẫn chạy nội bộ (Run Locally)

1. Clone mã nguồn về máy:
   ```bash
   git clone <link-repo-cua-ban>
   cd task-hamsa
   ```

2. Tải các thư viện (dependencies) cần thiết:
   ```bash
   flutter pub get
   ```

3. Chạy ứng dụng trên trình duyệt Chrome:
   ```bash
   flutter run -d chrome
   ```

## 🌐 Đóng gói và Triển khai (Build & Deploy)

1. Biên dịch mã nguồn cho nền tảng Web:
   ```bash
   flutter clean
   flutter pub get
   flutter build web
   ```
   *Quá trình này sẽ sinh ra thư mục `build/web` chứa toàn bộ code tĩnh.*

2. Tải bản build lên Firebase Hosting:
   ```bash
   firebase deploy --only hosting
   ```
