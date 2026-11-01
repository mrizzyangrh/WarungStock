# WARUNGSTOCK
## Dokumentasi Lengkap Proyek
**UTS Pemrograman Mobile (PMP) — Flutter Web, Firebase, Provider, dan Dio**

> Dokumen ini merupakan versi Markdown dari dokumentasi Word WarungStock. Digunakan sebagai bahan pembelajaran kelompok, referensi teknis, dan persiapan presentasi.

WARUNGSTOCK

Dokumentasi Lengkap Proyek

UTS Pemrograman Mobile (PMP) — Flutter Web, Firebase, Provider, dan Dio

| Informasi | Keterangan |
| --- | --- |
| Nama proyek | WarungStock — Aplikasi Inventaris Warung |
| Platform | Flutter Web |
| Backend & database | Firebase Authentication dan Cloud Firestore |
| State management | Provider / ChangeNotifier / MultiProvider |
| REST API | DummyJSON melalui Dio (read-only) |
| Kelompok | 4 anggota |
| Status berdasarkan laporan terakhir | Implementasi inti selesai; 34/34 test lulus; screenshot, video, deployment Rules, dan final Git checkpoint masih perlu dituntaskan. |

Disusun sebagai bahan belajar, pemahaman alur kode, pembagian tugas, dan persiapan presentasi.


## Catatan penggunaan dokumen

Dokumen ini merangkum riwayat proyek berdasarkan informasi dan laporan implementasi yang telah dibagikan selama pengerjaan. Informasi yang belum dikonfirmasi—misalnya nama/NIM selain yang diberikan, URL repositori, detail konfigurasi Firebase yang bersifat rahasia, dan hasil deployment—tidak dibuat-buat.

Status pengujian 34/34, flutter analyze, dan build web merupakan hasil yang dilaporkan dari lingkungan pengembangan. Firebase Emulator belum dijalankan karena lingkungan hanya memiliki OpenJDK 8; karena itu, skenario Security Rules pada laporan Phase 6C merupakan analisis statis, bukan hasil uji emulator.


# Daftar isi

- 1. Gambaran umum dan tujuan proyek
- 2. Latar belakang dan ruang lingkup
- 3. Teknologi yang digunakan
- 4. Arsitektur aplikasi dan alur data
- 5. Struktur folder dan komponen penting
- 6. Riwayat pengembangan dari awal hingga Phase 6C
- 7. Penjelasan modul utama
- 8. Firebase Security Rules
- 9. Pengujian dan hasil verifikasi
- 10. Pembagian peran empat anggota
- 11. Panduan menjalankan dan menguji aplikasi
- 12. Materi belajar dan pertanyaan presentasi
- 13. Rancangan alur presentasi 12–15 menit
- 14. Checklist final submission
- 15. Glosarium

# 1. Gambaran umum dan tujuan proyek

WarungStock adalah aplikasi inventaris berbasis Flutter Web yang ditujukan untuk membantu pengelolaan stok barang pada usaha warung. Aplikasi menyediakan autentikasi pengguna, pengelolaan data inventaris secara real-time melalui Cloud Firestore, serta katalog produk eksternal dari DummyJSON sebagai referensi informasi produk.

Tujuan teknis proyek adalah menerapkan materi UTS PMP: pemrograman asynchronous Dart, REST API dengan Dio, state management Provider, Firebase Authentication, dan operasi CRUD Cloud Firestore.


# 2. Latar belakang dan ruang lingkup

Usaha warung membutuhkan pencatatan barang yang mudah diakses dan diperbarui. Aplikasi ini memusatkan data inventaris setiap pengguna pada penyimpanan cloud dan membatasi akses berdasarkan UID akun yang sedang login.


## 2.1 Ruang lingkup fitur

- Register, login, logout, dan pemantauan status autentikasi.
- Dashboard inventaris dan navigasi menuju katalog.
- CRUD barang inventaris pada Cloud Firestore.
- Pembaruan data inventaris melalui Stream sehingga perubahan dapat diamati secara real-time.
- Katalog produk DummyJSON yang dibaca melalui Dio.
- Halaman daftar produk dan detail produk.
- State loading, loaded, empty, dan error pada modul data Firestore/API.

## 2.2 Batasan yang disengaja

- DummyJSON digunakan sebagai katalog referensi read-only, bukan sumber untuk mengimpor produk ke inventaris Firestore.
- Tidak ada endpoint penulisan produk DummyJSON yang digunakan.
- Fitur tambahan seperti laporan, analitik lanjutan, kategori kompleks, atau sinkronisasi katalog tidak termasuk implementasi yang dilaporkan.
- Security Rules telah dibuat sebagai file lokal, tetapi deployment ke Firebase Console belum dikonfirmasi.

# 3. Teknologi yang digunakan

| Teknologi | Fungsi dalam WarungStock |
| --- | --- |
| Flutter Web | Framework UI untuk membangun aplikasi yang berjalan pada browser. |
| Dart | Bahasa pemrograman aplikasi; mendukung Future dan Stream untuk operasi asynchronous. |
| Firebase Core | Inisialisasi koneksi aplikasi dengan Firebase. |
| Firebase Authentication | Register, login, logout, dan stream status autentikasi. |
| Cloud Firestore | Database dokumen NoSQL untuk menyimpan data inventaris. |
| Provider | State management berbasis ChangeNotifier dan penyedia dependency melalui MultiProvider. |
| ChangeNotifierProxyProvider | Menghubungkan perubahan AuthProvider dengan ItemProvider agar data inventaris mengikuti UID pengguna. |
| Dio | HTTP client untuk mengambil data dari REST API. |
| DummyJSON | REST API publik yang menyediakan data produk untuk katalog referensi. |
| Flutter Test | Pengujian unit dan widget. |
| Firebase CLI / FlutterFire CLI | Konfigurasi Firebase dan, bila lingkungan memenuhi syarat, emulator/deployment. |


# 4. Arsitektur aplikasi dan alur data


## 4.1 Gambaran arsitektur

```text
Pengguna | v Flutter Web UI (Screens & Widgets) | +--> AuthProvider ----> Firebase Authentication | +--> ItemProvider ----> FirestoreService ----> Cloud Firestore | +--> ApiProvider -----> ApiService (Dio) -----> DummyJSON REST API
```

UI berinteraksi dengan Provider. Provider mengelola state dan memanggil service. Service menangani komunikasi dengan Firebase atau REST API. Model mengubah data mentah menjadi objek Dart yang lebih mudah digunakan oleh UI.


## 4.2 Alur autentikasi

1. Aplikasi menginisialisasi Firebase sebelum runApp().
1. MultiProvider menyediakan AuthProvider pada root aplikasi.
1. AuthProvider memantau FirebaseAuth.instance.authStateChanges().
1. AuthGate menampilkan LoginScreen untuk pengguna yang belum login dan HomeScreen untuk pengguna yang sudah login.
1. Saat logout, status autentikasi berubah dan AuthGate kembali menampilkan halaman login.

## 4.3 Alur CRUD inventaris

1. Pengguna mengisi form barang pada UI.
1. ItemProvider menerima aksi dan mengatur state loading.
1. FirestoreService menulis atau mengubah dokumen pada users/{uid}/items/{itemId}.
1. Firestore mengirim pembaruan melalui Stream.
1. ItemProvider menerima data terbaru, memperbarui state, dan memanggil notifyListeners().
1. Widget yang menggunakan Provider membangun ulang tampilan sesuai state.

## 4.4 Alur katalog REST API

1. ProductListScreen meminta daftar produk melalui ApiProvider.
1. ApiProvider mengatur state loading dan memanggil ApiService.
1. ApiService menggunakan Dio untuk GET https://dummyjson.com/products.
1. JSON diubah menjadi ProductModel.
1. ApiProvider menyimpan daftar produk dan mengubah state menjadi loaded atau empty.
1. Saat pengguna memilih produk, aplikasi membuka ProductDetailScreen dan mengambil detail melalui endpoint GET /products/{id}.

# 5. Struktur folder dan komponen penting

Struktur berikut merupakan ringkasan berdasarkan laporan implementasi. Periksa pohon direktori aktual di repositori sebelum menyalinnya sebagai struktur final README.

```text
lib/ main.dart firebase_options.dart models/ item_model.dart product_model.dart providers/ auth_provider.dart item_provider.dart api_provider.dart services/ firestore_service.dart api_service.dart screens/ auth/ login_screen.dart register_screen.dart home_screen.dart products/ product_list_screen.dart product_detail_screen.dart widgets/ product_card.dart test/ api_test.dart product_list_screen_test.dart product_detail_screen_test.dart widget_test.dart docs/ screenshots/ README.md firestore.rules firebase.json README.md
```


## 5.1 Model

ItemModel merepresentasikan barang inventaris. Berdasarkan laporan, data dokumen memiliki field name, stock, price, createdAt, dan updatedAt. ProductModel merepresentasikan produk dari DummyJSON, termasuk id, title, description, category, price, discountPercentage, rating, stock, brand, thumbnail, dan images.


## 5.2 Provider

| Provider | Tanggung jawab |
| --- | --- |
| AuthProvider | Operasi autentikasi dan pemantauan authStateChanges. |
| ItemProvider | State dan operasi inventaris; mengikuti UID pengguna melalui ChangeNotifierProxyProvider. |
| ApiProvider | State daftar produk, detail produk, pemanggilan API, retry, serta pesan error. |


## 5.3 Service

| Service | Tanggung jawab |
| --- | --- |
| FirestoreService | Operasi Firestore untuk menambah, membaca/stream, memperbarui, dan menghapus item. |
| ApiService | Permintaan HTTP GET ke DummyJSON menggunakan Dio dan penanganan error jaringan. |


# 6. Riwayat pengembangan dari awal hingga Phase 6C

Pengembangan dilakukan bertahap agar setiap lapisan aplikasi dapat diverifikasi sebelum melanjutkan ke tahap berikutnya.

| Tahap / checkpoint | Pekerjaan | Hasil yang dilaporkan |
| --- | --- | --- |
| Inisialisasi proyek | Membuat proyek Flutter Web dan memastikan Flutter, Dart, Git, serta Chrome terdeteksi. | Commit 4ddcfae. |
| Dependencies & struktur | Menambahkan provider, dio, firebase_core, firebase_auth, cloud_firestore serta folder awal. | Commit 403d16a. |
| Konfigurasi Firebase | Menjalankan FlutterFire configure untuk proyek warungstock-uts dan menghasilkan firebase_options.dart serta firebase.json. | Konfigurasi web Firebase tersedia. |
| Authentication | Firebase init, AuthProvider, AuthGate, login, register, logout, validasi dan pesan error. | Commit 22b8b54. |
| Phase 4A Firestore CRUD | ItemModel, FirestoreService, ItemProvider, isolasi UID, Stream, CRUD dan ViewState. | Commit c464610; 10 test pada laporan tahap tersebut. |
| Phase 5A API foundation | ProductModel, ApiService, ApiProvider, Dio, DummyJSON GET list/detail dan state. | Commit 7df9726; 23 test pada laporan tahap tersebut. |
| Phase 5B Step 1 | ProductListScreen, ProductCard, responsive grid, loading/error/empty/loaded dan widget tests. | 28 test lulus. |
| Phase 5B Step 2 | ProductDetailScreen, navigasi dari daftar ke detail dan pengujian widget. | 33 test lulus. |
| Phase 5B Step 3 | Integrasi akses katalog pada HomeScreen dan pengujian navigasi. | Commit 984558b; 34 test, analyze dan build web lulus. |
| Phase 6A audit | Audit read-only terhadap Auth, Firestore, Provider, Dio, navigasi, struktur dan README. | Menemukan README dan Security Rules masih perlu dilengkapi. |
| Phase 6B | Membuat firestore.rules, menyusun ulang README dan panduan screenshot. | Perubahan lokal belum di-commit. |
| Phase 6C | Analisis kompatibilitas Rules, regression test dan pemeriksaan placeholder dokumentasi. | 34/34 test, analyze, build web dan diff check dilaporkan lulus; emulator tidak dijalankan. |

Commit terakhir yang dilaporkan adalah 984558b. Perubahan Phase 6B/6C masih berstatus lokal: README.md dimodifikasi, docs/ dan firestore.rules belum dilacak Git. Belum ada commit atau push untuk perubahan tersebut.


# 7. Penjelasan modul utama


## 7.1 Firebase Authentication

Authentication memastikan pengguna memiliki sesi sebelum mengakses inventaris. AuthProvider membungkus operasi Firebase Authentication dan berlangganan authStateChanges. Stream ini penting agar UI bereaksi otomatis terhadap login dan logout, bukan hanya memeriksa status sekali.


## 7.2 Firestore CRUD

Data inventaris disimpan pada subkoleksi per pengguna dengan pola users/{uid}/items/{itemId}. Pola ini mendukung pemisahan data antar akun. Operasi CRUD dilakukan melalui FirestoreService, sedangkan ItemProvider mengelola state dan menyampaikan perubahan ke UI.

| Operasi | Makna | Contoh penggunaan |
| --- | --- | --- |
| Create | Menambahkan dokumen item baru. | Pengguna menyimpan barang baru. |
| Read / Stream | Mengambil data atau mendengarkan perubahan. | Daftar inventaris diperbarui saat data berubah. |
| Update | Mengubah field item yang sudah ada. | Nama, stok, atau harga diperbarui. |
| Delete | Menghapus dokumen item. | Barang yang tidak lagi dicatat dihapus. |


## 7.3 REST API dan Dio

ApiService menggunakan Dio untuk melakukan permintaan GET ke DummyJSON. ApiProvider mengelola daftar dan detail produk serta state pemuatan, keberhasilan, data kosong, dan kegagalan. Fitur retry memberi kesempatan pengguna mengulangi permintaan setelah gangguan jaringan.


## 7.4 Future dan Stream

| Konsep | Karakteristik | Contoh dalam proyek |
| --- | --- | --- |
| Future | Merepresentasikan satu hasil asynchronous yang selesai satu kali. | Permintaan HTTP getProducts() mengembalikan hasil setelah request selesai. |
| Stream | Mengirim nol atau lebih event secara berkelanjutan selama subscription aktif. | authStateChanges() dan getItemsStream() mengirim perubahan status/data. |

Analogi presentasi: Future seperti memesan satu paket dan menunggu satu kali sampai paket tiba. Stream seperti berlangganan notifikasi yang dapat datang berkali-kali ketika ada perubahan.


## 7.5 Provider dan ChangeNotifier

ChangeNotifier menyediakan mekanisme pemberitahuan perubahan state. Ketika data atau status berubah, Provider memanggil notifyListeners() sehingga widget yang mendengarkan provider dapat membangun ulang UI. Subscription Stream perlu dibatalkan pada dispose agar tidak meninggalkan listener yang tidak lagi digunakan.


## 7.6 ViewState

| State | Kapan digunakan | Contoh UI |
| --- | --- | --- |
| initial | Belum ada permintaan atau state awal. | Tampilan awal / belum memuat. |
| loading | Permintaan sedang berlangsung. | CircularProgressIndicator. |
| loaded | Data berhasil diterima dan tersedia. | Daftar item atau produk. |
| empty | Permintaan berhasil tetapi data kosong. | Pesan belum ada data. |
| error | Permintaan gagal. | Pesan kesalahan dan tombol coba lagi. |


# 8. Firebase Cloud Firestore Security Rules

File firestore.rules dibuat pada Phase 6B. Tujuannya membatasi akses berdasarkan autentikasi dan UID, serta memvalidasi struktur dokumen inventaris.

```text
rules_version = '2'; service cloud.firestore { match /databases/{database}/documents { function isAuthenticated() { return request.auth != null; } function isOwner(userId) { return isAuthenticated() && request.auth.uid == userId; } function hasValidItemFields() { let data = request.resource.data; return data.keys().hasOnly([ 'name', 'stock', 'price', 'createdAt', 'updatedAt' ]) && data.name is string && data.name.trim().size() > 0 && data.name.size() <= 100 && data.stock is int && data.stock >= 0 && (data.price is int || data.price is float) && data.price > 0 && data.createdAt is timestamp && data.updatedAt is timestamp; } match /users/{userId}/items/{itemId} { allow read: if isOwner(userId); allow create: if isOwner(userId) && hasValidItemFields(); allow update: if isOwner(userId) && hasValidItemFields() && request.resource.data.createdAt == resource.data.createdAt; allow delete: if isOwner(userId); } match /{document=**} { allow read, write: if false; } } }
```

Catatan: potongan di atas diringkas dari isi yang dilaporkan. Untuk deployment, gunakan file firestore.rules aktual di repositori, bukan salinan ringkasan ini.


## 8.1 Makna aturan

- request.auth != null: hanya pengguna yang sudah login yang dapat melewati pemeriksaan autentikasi.
- request.auth.uid == userId: UID akun harus sama dengan UID pada path dokumen.
- keys().hasOnly(...): menolak field yang tidak termasuk skema yang diizinkan.
- Pemeriksaan tipe dan rentang nilai: memastikan name, stock, price, createdAt, dan updatedAt sesuai format.
- createdAt saat update harus sama dengan nilai sebelumnya: mencegah perubahan waktu pembuatan.
- Fallback deny: akses pada path lain ditolak.

## 8.2 Status validasi

Phase 6C menyatakan emulator tidak dijalankan karena Java yang tersedia adalah OpenJDK 8, sementara Firestore Emulator memerlukan Java 11 atau lebih baru. Karena itu, matriks keamanan yang dilaporkan merupakan evaluasi logika statis. Sebelum menyatakan Rules teruji secara runtime, lakukan pengujian dengan Java yang didukung dan Firebase Emulator atau gunakan pengujian Rules di lingkungan yang sesuai.

Rules belum di-deploy ke Firebase Console menurut laporan terakhir. Membuat file lokal tidak otomatis mengaktifkan aturan di proyek Firebase.


# 9. Pengujian dan hasil verifikasi

| Perintah / pemeriksaan | Hasil terakhir yang dilaporkan | Interpretasi |
| --- | --- | --- |
| flutter analyze | No issues found | Analisis statis Dart/Flutter bersih. |
| flutter test | 34/34 passed | Seluruh unit/widget test yang ada lulus. |
| flutter build web --release | Build succeeded | Aplikasi berhasil dikompilasi untuk web release. |
| git diff --check | Exit code 0 | Tidak ditemukan masalah whitespace/conflict marker. |
| Firestore Emulator | Tidak dijalankan | Belum ada bukti pengujian Rules runtime. |

34 test yang dilaporkan terdiri dari 13 API unit tests, 5 Product Detail widget tests, 5 Product List widget tests, dan 11 Auth, Navigation & Inventory CRUD tests.


## 9.1 Mengapa pengujian diperlukan?

Pengujian membantu memastikan fungsi penting tidak rusak saat fitur baru ditambahkan. Unit test dapat menguji parsing dan service/provider, sedangkan widget test memeriksa perilaku tampilan dan navigasi. Analyze mendeteksi masalah kode, sedangkan build release memastikan aplikasi dapat dikompilasi untuk target web.


# 10. Pembagian peran empat anggota

Berikut usulan pembagian berdasarkan struktur tugas UTS dan modul proyek. Ini adalah rancangan tanggung jawab tim, bukan klaim bahwa seluruh anggota telah mengerjakan modul tersebut. Setiap anggota harus mempelajari dan mampu mendemonstrasikan bagian yang menjadi tanggung jawabnya.

| Anggota | Peran yang disarankan | Tanggung jawab dan materi yang dipresentasikan |
| --- | --- | --- |
| 1. Muhammad Rizzy Anugrah | Auth + navigasi + struktur folder (peran baku Anggota 1) | Menjelaskan inisialisasi Firebase, AuthProvider, authStateChanges, AuthGate, Login/Register/Logout, struktur folder, dan navigasi menuju Home/Katalog. |
| 2. Adilla Agustia | Firestore CRUD + Model/Service/Provider + ViewState (peran baku Anggota 2) | Menjelaskan ItemModel, FirestoreService, ItemProvider, path users/{uid}/items, CRUD, Stream inventaris, isolasi UID, dan state initial/loading/loaded/empty/error. |
| 3. Farinda Dwi Rahmadini | Dio REST API + loading/error/empty + Future vs Stream (peran baku Anggota 3) | Menjelaskan ProductModel, ApiService, Dio, endpoint DummyJSON, ApiProvider, Product List/Detail, parsing JSON, error/retry, dan perbedaan Future dengan Stream. |
| 4. Galih Havid | Integrasi UI, pengujian, Security Rules & dokumentasi (peran tambahan Anggota 4) | Menjelaskan alur integrasi antar modul, ProductCard dan tampilan responsif, hasil flutter analyze/test/build, konsep Security Rules, README, screenshot, dan koordinasi video. |

Saran pemerataan: Galih tidak hanya bertugas mengambil screenshot atau mengedit video. Ia perlu memahami alur integrasi dan hasil pengujian, serta ikut melakukan demo fitur. Setiap anggota sebaiknya mencoba menjalankan aplikasi dan menjelaskan kode bagiannya secara langsung.


## 10.1 Matriks tanggung jawab

| Aktivitas | Rizzy | Adilla | Farinda | Galih |
| --- | --- | --- | --- | --- |
| Auth dan navigasi | Lead | Belajar | Belajar | Review |
| Firestore CRUD | Review | Lead | Belajar | Review |
| REST API Dio | Review | Belajar | Lead | Review |
| UI integration & testing | Koordinasi | Uji CRUD | Uji API | Lead |
| Security Rules & README | Koordinasi | Review rules | Review API docs | Lead dokumentasi |
| Video presentasi | Demo Auth | Demo CRUD | Demo API | Koordinasi/editing |


# 11. Panduan menjalankan dan menguji aplikasi


## 11.1 Persiapan

1. Pastikan Flutter SDK dan Dart tersedia pada PATH.
1. Pastikan Chrome tersedia untuk target Flutter Web.
1. Pastikan proyek Firebase warungstock-uts masih dapat diakses oleh tim.
1. Pastikan file konfigurasi Firebase yang diperlukan tersedia sesuai instruksi repositori.

## 11.2 Menyiapkan dependensi dan konfigurasi

```text
flutter pub get flutterfire configure --project=warungstock-uts --platforms=web
```

Perintah FlutterFire configure digunakan untuk menghubungkan konfigurasi aplikasi dengan Firebase. Ikuti instruksi README proyek dan jangan membagikan credential pribadi atau file rahasia.


## 11.3 Menjalankan aplikasi

```text
flutter run -d chrome
```


## 11.4 Pemeriksaan kualitas

```text
flutter analyze flutter test flutter build web --release
```


## 11.5 Deployment Security Rules

Deployment harus dilakukan oleh anggota yang memiliki izin pada proyek Firebase. Sebelum Publish, tinjau isi firestore.rules dan pastikan cocok dengan struktur dokumen aktual. Setelah publish, uji akses menggunakan akun pengguna yang berbeda. Jangan menganggap file lokal sudah aktif di Firebase sebelum deployment berhasil.

```text
firebase deploy --only firestore:rules
```

Perintah CLI di atas memerlukan konfigurasi Firebase CLI yang benar dan file firebase.json yang sesuai. Alternatifnya, salin isi file Rules ke Firebase Console → Firestore Database → Rules, lalu Publish.


# 12. Materi belajar dan pertanyaan presentasi

Mengapa menggunakan Flutter Web?

Agar aplikasi dapat dijalankan melalui browser dan memenuhi target platform proyek UTS.

Apa fungsi Firebase Authentication?

Mengelola identitas dan sesi pengguna, termasuk register, login, logout, serta perubahan status autentikasi.

Mengapa data inventaris memakai users/{uid}/items?

Untuk memisahkan data setiap pengguna berdasarkan UID dan mendukung aturan akses per pemilik.

Apa perbedaan Firestore dan REST API DummyJSON?

Firestore menyimpan data inventaris aplikasi, sedangkan DummyJSON menyediakan data produk eksternal untuk katalog referensi.

Apa fungsi Dio?

HTTP client untuk mengirim request ke REST API dan menerima respons.

Apa fungsi Model?

Merepresentasikan data sebagai objek Dart dan membantu proses parsing/serialisasi.

Apa fungsi Service?

Memisahkan detail komunikasi ke Firebase/API dari UI dan Provider.

Apa fungsi Provider?

Menyediakan state dan logika yang dapat digunakan widget; ChangeNotifier memberi notifikasi saat state berubah.

Apa perbedaan Future dan Stream?

Future menghasilkan satu penyelesaian asynchronous; Stream dapat menghasilkan banyak event selama subscription.

Mengapa ada state loading, empty, dan error?

Agar UI memberi umpan balik yang sesuai selama proses, ketika data kosong, atau saat terjadi kegagalan.

Mengapa perlu Security Rules jika UI sudah membatasi akses?

Pembatasan UI dapat dilewati; Rules menegakkan otorisasi pada sisi layanan Firestore.

Apakah Rules sudah teruji di Emulator?

Belum menurut laporan Phase 6C; emulator tidak dijalankan karena Java 8. Evaluasi yang ada bersifat statis.

Apakah Rules sudah di-deploy?

Belum dikonfirmasi dan laporan menyebut belum dilakukan.

Apa makna 34/34 test?

Semua test yang ada pada suite saat verifikasi tersebut berhasil, tetapi tidak berarti semua kemungkinan perilaku telah diuji.


# 13. Rancangan alur presentasi 12–15 menit

Pembagian berikut menargetkan setiap anggota berbicara dan melakukan screen-sharing sekurang-kurangnya tiga menit. Sesuaikan dengan instruksi dosen dan pastikan semua anggota tampil sesuai ketentuan video.

| Waktu | Presenter | Materi / demonstrasi |
| --- | --- | --- |
| 00:00–01:00 | Semua anggota | Pembukaan, perkenalan, judul proyek dan tujuan. |
| 01:00–04:00 | Muhammad Rizzy | Latar belakang, arsitektur, struktur folder, Firebase initialization, AuthProvider, AuthGate, demo login/register/logout dan navigasi. |
| 04:00–07:00 | Adilla | ItemModel, FirestoreService, ItemProvider, path data, demo tambah/baca/update/hapus inventaris dan penjelasan Stream. |
| 07:00–10:00 | Farinda | ProductModel, Dio, ApiService, ApiProvider, demo katalog dan detail, loading/error/retry, Future vs Stream. |
| 10:00–13:00 | Galih | Integrasi UI, Security Rules, ViewState lintas modul, hasil 34 test, analyze dan build, README serta checklist pengumpulan. |
| 13:00–15:00 | Semua anggota | Kesimpulan, manfaat, keterbatasan, dan penutup. |

Perhatian: bila durasi presentasi harus tepat 12 menit, padatkan pembukaan dan penutup. Jangan mengurangi waktu bicara/screen-share minimum yang diwajibkan untuk setiap anggota.


## 13.1 Saran demonstrasi langsung

1. Tunjukkan halaman login dan registrasi.
1. Login menggunakan akun demo yang telah disiapkan (jangan tampilkan password di rekaman).
1. Tambahkan satu barang inventaris, lalu tunjukkan barang muncul di daftar.
1. Ubah stok atau harga dan tunjukkan hasilnya.
1. Hapus barang demo.
1. Buka katalog DummyJSON, pilih produk, lalu tampilkan detailnya.
1. Jelaskan state loading/error/empty dan perbedaan Future/Stream.
1. Tunjukkan hasil test dan struktur Security Rules; jelaskan secara jujur apakah Rules sudah di-deploy.

# 14. Checklist final submission

- ☐ Isi nama lengkap dan NIM seluruh anggota di README.
- ☐ Sepakati dan isi peran tambahan Galih sebagai Anggota 4.
- ☐ Periksa URL clone GitHub pada README.
- ☐ Ambil enam screenshot asli: Login, Register, Dashboard Inventaris, Dialog Tambah Barang, Katalog DummyJSON, Detail Produk.
- ☐ Simpan screenshot dengan nama yang sesuai panduan docs/screenshots/README.md.
- ☐ Deploy Firestore Security Rules ke proyek Firebase dan uji setelah publish.
- ☐ Rekam video sesuai durasi dan ketentuan dosen; pastikan semua anggota bicara dan screen-share minimal tiga menit.
- ☐ Unggah video ke Google Drive dan atur akses sesuai instruksi pengumpulan.
- ☐ Masukkan tautan video ke README.
- ☐ Jalankan ulang flutter analyze, flutter test, flutter build web --release, dan git diff --check.
- ☐ Tinjau git status dan commit dokumentasi, Rules, serta screenshot yang sudah final.
- ☐ Push ke GitHub dan pastikan repositori dapat diakses dosen.

# 15. Glosarium

| Istilah | Penjelasan singkat |
| --- | --- |
| API | Antarmuka untuk komunikasi antar aplikasi/sistem. |
| CRUD | Create, Read, Update, Delete. |
| Dart async | Fasilitas pemrograman asynchronous seperti Future, async/await, dan Stream. |
| Firestore | Database dokumen NoSQL dari Firebase. |
| UID | User ID unik untuk akun Firebase Authentication. |
| Provider | Paket state management Flutter. |
| ChangeNotifier | Kelas yang memberi notifikasi kepada listener ketika state berubah. |
| MultiProvider | Widget untuk menyediakan beberapa Provider pada subtree aplikasi. |
| REST API | Gaya antarmuka web yang diakses melalui HTTP. |
| Dio | Paket HTTP client untuk Dart/Flutter. |
| JSON | Format pertukaran data berbasis teks. |
| Widget test | Pengujian perilaku widget Flutter. |
| Security Rules | Aturan server-side yang menentukan izin akses data Firebase. |
| Emulator | Lingkungan lokal untuk menjalankan layanan Firebase tanpa langsung memakai layanan produksi. |


# Lampiran A — Informasi yang perlu dikonfirmasi tim

- NIM masing-masing anggota.
- URL repositori GitHub yang final.
- Apakah Galih menyetujui peran integrasi UI, pengujian, Security Rules, dan dokumentasi.
- Status deployment Firestore Rules setelah dilakukan.
- Nama file dan keberadaan enam screenshot final.
- URL Google Drive video demonstrasi.

# Lampiran B — Catatan checkpoint Git

| Commit | Deskripsi |
| --- | --- |
| 4ddcfae | chore: initialize Flutter Web project |
| 403d16a | chore: add core dependencies and project structure |
| 22b8b54 | feat: implement Firebase authentication |
| c464610 | feat: implement Firestore CRUD inventory management (Phase 4A) |
| 7df9726 | feat: implement REST API backend foundation with Dio and DummyJSON |
| 984558b | feat: implement DummyJSON product catalog UI and HomeScreen navigation (Phase 5B) |

Phase 6B/6C belum di-commit pada laporan terakhir. Daftar commit ini berasal dari checkpoint yang dilaporkan selama pengerjaan dan perlu dicocokkan dengan git log aktual sebelum dijadikan catatan rilis resmi.
