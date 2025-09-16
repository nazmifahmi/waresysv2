# 📱 WareSys UI Development Plan (ERP Modules)

Dokumen ini merinci instruksi pembuatan UI untuk 4 menu utama ERP WareSys: **Monitoring, Inventory, Finance, dan Transactions**, dengan struktur komponen, integrasi Firestore, dan konfigurasi yang disarankan.

---

## 1. 📊 Monitoring Screen

### 🎯 Tujuan
Menampilkan **dashboard ringkasan** dari data transaksi, stok, login user, dan sistem alert secara real-time.

### 🧱 Komponen UI
- **Dashboard Cards**:
  - Total Transaksi Hari Ini
  - Total Penjualan/Pembelian
  - Jumlah Stok Masuk / Keluar
  - Jumlah Order Pending
  - Notifikasi/Error Operasional

- **Charts**:
  - Line Chart Penjualan Mingguan
  - Pie Chart Status Order

- **Tables (Recent Activity)**:
  - Transaksi Terbaru
  - User Login Hari Ini
  - Perubahan Stok Terakhir

- **System Status & Alert**:
  - Firebase / Server Online Status
  - Notifikasi Alert: stok menipis, transaksi gagal

### 🔌 Integrasi Firestore
```dart
Firestore.instance.collection('transactions')
FirebaseFirestore.instance.collection('products')
FirebaseFirestore.instance.collection('logs')
FirebaseAuth.instance.currentUser
2. 📦 Inventory Screen
🎯 Tujuan
Mengelola dan memantau produk, stok masuk, stok keluar, dan reorder alert.

🧱 Komponen UI
Product List Table

Nama Produk

SKU / Barcode

Kategori

Stok Saat Ini

Status: Aman / Kritis / Habis

Filter & Search

Berdasarkan Kategori / Status / Nama

Tombol Tambah Produk / Update Stok

Modal Form: Tambah Produk

Modal Form: Update Stok (Masuk/Keluar)

🔌 Integrasi Firestore
dart
Copy
Edit
FirebaseFirestore.instance.collection('products')
FirebaseFirestore.instance.collection('stock_logs') // Optional: Riwayat stok masuk/keluar
3. 💰 Finance Screen
🎯 Tujuan
Menampilkan arus kas, daftar invoice, tagihan, dan laporan keuangan sederhana.

🧱 Komponen UI
Cashflow Summary Cards

Total Pemasukan

Total Pengeluaran

Saldo Akhir

Invoice & Tagihan Table

ID Transaksi

Vendor / Customer

Tanggal

Nominal

Status: Dibayar / Belum / Overdue

Export PDF / CSV Button (Optional)

🔌 Integrasi Firestore
dart
Copy
Edit
FirebaseFirestore.instance.collection('finance')
FirebaseFirestore.instance.collection('transactions').where('type', isEqualTo: 'income') // pemasukan
FirebaseFirestore.instance.collection('transactions').where('type', isEqualTo: 'expense') // pengeluaran
4. 🔁 Transactions Screen (Sales & Purchase)
🎯 Tujuan
Mengelola transaksi penjualan dan pembelian dengan status dan detail lengkap.

🧱 Komponen UI
List Transaksi

Tipe: Penjualan / Pembelian

ID Transaksi

Customer / Vendor

Tanggal

Total Harga

Status: Pending / Done / Cancelled

Filter dan Search

Berdasarkan Tipe / Status / Rentang Tanggal

Form Input Transaksi Baru

Produk

Jumlah

Harga Satuan

Total

🔌 Integrasi Firestore
dart
Copy
Edit
FirebaseFirestore.instance.collection('transactions')
✅ Konfigurasi Tambahan
📅 Date Filtering
Gunakan date_picker_timeline atau flutter_datetime_picker untuk navigasi per hari/bulan.

🔔 Alert & Notifikasi
Gunakan Firebase Cloud Messaging (FCM) untuk:

Stok kritis

Transaksi gagal

Invoice jatuh tempo

📋 Activity Log (Log Sistem)
Setiap aktivitas CRUD simpan ke:

dart
Copy
Edit
FirebaseFirestore.instance.collection('logs')
Dengan data:

json
Copy
Edit
{
  "user": "uid",
  "action": "create/update/delete",
  "module": "transactions/inventory/etc",
  "timestamp": Timestamp.now()
}
🎯 MVP Prioritas (Step-by-Step)
Layout dasar untuk 4 screen

Integrasi Firestore pada data utama

Implementasi filtering dan status label

Tambahkan chart sederhana

Tambahkan logging & notifikasi opsional

🧩 Direkomendasikan Package Flutter
cloud_firestore

firebase_auth

fl_chart / syncfusion_flutter_charts

provider / riverpod

flutter_datetime_picker

flutter_local_notifications + firebase_messaging (opsional)

[ ] User
[ ] Admin

Jika pilih Admin:
[Input] Masukkan Kode Admin: waresysadmin