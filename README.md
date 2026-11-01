# WarungStock — Sistem Manajemen Inventaris Warung

Aplikasi web modern berbasis **Flutter Web** untuk pencatatan dan pengelolaan stok barang warung secara real-time, terisolasi per akun pemilik warung, serta terintegrasi dengan katalog referensi produk grosir eksternal.

Proyek ini disusun untuk memenuhi tugas **Ujian Tengah Semester (UTS) Pengembangan Aplikasi Mobile (PMP)**.

---

## 1. Deskripsi Proyek

**WarungStock** dirancang untuk membantu para pelaku usaha mikro, kecil, dan menengah (warung kelontong/ritel) dalam mengelola inventaris dagangan mereka secara efisien dan mandiri. Aplikasi ini berjalan pada platform **Flutter Web** yang responsif dan dapat diakses langsung melalui peramban modern (browser) seperti Google Chrome.

### Fitur Utama

1. **Autentikasi Pengguna Mandiri:** Pendaftaran akun baru, masuk, dan keluar dengan penanganan status sesi yang aman via Firebase Authentication.
2. **Manajemen Stok Real-Time (Cloud Firestore CRUD):** Tambah barang baru, pembaruan informasi barang, penghapusan stok, dan pemantauan daftar barang secara instan melalui reactive stream.
3. **Isolasi Data Multi-Tenant (Per UID):** Setiap pengguna hanya memiliki akses penuh terhadap data inventaris miliknya sendiri pada path `users/{uid}/items/{itemId}`.
4. **Katalog Produk Grosir Eksternal (DummyJSON REST API):** Eksplorasi katalog produk grosir lengkap dengan sistem paginasi referensi, pencarian, dan visualisasi kartu produk modern.
5. **Detail Produk & Galeri:** Informasi rincian barang grosir, galeri gambar interaktif, kalkulasi harga diskon, rating, dan stok produk eksternal.
6. **State Management Lengkap (5 ViewState):** Penanganan status antarmuka yang menyeluruh mencakup kondisi `initial`, `loading`, `loaded`, `empty`, dan `error` dengan mekanisme _retry_ pemulihan mandiri.

---

## 2. Teknologi yang Digunakan

- **Framework & Bahasa:** Flutter (Channel stable, Web target) & Dart SDK
- **Backend & Cloud Database:**
  - **Firebase Authentication:** Manajemen identitas pengguna berbasis email & password.
  - **Cloud Firestore:** Basis data NoSQL real-time berorientasi dokumen untuk inventaris warung.
- **State Management:**
  - **Provider (^6.1.5+1):** Menggunakan pola arsitektur `MultiProvider`, `ChangeNotifier`, dan `ChangeNotifierProxyProvider` untuk mengalirkan status sesi dan data secara reaktif.
- **REST API Client:**
  - **Dio (^5.11.1):** Klien HTTP tangguh untuk komunikasi data dengan REST API DummyJSON, dilengkapi konfigurasi timeout, interseptor, dan pemetaan exception.
- **Sumber Data Eksternal:**
  - **DummyJSON REST API (`https://dummyjson.com`):** Layanan API publik sebagai referensi katalog produk grosir pihak ketiga.

---

## 3. Anggota Kelompok

| No  | Nama Lengkap             |      NIM       | Peran Utama                                                                                                   |
| :-: | :----------------------- | :------------: | :------------------------------------------------------------------------------------------------------------ |
|  1  | `Muhammad Rizzy Anugrah` | `[2411500069]` | Auth + navigasi + struktur folder                                                                             |
|  2  | `[Adilla Agustia]`       | `[2411500078]` | Firestore CRUD + Model/Service/Provider + ViewState                                                           |
|  3  | `[Parin Dwi Rahmadini]`  | `[2411500003]` | Dio REST API + loading/error/empty + Future vs Stream                                                         |
|  4  | `[Galih Havid Permana]`  | `[2411500061]` | `[Peran Tambahan / UI-UX Styling / Pengujian & Dokumentasi / Video Demo — Menyesuaikan Kesepakatan Kelompok]` |

---

## 4. Rincian Pembagian Peran

Pembagian tanggung jawab teknis mengacu pada spesifikasi rubrik tugas UTS PMP:

### Anggota 1: Auth + navigasi + struktur folder

- Menginisialisasi proyek Flutter Web, struktur modular `lib/`, dan dependensi utama.
- Mengimplementasikan `AuthProvider` dengan Firebase Authentication (Register, Login, Logout).
- Mengelola listener status sesi berbasis `Stream<User?>` dan _subscription lifecycle_ (`dispose()`).
- Membangun `AuthGate` sebagai gerbang navigasi reaktif antara sesi login dan halaman utama.
- Merancang tata letak dasar, tema Material 3, dan alur navigasi antar-halaman.

### Anggota 2: Firestore CRUD + Model/Service/Provider + ViewState

- Merancang `ItemModel` dengan serialisasi aman terhadap `DocumentSnapshot`, `Timestamp`, dan penanganan tipe numerik.
- Mengembangkan `FirestoreService` untuk operasi CRUD lengkap di bawah path terisolasi `users/{uid}/items/{itemId}`.
- Mengembangkan `ItemProvider` menggunakan `ChangeNotifierProxyProvider` yang secara otomatis menghubungkan UID aktif ke stream inventaris.
- Menerapkan siklus status antarmuka `ItemViewState` (`initial`, `loading`, `loaded`, `empty`, `error`).
- Merancang dialog interaktif tambah/edit barang dan validasi input inventaris di `HomeScreen`.

### Anggota 3: Dio REST API + loading/error/empty + Future vs Stream

- Mengonfigurasi klien `Dio` pada `ApiService` dengan Base URL DummyJSON, timeout 10 detik, dan pemetaan lengkap `DioExceptionType`.
- Merancang `ProductModel` untuk parsing katalog dan detail produk DummyJSON.
- Mengembangkan `ApiProvider` dengan pengelolaan status terpisah antara daftar produk (`_state`) dan detail produk (`_detailState`).
- Membangun antarmuka `ProductListScreen`, `ProductDetailScreen`, dan `ProductCard` yang responsif.
- Mengimplementasikan penanganan status UI katalog (`CircularProgressIndicator`, kartu error dengan tombol retry, dan empty state).
- Menyusun komparasi implementasi **Future** (transaksi REST API satu kali) vs **Stream** (aliran data real-time Firestore & Auth).

### Anggota 4: Kesepakatan Tanggung Jawab Tambahan Kelompok

- `[Pengujian integrasi antarmuka, verifikasi cross-browser, penyusunan naskah/skenario video presentasi, pengeditan rekaman demonstrasi, serta finalisasi dokumen pengumpulan tugas UTS.]`

---

## 5. Fitur Aplikasi yang Diimplementasikan

### 1. Modul Autentikasi (`lib/screens/auth/`)

- **Pendaftaran Akun:** Formulir registrasi akun pemilik warung dengan validasi format email dan kata sandi minimal 6 karakter.
- **Masuk Akun:** Otentikasi email dan kata sandi dengan pesan galat ramah pengguna jika kredensial tidak sesuai.
- **Keluar Akun:** Konfirmasi keluar sesi akun dengan dialog peringatan dan pembersihan memori state pengguna aktif.

### 2. Modul Inventaris Warung (`lib/screens/home_screen.dart`)

- **Tambah Barang Baru:** Modal form penambahan barang dengan kolom nama, jumlah stok (bilangan bulat non-negatif), dan harga satuan.
- **Pemutakhiran Data:** Memperbarui data barang yang sudah tersimpan tanpa mengubah waktu pembuatan asli (`createdAt`).
- **Hapus Barang:** Menghapus barang dari basis data dengan konfirmasi tindakan terlebih dahulu.
- **Sinkronisasi Real-Time:** Daftar barang diperbarui otomatis secara instan tanpa perlu memuat ulang peramban.
- **Isolasi Data Pengguna:** Barang milik pemilik warung A tidak dapat dilihat maupun dimodifikasi oleh pemilik warung B.

### 3. Modul Katalog Produk Grosir Eksternal (`lib/screens/products/`)

- **Katalog Produk:** Grid produk responsif dari DummyJSON dengan informasi nama produk, harga, kategori, rating, dan stok.
- **Rincian Produk:** Halaman detail dengan galeri gambar multi-tampilan, persentase diskon, kalkulasi harga asli, serta deskripsi lengkap.
- **Mode Baca Saja (Read-Only):** Klien Dio hanya menjalankan metode HTTP `GET` tanpa operasi penulisan ke server DummyJSON.
- **Penanganan Kesalahan & Pemulihan:** Jika koneksi terputus atau server lambat, antarmuka menyediakan tombol coba lagi (_retry_).

---

## 6. Struktur Direktori Proyek

Struktur direktori aktual pada repositori adalah sebagai berikut:

```text
InventoryWarung(UTS)/
├── .gitignore
├── analysis_options.yaml
├── firebase.json
├── firestore.rules
├── pubspec.yaml
├── README.md
├── docs/
│   └── screenshots/
│       └── README.md
├── lib/
│   ├── firebase_options.dart
│   ├── main.dart
│   ├── models/
│   │   ├── item_model.dart
│   │   └── product_model.dart
│   ├── providers/
│   │   ├── api_provider.dart
│   │   ├── auth_provider.dart
│   │   └── item_provider.dart
│   ├── screens/
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   └── register_screen.dart
│   │   ├── home_screen.dart
│   │   └── products/
│   │       ├── product_detail_screen.dart
│   │       └── product_list_screen.dart
│   ├── services/
│   │   ├── api_service.dart
│   │   └── firestore_service.dart
│   └── widgets/
│       └── product_card.dart
├── test/
│   ├── api_test.dart
│   ├── product_detail_screen_test.dart
│   ├── product_list_screen_test.dart
│   └── widget_test.dart
└── web/
    ├── favicon.png
    ├── index.html
    └── manifest.json
```

---

## 7. Konfigurasi dan Instalasi

### Prasyarat

- [Flutter SDK](https://docs.flutter.dev/get-started/install) versi stable (disarankan >= 3.22.0).
- [Google Chrome](https://www.google.com/chrome/) terpasang pada komputer pengembang.
- [Node.js](https://nodejs.org/) & [Firebase CLI](https://firebase.google.com/docs/cli) (opsional, jika ingin menghubungkan ulang project Firebase).

### Langkah Instalasi

1. **Clone Repositori:**

   ```bash
   git clone https://github.com/[username-pengguna]/InventoryWarung.git
   cd InventoryWarung
   ```

2. **Unduh Seluruh Dependensi:**

   ```bash
   flutter pub get
   ```

3. **Konfigurasi Firebase:**
   Proyek ini telah memiliki berkas `lib/firebase_options.dart` yang terhubung ke Firebase Project ID `warungstock-uts`.
   Apabila penguji atau pengembang ingin mengonfigurasi ulang ke proyek Firebase sendiri, jalankan perintah resmi berikut:
   ```bash
   flutterfire configure --project=warungstock-uts --platforms=web
   ```
   > **Catatan:** Pastikan akun Firebase Anda telah mengaktifkan layanan **Authentication (Email/Password)** dan basis data **Cloud Firestore**.

---

## 8. Menjalankan Aplikasi

Untuk menjalankan aplikasi pada target peramban Google Chrome dalam mode debug:

```bash
flutter pub get
flutter run -d chrome
```

---

## 9. Menjalankan Pengujian Kualitas Kode

Seluruh rangkaian pengujian statis dan dinamis dapat dijalankan melalui terminal:

1. **Analisis Statis Kode (0 issues):**

   ```bash
   flutter analyze
   ```

2. **Rangkaian Pengujian Otomatis (34 unit & widget tests):**

   ```bash
   flutter test
   ```

3. **Kompilasi Web Release:**
   ```bash
   flutter build web --release
   ```

---

## 10. Aturan Keamanan Cloud Firestore (`firestore.rules`)

Berkas aturan keamanan lokal tersedia pada direktori root proyek:
[`firestore.rules`](./firestore.rules)

### Ringkasan Aturan Keamanan

- Akses baca, buat, ubah, dan hapus pada `users/{userId}/items/{itemId}` **wajib** melewati autentikasi (`request.auth != null`).
- Operasi hanya diizinkan jika `request.auth.uid == userId` (menegakkan isolasi data antar-pengguna).
- Seluruh kolom dokumen inventaris divalidasi dengan ketat:
  - `name`: Tipe `string`, tidak kosong setelah di-trim, panjang maksimal 100 karakter.
  - `stock`: Tipe `int`, nilai minimal 0.
  - `price`: Tipe `int` atau `float`, nilai lebih besar dari 0.
  - `createdAt` & `updatedAt`: Tipe `timestamp`.
  - Kolom tambahan di luar skema akan otomatis ditolak (`hasOnly(...)`).
- Seluruh dokumen dan koleksi lain di luar path di atas ditolak secara default (`allow read, write: if false;`).

### Panduan Menerapkan Aturan ke Firebase Console

> **Penting:** Berkas `firestore.rules` pada repositori ini merupakan konfigurasi lokal. Untuk menerapkannya ke backend Cloud Firestore yang aktif, ikuti salah satu opsi berikut:

**Opsi A — Melalui Firebase CLI:**

```bash
firebase login
firebase use warungstock-uts
firebase deploy --only firestore:rules
```

**Opsi B — Melalui Firebase Console:**

1. Masuk ke [Firebase Console](https://console.firebase.google.com/).
2. Buka proyek **warungstock-uts** $\rightarrow$ pilih **Build** $\rightarrow$ **Firestore Database** $\rightarrow$ tab **Rules**.
3. Salin seluruh isi dari berkas [`firestore.rules`](./firestore.rules).
4. Tempel ke editor aturan Firebase Console, lalu klik **Publish**.

---

## 11. Tangkapan Layar Aplikasi (Screenshots)

Direktori penyimpanan aset tangkapan layar tersedia di `docs/screenshots/`.

### 1. Halaman Masuk & Pendaftaran Akun

|                       Halaman Masuk (Login)                        |                    Halaman Pendaftaran (Register)                     |
| :----------------------------------------------------------------: | :-------------------------------------------------------------------: |
| _(Screenshot Placeholder: `docs/screenshots/01_login_screen.png`)_ | _(Screenshot Placeholder: `docs/screenshots/02_register_screen.png`)_ |

### 2. Beranda Inventaris Warung (Firestore CRUD)

|                      Tampilan Daftar Stok & Dashboard                       |                      Dialog Tambah / Ubah Barang                      |
| :-------------------------------------------------------------------------: | :-------------------------------------------------------------------: |
| _(Screenshot Placeholder: `docs/screenshots/03_home_inventory_screen.png`)_ | _(Screenshot Placeholder: `docs/screenshots/04_add_item_dialog.png`)_ |

### 3. Katalog & Detail Produk Grosir (DummyJSON REST API)

|                            Katalog Produk Grosir                             |                           Detail & Galeri Produk                            |
| :--------------------------------------------------------------------------: | :-------------------------------------------------------------------------: |
| _(Screenshot Placeholder: `docs/screenshots/05_product_catalog_screen.png`)_ | _(Screenshot Placeholder: `docs/screenshots/06_product_detail_screen.png`)_ |

> **Petunjuk:** Jalankan aplikasi web di Google Chrome, ambil tangkapan layar antarmuka asli pada keenam kondisi di atas, simpan pada folder `docs/screenshots/`, lalu tautkan file gambarnya pada tabel di atas sebelum penyerahan final.

---

## 12. Video Demonstrasi Aplikasi

Sebagai bagian dari persyaratan penyerahan tugas UTS PMP, video rekaman demonstrasi yang menjelaskan arsitektur aplikasi, autentikasi, Firestore CRUD real-time, integrasi Dio REST API, serta komparasi Future vs Stream dapat diakses pada tautan berikut:

- **Tautan Video Demonstrasi (Google Drive):**
  `[Link Google Drive Video Demonstrasi UTS PMP — Silakan Isi Tautan Resmi Di Sini]`

---

## 13. Informasi Pengumpulan Tugas UTS

Penyerahan tugas proyek Ujian Tengah Semester (UTS) Pengembangan Aplikasi Mobile (PMP) mencakup:

1. **Repositori Publik GitHub:** Memuat kode sumber lengkap, riwayat commit yang terstruktur, pengujian unit, aturan keamanan Firestore, dan dokumentasi `README.md`.
2. **Video Rekaman Demonstrasi:** Menjelaskan alur penggunaan aplikasi secara langsung serta pembagian kontribusi masing-masing anggota kelompok.
