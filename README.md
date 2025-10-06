# 📦 WareSystem v2 - Enterprise Resource Planning (ERP) Application

> **Sistem Manajemen Gudang dan ERP Terintegrasi dengan AI/ML untuk Optimasi Bisnis**

## 🎯 Deskripsi Aplikasi

WareSystem v2 adalah aplikasi ERP (Enterprise Resource Planning) berbasis Flutter yang dirancang khusus untuk manajemen gudang, inventori, transaksi, dan keuangan dengan dukungan AI/ML untuk prediksi dan analisis bisnis. Aplikasi ini mengintegrasikan Firebase sebagai backend dan TensorFlow Lite untuk machine learning.

## 🚀 Fitur Utama

### 📊 **1. Monitoring & Dashboard**
- **Real-time Dashboard**: Ringkasan transaksi, stok, dan performa bisnis
- **Analytics Charts**: Grafik penjualan mingguan, status order (Line Chart & Pie Chart)
- **Activity Logs**: Tracking semua aktivitas user dan sistem
- **System Status**: Monitoring koneksi Firebase dan status server
- **Smart Notifications**: Alert untuk stok menipis, transaksi gagal, dll
- **AI Insights**: Prediksi dan rekomendasi berbasis machine learning

### 📦 **2. Inventory Management**
- **Product Management**: CRUD produk dengan kategori, SKU, dan gambar
- **Stock Tracking**: Monitoring stok real-time dengan minimum stock alerts
- **Stock Mutations**: Pencatatan stok masuk/keluar dengan history lengkap
- **Barcode/QR Scanner**: Scanning produk untuk input cepat
- **Multi-category Support**: Organisasi produk berdasarkan kategori
- **Image Management**: Upload dan manajemen gambar produk

### 💰 **3. Financial Management**
- **Transaction Recording**: Pencatatan penjualan dan pembelian
- **Budget Planning**: Perencanaan dan tracking budget
- **Financial Reports**: Laporan keuangan komprehensif
- **Payment Tracking**: Monitoring status pembayaran (Cash, Transfer, QRIS)
- **Profit Analysis**: Analisis keuntungan per produk/kategori
- **Export Reports**: Export laporan ke PDF dan Excel

### 🛒 **4. Transaction Management**
- **Sales & Purchase**: Manajemen transaksi penjualan dan pembelian
- **Multi-item Transactions**: Support transaksi dengan multiple produk
- **Payment Methods**: Cash, Transfer Bank, QRIS, dan lainnya
- **Transaction Status**: Tracking status (Pending, Completed, Cancelled)
- **Customer/Vendor Management**: Database pelanggan dan supplier
- **Invoice Generation**: Generate invoice otomatis

### 🤖 **5. AI Chatbot Assistant**
- **Google Gemini AI Integration** - Powered by advanced AI untuk business insights
- **Intelligent Business Analysis** - Analisis data inventory, keuangan, dan transaksi
- **Image & Document Analysis** - Upload dan analisis gambar/dokumen bisnis
- **Predictive Insights** - Prediksi bisnis dan rekomendasi strategis
- **Context-Aware Conversations** - Chat yang memahami konteks bisnis Anda
- **Multi-Modal Support** - Text dan image input dengan respons yang akurat
- **Floating Chat Interface** - Akses mudah dari semua screen dengan floating bubble
- **Real-time Notifications** - Notifikasi untuk pesan baru dan insights penting

### 🧠 **6. AI/ML Features**
- **Sales Prediction**: Prediksi penjualan menggunakan TensorFlow Lite
- **Stock Optimization**: Rekomendasi stok optimal berdasarkan historical data
- **Financial Forecasting**: Prediksi keuangan dan cash flow
- **Demand Forecasting**: Prediksi permintaan produk
- **Smart Alerts**: Notifikasi cerdas berdasarkan pattern recognition
- **Business Intelligence**: Insights dan rekomendasi bisnis

### 📱 **7. User Management & Authentication**
- **Multi-platform Auth**: Email/Password, Google Sign-In, Apple Sign-In
- **Role-based Access**: User dan Admin dengan permission berbeda
- **Profile Management**: Manajemen profil user
- **Activity Tracking**: Log semua aktivitas user
- **Secure Authentication**: Firebase Auth dengan biometric support

### 📰 **8. News & Information**
- **Business News**: Agregasi berita bisnis dan ekonomi
- **Market Updates**: Update pasar dan trend industri
- **News Categories**: Kategorisasi berita berdasarkan topik

## 🏗️ Arsitektur Teknis

### **Frontend Architecture**
```
lib/
├── constants/          # Theme dan konstanta aplikasi
├── models/            # Data models (Product, Transaction, Finance, etc.)
├── providers/         # State management dengan Provider pattern
├── screens/           # UI screens terorganisir per modul
│   ├── monitoring/    # Dashboard dan monitoring
│   ├── inventory/     # Manajemen inventori
│   ├── finances/      # Manajemen keuangan
│   ├── transaction/   # Manajemen transaksi
│   ├── news/         # Berita dan informasi
│   └── shared/       # Komponen shared
├── services/          # Business logic dan API services
│   ├── ai/           # AI/ML services dan predictors
│   └── *.dart        # Various services
├── utils/            # Utility functions
└── widgets/          # Reusable UI components
```

### **Backend & Database**
- **Firebase Firestore**: NoSQL database untuk data real-time
- **Firebase Authentication**: Sistem autentikasi multi-platform
- **Firebase Storage**: Penyimpanan file dan gambar
- **Firebase Cloud Messaging**: Push notifications
- **Firestore Security Rules**: Aturan keamanan database

### **AI/ML Architecture**
- **TensorFlow Lite**: On-device machine learning
- **Custom Predictors**: Stock, Sales, dan Financial predictors
- **Model Validation**: Validasi model ML sebelum deployment
- **Fallback System**: Mock AI service untuk graceful degradation
- **Background Processing**: Isolate untuk pemrosesan ML

## 🛠️ Tech Stack

### **Core Framework**
- **Flutter SDK**: ^3.2.0
- **Dart**: ^3.2.0

### **State Management**
- **Provider**: ^6.1.2 (Primary)
- **Flutter Bloc**: ^8.1.4
- **MobX**: ^2.3.3+2
- **Redux**: ^5.0.0

### **Backend & Database**
- **Firebase Core**: ^2.27.0
- **Firebase Auth**: ^4.17.8
- **Cloud Firestore**: ^4.15.8
- **Firebase Storage**: ^11.6.9
- **Firebase Messaging**: ^14.7.19

### **Authentication**
- **Google Sign In**: ^6.2.1
- **Sign in with Apple**: ^6.1.0
- **Local Auth**: ^2.2.0 (Biometric)
- **Biometric Storage**: ^5.0.0+4

### **UI & Visualization**
- **FL Chart**: ^0.68.0 (Charts & Graphs)
- **Flutter SVG**: ^2.0.10+1
- **Cached Network Image**: ^3.3.1
- **Shimmer**: ^3.0.0 (Loading effects)
- **Lottie**: ^3.1.0 (Animations)
- **Carousel Slider**: ^4.2.1

### **AI/ML & Data Processing**
- **Google Gemini AI** - Advanced conversational AI untuk chatbot
- **TFLite Flutter**: ^0.11.0
- **ML Algo**: ^16.18.0
- **ML DataFrame**: ^1.6.0
- **ML Preprocessing**: ^7.0.0
- **Multi-Modal AI** - Text dan image processing capabilities

### **Device Features**
- **Mobile Scanner**: ^4.0.1 (QR/Barcode)
- **Image Picker**: ^1.0.7
- **Geolocator**: ^11.0.0
- **Device Info Plus**: ^9.1.2
- **Connectivity Plus**: ^5.0.2

### **File & Data Management**
- **Path Provider**: ^2.1.2
- **Shared Preferences**: ^2.2.2
- **PDF**: ^3.10.8
- **Excel**: ^4.0.6
- **CSV**: ^5.1.1
- **Archive**: ^3.4.10

### **Testing**
- **Flutter Test**: SDK
- **Mockito**: ^5.4.4
- **Bloc Test**: ^9.1.6
- **Fake Cloud Firestore**: ^2.5.0
- **Firebase Auth Mocks**: ^0.13.0
- **Integration Test**: SDK

## 📊 Database Schema

### **Collections Structure**
```
Firestore Collections:
├── users/              # User profiles dan settings
├── products/           # Master data produk
├── transactions/       # Data transaksi penjualan/pembelian
├── finance/           # Data keuangan dan budget
├── activities/        # Log aktivitas sistem
├── notifications/     # Notifikasi user
├── ai_logs/          # Log prediksi dan AI insights
└── stock_logs/       # History perubahan stok
```

### **Key Models**
- **Product**: id, name, description, price, stock, minStock, category, imageUrl, sku
- **Transaction**: id, type, items[], total, paymentMethod, status, customer/vendor
- **Finance**: id, type, amount, category, description, date, budget
- **User**: uid, name, email, role, lastLogin, preferences

## 🔧 Setup & Installation

### **Prerequisites**
- Flutter SDK ≥ 3.2.0
- Dart SDK ≥ 3.2.0
- Android Studio / VS Code
- Firebase Project
- Google Services JSON

### **Installation Steps**

1. **Clone Repository**
   ```bash
   git clone <repository-url>
   cd waresysv2
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Buat project Firebase baru
   - Enable Authentication, Firestore, Storage
   - Download `google-services.json` (Android)
   - Download `GoogleService-Info.plist` (iOS)
   - Place files di direktori yang sesuai

4. **Configure Firestore Rules**
   ```bash
   firebase deploy --only firestore:rules
   ```

5. **Run Application**
   ```bash
   flutter run
   ```

## 🚀 Deployment

### **Android**
```bash
flutter build apk --release
# atau
flutter build appbundle --release
```

### **iOS**
```bash
flutter build ios --release
```

### **Web**
```bash
flutter build web --release
```

## 🔒 Security Features

- **Firebase Security Rules**: Akses data berdasarkan authentication
- **Biometric Authentication**: Fingerprint/Face ID support
- **Data Encryption**: Sensitive data encrypted
- **Role-based Access Control**: User vs Admin permissions
- **Secure API Communication**: HTTPS only
- **Local Data Protection**: SharedPreferences encryption

## 📈 Performance Optimizations

- **Lazy Loading**: Load data sesuai kebutuhan
- **Image Caching**: Cached network images
- **Background Processing**: AI/ML processing di isolate
- **Database Indexing**: Optimized Firestore queries
- **Memory Management**: Proper disposal dan cleanup
- **Offline Support**: Local caching untuk offline mode

## 🧪 Testing Strategy

- **Unit Tests**: Business logic dan services
- **Widget Tests**: UI components testing
- **Integration Tests**: End-to-end user flows
- **Firebase Mocking**: Fake Firestore untuk testing
- **AI/ML Testing**: Model validation dan performance tests

## 📱 Platform Support

- ✅ **Android**: API 21+ (Android 5.0+)
- ✅ **iOS**: iOS 12.0+
- ✅ **Web**: Modern browsers
- ✅ **macOS**: macOS 10.14+
- ✅ **Windows**: Windows 10+
- ✅ **Linux**: Ubuntu 18.04+

## 🔄 CI/CD Pipeline

- **GitHub Actions**: Automated testing dan building
- **Firebase Hosting**: Web deployment
- **Play Store**: Android app distribution
- **App Store**: iOS app distribution

## 📋 Roadmap & Future Features

### **Phase 1 (Current)**
- ✅ Core ERP functionality
- ✅ Basic AI/ML integration
- ✅ Multi-platform authentication
- ✅ Real-time dashboard

### **Phase 2 (Planned)**
- 🔄 Advanced AI recommendations
- 🔄 Multi-warehouse support
- 🔄 Advanced reporting
- 🔄 API integrations

### **Phase 3 (Future)**
- 📋 IoT device integration
- 📋 Advanced analytics
- 📋 Multi-tenant support
- 📋 Blockchain integration

## 🤝 Contributing

1. Fork repository
2. Create feature branch
3. Commit changes
4. Push to branch
5. Create Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 👥 Team

- **Lead Developer**: [Your Name]
- **UI/UX Designer**: [Designer Name]
- **Backend Developer**: [Backend Dev Name]
- **QA Engineer**: [QA Name]

## 📞 Support

Untuk support dan pertanyaan:
- Email: support@waresys.com
- Documentation: [docs.waresys.com]
- Issues: [GitHub Issues]

---

**WareSystem v2** - Revolutionizing warehouse and business management with AI-powered insights! 🚀
