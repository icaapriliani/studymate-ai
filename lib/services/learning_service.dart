import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class LearningService {
  final FirebaseFirestore _firestore;

  LearningService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _materialsCollection =>
      _firestore.collection('materials');

  CollectionReference<Map<String, dynamic>> _modulesCollection(String materialId) =>
      _firestore.collection('materials').doc(materialId).collection('modules');

  CollectionReference<Map<String, dynamic>> _progressCollection(String uid) =>
      _firestore.collection('users').doc(uid).collection('module_progress');

  /// Streams all materials from Firestore ordered by creation date
  Stream<QuerySnapshot<Map<String, dynamic>>> streamMaterials() {
    debugPrint('[LearningService] streamMaterials() dipanggil, melakukan query ke Firestore...');
    return _materialsCollection
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      debugPrint('[LearningService] streamMaterials() menerima snapshot. Jumlah dokumen: ${snapshot.docs.length}');
      for (var doc in snapshot.docs) {
        debugPrint('[LearningService] - Material ditemukan: ID=${doc.id}, Title=${doc.data()['title']}');
      }
      return snapshot;
    }).handleError((error, stackTrace) {
      debugPrint('[LearningService] streamMaterials() ERROR: $error');
      debugPrint('[LearningService] STACKTRACE: $stackTrace');
    });
  }

  /// Streams all modules for a specific material ordered by orderIndex
  Stream<QuerySnapshot<Map<String, dynamic>>> streamModules(String materialId) {
    debugPrint('[LearningService] streamModules() dipanggil untuk materialId: $materialId');
    return _modulesCollection(materialId)
        .orderBy('orderIndex', descending: false)
        .snapshots()
        .map((snapshot) {
      debugPrint('[LearningService] streamModules() untuk $materialId menerima snapshot. Jumlah modul: ${snapshot.docs.length}');
      for (var doc in snapshot.docs) {
        debugPrint('[LearningService] - Modul ditemukan: ID=${doc.id}, Title=${doc.data()['title']}, OrderIndex=${doc.data()['orderIndex']}');
      }
      return snapshot;
    }).handleError((error, stackTrace) {
      debugPrint('[LearningService] streamModules() untuk $materialId ERROR: $error');
      debugPrint('[LearningService] STACKTRACE: $stackTrace');
    });
  }

  /// Streams all module progress for a specific user
  Stream<QuerySnapshot<Map<String, dynamic>>> streamUserModuleProgress(String uid) {
    debugPrint('[LearningService] streamUserModuleProgress() dipanggil untuk uid: $uid');
    return _progressCollection(uid).snapshots().map((snapshot) {
      debugPrint('[LearningService] streamUserModuleProgress() untuk $uid menerima snapshot. Jumlah progres: ${snapshot.docs.length}');
      return snapshot;
    }).handleError((error, stackTrace) {
      debugPrint('[LearningService] streamUserModuleProgress() untuk $uid ERROR: $error');
      debugPrint('[LearningService] STACKTRACE: $stackTrace');
    });
  }

  /// Saves or updates the progress of a module for a user
  Future<void> saveModuleProgress(String uid, String materialId, String moduleId, bool completed) async {
    debugPrint('[LearningService] saveModuleProgress() dipanggil: uid=$uid, materialId=$materialId, moduleId=$moduleId, completed=$completed');
    try {
      final docRef = _progressCollection(uid).doc(moduleId);
      final now = Timestamp.now();
      
      debugPrint('[LearningService] Menyimpan ke path: ${docRef.path}');
      await docRef.set({
        'materialId': materialId,
        'completed': completed,
        'lastReadAt': now,
        'completedAt': completed ? now : FieldValue.delete(),
      }, SetOptions(merge: true));
      debugPrint('[LearningService] saveModuleProgress() BERHASIL untuk moduleId: $moduleId');
    } catch (e, stackTrace) {
      debugPrint('[LearningService] saveModuleProgress() GAGAL untuk moduleId: $moduleId, Error: $e');
      debugPrint('[LearningService] STACKTRACE: $stackTrace');
      rethrow;
    }
  }

  /// Simple seeder test to write a single document and subcollection document to Firestore
  Future<void> runSimpleSeederTest() async {
    debugPrint('[SEEDER TEST] Memulai seeder test sederhana...');
    try {
      final testMatRef = _materialsCollection.doc('seeder_test_material');
      debugPrint('[SEEDER TEST] Menulis material dummy ke path: ${testMatRef.path}');
      await testMatRef.set({
        'title': 'Test Material Dummy',
        'description': 'Ini adalah material dummy untuk testing koneksi Firestore write.',
        'category': 'Test',
        'thumbnailColor': 'FF0000',
        'estimatedMinutes': 5,
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('[SEEDER TEST] Material dummy BERHASIL dibuat!');

      final testModRef = testMatRef.collection('modules').doc('seeder_test_module');
      debugPrint('[SEEDER TEST] Menulis module dummy ke path: ${testModRef.path}');
      await testModRef.set({
        'title': 'Test Module Dummy',
        'content': 'Ini adalah konten module dummy untuk testing.',
        'orderIndex': 0,
        'estimatedMinutes': 5,
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('[SEEDER TEST] Module dummy BERHASIL dibuat!');
      debugPrint('[SEEDER TEST] SEED TEST SUCCESS: Seluruh penulisan dummy berhasil!');
    } catch (e, stackTrace) {
      debugPrint('[SEEDER TEST] SEED TEST FAILED: Penulisan dummy gagal!');
      debugPrint('[SEEDER TEST] ERROR ASLI: $e');
      debugPrint('[SEEDER TEST] STACKTRACE: $stackTrace');
      rethrow;
    }
  }

  /// Seeds default materials and modules if the materials collection is empty or lacks modules subcollection
  Future<void> seedDefaultMaterialsIfNeeded() async {
    debugPrint('[LearningService] seedDefaultMaterialsIfNeeded() dipanggil.');
    try {
      bool needsSeeding = false;
      debugPrint('[LearningService] Memeriksa koleksi materials...');
      final snapshot = await _materialsCollection.limit(1).get();
      
      if (snapshot.docs.isEmpty) {
        debugPrint('[LearningService] Koleksi materials KOSONG. Menjalankan seeding default...');
        needsSeeding = true;
      } else {
        debugPrint('[LearningService] Koleksi materials memiliki data. Memeriksa subkoleksi modules under "db_systems"...');
        // Check if the representative subcollection 'modules' under 'db_systems' has any documents
        final modulesSnapshot = await _modulesCollection('db_systems').limit(1).get();
        if (modulesSnapshot.docs.isEmpty) {
          debugPrint('[LearningService] Deteksi DATA LAMA (subkoleksi modules kosong). Menjalankan migrasi database...');
          needsSeeding = true;
        } else {
          // Check if representative module 'db_systems_m1' has the updated high-quality video URL to trigger migration if not
          final testDoc = await _modulesCollection('db_systems').doc('db_systems_m1').get();
          if (testDoc.exists) {
            final testUrl = testDoc.data()?['youtubeUrl'] as String?;
            if (testUrl != 'https://www.youtube.com/watch?v=fxe6qev-bno') {
              debugPrint('[LearningService] Deteksi DATA LAMA/KADALUARSA (URL video tidak cocok). Menjalankan migrasi database...');
              needsSeeding = true;
            } else {
              debugPrint('[LearningService] Subkoleksi modules tidak kosong dan skema data mutakhir. Seeding dilewati.');
            }
          } else {
            needsSeeding = true;
          }
        }
      }

      if (!needsSeeding) {
        debugPrint('[LearningService] Database sudah ter-seed dengan benar. Melewati seeding.');
        return;
      }

      debugPrint('[LearningService] SEEDING DIMULAI: Memulai pembersihan data lama untuk migrasi...');
      // Clean up old materials to avoid duplicate or broken entries during demo migration
      final allMaterials = await _materialsCollection.get();
      debugPrint('[LearningService] Berhasil mengambil seluruh materi. Ditemukan ${allMaterials.docs.length} dokumen materials.');
      if (allMaterials.docs.isNotEmpty) {
        debugPrint('[LearningService] Menghapus ${allMaterials.docs.length} dokumen materials lama untuk migrasi...');
        final cleanupBatch = _firestore.batch();
        for (final doc in allMaterials.docs) {
          // Delete modules under this material first to be perfectly thorough
          debugPrint('[LearningService] Mengambil subkoleksi modules untuk material: ${doc.id}');
          final modulesSnap = await _modulesCollection(doc.id).get();
          debugPrint('[LearningService] Menghapus ${modulesSnap.docs.length} dokumen modul di bawah ${doc.id}');
          for (final mDoc in modulesSnap.docs) {
            cleanupBatch.delete(mDoc.reference);
          }
          cleanupBatch.delete(doc.reference);
        }
        debugPrint('[LearningService] Meng-commit batch pembersihan data lama...');
        await cleanupBatch.commit();
        debugPrint('[LearningService] Sukses membersihkan data lama dari Firestore.');
      }

      final batch = _firestore.batch();
      final now = Timestamp.now();

      // ==========================================
      // MATERIAL 1: Sistem Manajemen Basis Data
      // ==========================================
      final mat1Ref = _materialsCollection.doc('db_systems');
      batch.set(mat1Ref, {
        'title': 'Sistem Manajemen Basis Data',
        'description': 'Sistem Manajemen Basis Data (DBMS) adalah perangkat lunak terintegrasi yang dirancang untuk mengelola, menyimpan, memanipulasi, dan mengambil data secara efisien dan aman. DBMS menjadi tulang punggung utama bagi sistem informasi modern dengan menyediakan abstraksi data, integritas referensial, kontrol konkurensi multi-user, serta mekanisme pemulihan data setelah terjadinya kegagalan sistem.',
        'category': 'Ilmu Komputer',
        'thumbnailColor': '1E58C1',
        'estimatedMinutes': 120, // Will be dynamically computed by provider
        'keyPoints': [
          'Arsitektur Data: Tiga tingkatan abstraksi data (Fisik, Konseptual, dan Pandangan) untuk kemandirian data.',
          'Model Relasional: Pengorganisasian informasi ke dalam tabel dua dimensi dengan baris dan kolom terstruktur.',
          'Integritas Kunci: Penerapan Primary Key dan Foreign Key untuk menjamin keabsahan hubungan antar tabel.',
          'Normalisasi Database: Proses perancangan data untuk menghindari anomali dan redundansi penyimpanan.'
        ],
        'sampleQuestions': [
          {
            'question': 'Apa tujuan utama dari proses normalisasi pada database relasional?',
            'answer': 'Tujuan utama normalisasi adalah untuk meminimalkan redundansi data dan menghindari anomali pembaruan (insert, update, delete anomalies).',
            'explanation': 'Normalisasi memecah tabel besar menjadi tabel-tabel kecil yang saling berhubungan dengan mematuhi aturan formal (1NF, 2NF, 3NF), sehingga integritas data tetap terjaga.',
          },
          {
            'question': 'Sebutkan perbedaan mendasar antara skema fisik dan skema logis data!',
            'answer': 'Skema fisik mendeskripsikan bagaimana data disimpan secara nyata di dalam media penyimpanan keras, sedangkan skema logis mendeskripsikan struktur data secara konseptual dan hubungan antar data.',
            'explanation': 'Kemandirian data logis menjamin bahwa perubahan pada skema fisik (misalnya perubahan lokasi file penyimpanan database) tidak akan merusak program aplikasi yang mengakses skema logis.',
          }
        ],
        'createdAt': now,
      });

      // Modules for Material 1
      final m1_1Ref = mat1Ref.collection('modules').doc('db_systems_m1');
      batch.set(m1_1Ref, {
        'title': 'Pengantar Basis Data & Arsitektur Abstraksi',
        'content': r'''# Pengantar Basis Data & Arsitektur Abstraksi

## Pendahuluan
Dalam era transformasi digital saat ini, data telah menjadi aset yang paling berharga bagi organisasi. Kebutuhan untuk menyimpan, mengelola, dan memproses informasi secara cepat dan aman melahirkan konsep sistem basis data. Tanpa sistem yang terstruktur, organisasi akan menghadapi masalah besar seperti inkonsistensi informasi, kesulitan dalam pencarian data, serta risiko kebocoran data yang tinggi. Sistem Manajemen Basis Data (DBMS) hadir sebagai solusi perangkat lunak komprehensif untuk menjawab tantangan tersebut.

## Penjelasan Konsep Utama
Sistem Manajemen Basis Data (DBMS) bertindak sebagai perantara atau antarmuka antara database fisik dengan pengguna akhir maupun aplikasi program. DBMS menyembunyikan detail teknis penyimpanan melalui konsep **Abstraksi Data**. Abstraksi ini dibagi menjadi tiga tingkatan utama menurut arsitektur ANSI-SPARC:
1. **Level Fisik (Physical Level)**: Tingkat terendah yang mendeskripsikan *bagaimana* data disimpan secara nyata di dalam media penyimpanan keras (seperti harddisk atau SSD), termasuk struktur indeks dan alokasi blok memori.
2. **Level Konseptual (Conceptual Level)**: Tingkat menengah yang menggambarkan *apa* data yang disimpan di dalam database serta hubungan logis apa saja yang terjadi di antara data tersebut. Tingkat ini biasanya dirancang oleh database designer.
3. **Level Pandangan (View/External Level)**: Tingkat tertinggi yang mendeskripsikan hanya sebagian dari isi database yang relevan bagi pengguna akhir tertentu, sehingga menjaga privasi dan keamanan sistem.

> **Abstraksi Data**: Konsep ini memberikan kemandirian data (data independence). Artinya, jika kita melakukan optimasi atau perubahan pada media penyimpanan fisik (Physical Level), kita tidak perlu mengubah kode program aplikasi kita yang bekerja pada tingkat pandangan (View Level).

## Contoh Sederhana
Bayangkan sebuah sistem akademik kampus. Mahasiswa hanya dapat melihat Kartu Hasil Studi (KHS) milik mereka sendiri melalui portal akademis. Portal ini adalah perwujudan dari **Level Pandangan (View Level)**. Di sisi lain, Kepala Program Studi dapat melihat data nilai seluruh mahasiswa di jurusannya, yang mewakili **Level Konseptual**. Sementara itu, file data biner riil berisi ribuan baris data tersebut yang terenkripsi di dalam server kampus dikelola langsung oleh DBMS pada **Level Fisik**.

## Poin Penting
- **Mencegah Inkonsistensi**: Menghindari anomali di mana data yang sama memiliki nilai berbeda di tempat berbeda.
- **Mendukung Konkurensi**: Memungkinkan ratusan pengguna membaca dan menulis data pada detik yang sama secara aman.
- **Keamanan Terpusat**: Pembatasan hak akses baca/tulis data melalui autentikasi pengguna secara dinamis.

## Mini Rangkuman
DBMS adalah fondasi utama teknologi informasi modern yang bertugas mengelola data secara efisien dan aman. Melalui arsitektur tiga level abstraksi data, DBMS berhasil memisahkan kompleksitas penyimpanan fisik dari kebutuhan praktis pengguna akhir, menciptakan kemandirian data yang tangguh dan mudah dirawat.''',
        'orderIndex': 0,
        'youtubeUrl': 'https://www.youtube.com/watch?v=fxe6qev-bno',
        'youtubeTitle': 'DATABASE #1 : PENGENALAN DATABASE',
        'youtubeChannel': 'Web Programming UNPAS',
        'createdAt': now,
      });

      final m1_2Ref = mat1Ref.collection('modules').doc('db_systems_m2');
      batch.set(m1_2Ref, {
        'title': 'Model Data Relasional & Peran Kunci (Keys)',
        'content': r'''# Model Data Relasional & Peran Kunci (Keys)

## Pendahuluan
Setelah memahami konsep dasar basis data, langkah berikutnya adalah mempelajari bagaimana data tersebut diorganisasikan. Model data relasional adalah standar industri yang paling populer dan banyak digunakan di seluruh dunia saat ini. Diperkenalkan oleh Dr. Edgar F. Codd pada tahun 1970, model ini menyederhanakan representasi data ke dalam bentuk tabel dua dimensi yang intuitif namun memiliki landasan matematis teori himpunan yang sangat kuat.

## Penjelasan Konsep Utama
Dalam model relasional, database direpresentasikan sebagai kumpulan relasi yang saling berhubungan. Istilah-istilah formal dalam model relasional meliputi:
- **Relasi (Relation)**: Tabel dua dimensi yang terdiri dari baris dan kolom.
- **Atribut (Attribute)**: Kolom pada tabel yang mendefinisikan karakteristik data.
- **Tuple (Baris)**: Baris tunggal dalam tabel yang merepresentasikan satu record data riil.
- **Domain**: Kumpulan nilai yang diperbolehkan untuk suatu atribut (misal: domain nilai untuk Jenis Kelamin adalah "L" atau "P").

Untuk mengaitkan data antar tabel secara logis dan menjamin integritas data, model relasional menggunakan konsep **Kunci (Keys)**:
1. **Candidate Key**: Satu atau kombinasi beberapa atribut minimal yang secara unik dapat mengidentifikasi setiap baris data di dalam tabel.
2. **Primary Key (Kunci Utama)**: Salah satu *Candidate Key* yang dipilih secara khusus oleh administrator basis data untuk menjadi identitas utama tabel. Nilai Primary Key wajib bersifat unik dan tidak boleh bernilai kosong (NOT NULL).
3. **Foreign Key (Kunci Tamu)**: Atribut dalam suatu tabel yang nilainya merujuk pada *Primary Key* di tabel lain. Kunci ini digunakan untuk membangun relasi antar tabel dan menjamin integritas referensial.

> **Integritas Referensial**: Aturan yang menjamin bahwa nilai Foreign Key di tabel anak harus selalu ada di dalam kolom Primary Key tabel induk. Hal ini mencegah adanya data "yatim piatu" yang tidak valid dalam relasi database.

## Contoh Sederhana
Mari kita tinjau relasi antara tabel `Dosen` dan tabel `MataKuliah`. Tabel `Dosen` memiliki Primary Key `NIDN` (Nomor Induk Dosen Nasional). Tabel `MataKuliah` memiliki Primary Key `Kode_MK` dan Foreign Key `NIDN_Pengajar` yang merujuk langsung ke tabel `Dosen`. 
Jika kita mencoba memasukkan mata kuliah baru dengan pengajar ber-`NIDN` "99999" sedangkan di tabel `Dosen` tidak ada dosen dengan nomor induk tersebut, DBMS akan menolak perintah tersebut untuk melindungi integritas sistem.

## Poin Penting
- **Keunikan Data**: Primary Key menjamin bahwa tidak akan ada dua baris data yang identik di dalam sebuah tabel database.
- **Relasi Logis**: Hubungan antar tabel dibangun secara konseptual melalui keterkaitan nilai kunci, bukan melalui pointer fisik memori.
- **Cascade Operations**: Kita dapat mengatur aksi otomatis seperti `ON DELETE CASCADE` di mana jika data dosen dihapus, seluruh mata kuliah yang diajarkannya juga akan otomatis terhapus.

## Mini Rangkuman
Model data relasional menyusun informasi ke dalam tabel terstruktur yang saling terhubung menggunakan kunci data. Pemilihan Primary Key yang tepat dan pemetaan Foreign Key yang disiplin sangat krusial untuk menjamin keunikan data dan mempertahankan integritas referensial di seluruh relasi database.''',
        'orderIndex': 1,
        'createdAt': now,
      });

      final m1_3Ref = mat1Ref.collection('modules').doc('db_systems_m3');
      batch.set(m1_3Ref, {
        'title': 'Entity-Relationship Diagram (ERD) Konseptual',
        'content': r'''# Entity-Relationship Diagram (ERD) Konseptual

## Pendahuluan
Sebelum membangun database fisik menggunakan kueri pemrograman, seorang perancang basis data harus membuat cetak biru atau arsitektur konseptual terlebih dahulu. Membuat database tanpa perencanaan matang di awal akan mengakibatkan kegagalan sistem di masa depan akibat struktur tabel yang berantakan dan lambat. Alat bantu pemodelan data yang paling populer untuk merancang skema konseptual ini adalah *Entity-Relationship Diagram* (ERD).

## Penjelasan Konsep Utama
ERD menggambarkan struktur logis database dalam representasi grafis. Terdapat tiga komponen dasar pembentuk ERD:
1. **Entitas (Entity)**: Objek di dunia nyata yang dapat dibedakan dari objek lain dan relevan untuk disimpan datanya (misal: `Mahasiswa`, `Buku`, `Transaksi`). Digambarkan dengan simbol persegi panjang.
2. **Atribut (Attribute)**: Karakteristik atau properti yang melekat pada suatu entitas (misal: entitas `Mahasiswa` memiliki atribut NIM, Nama, dan Alamat). Atribut digambarkan dengan simbol elips. Atribut terbagi menjadi:
   - *Key Attribute*: Atribut unik penentu identitas (Primary Key).
   - *Composite Attribute*: Atribut yang dapat dipecah lagi (misal: Nama dipecah menjadi Nama Depan dan Nama Belakang).
   - *Derived Attribute*: Atribut yang nilainya dihitung dari atribut lain (misal: Umur dihitung dari Tanggal Lahir).
3. **Hubungan (Relationship)**: Hubungan logis yang terjadi antar entitas (misal: Mahasiswa *meminjam* Buku). Digambarkan dengan simbol belah ketupat.

> **Kardinalitas Relasi**: Menentukan batas jumlah maksimum instansi entitas yang dapat berelasi dengan instansi entitas lainnya. Pilihan kardinalitas meliputi:
> - **One-to-One (1:1)**: Satu baris tabel A hanya berelasi dengan satu baris tabel B (misal: Suami dan Istri).
> - **One-to-Many (1:N)**: Satu baris tabel A dapat berelasi dengan banyak baris di tabel B (misal: Jurusan memiliki banyak Mahasiswa).
> - **Many-to-Many (N:M)**: Banyak baris tabel A dapat saling berelasi dengan banyak baris di tabel B (misal: Mahasiswa mengambil banyak Mata Kuliah).

## Contoh Sederhana
Dalam merancang sistem perpustakaan digital:
- Kita membuat entitas `Anggota` dengan atribut kunci `ID_Anggota`.
- Kita membuat entitas `Buku` dengan atribut kunci `ISBN`.
- Keduanya dihubungkan oleh relasi `Meminjam` yang memiliki atribut derived `Tanggal_Kembali`. Kardinalitas relasi ini adalah Many-to-Many (N:M) karena satu anggota bisa meminjam banyak buku, dan satu buku bisa dipinjam oleh banyak anggota secara bergantian.

## Poin Penting
- **Komunikasi Klien**: ERD berfungsi sebagai alat komunikasi visual antara pengembang dengan klien non-teknis untuk menyamakan persepsi data.
- **Dokumentasi Struktur**: Menjadi panduan utama saat melakukan transformasi diagram menjadi tabel database fisik.
- **Validasi Aturan Bisnis**: Memastikan seluruh aturan bisnis organisasi telah diakomodasi oleh sistem database.

## Mini Rangkuman
ERD adalah diagram pemodelan konseptual yang merangkum entitas, atribut, dan hubungan relasi data di dunia nyata. Pemodelan ERD yang akurat beserta penentuan kardinalitas yang presisi merupakan langkah wajib guna menciptakan arsitektur basis data yang efisien, kokoh, dan berkinerja tinggi.''',
        'orderIndex': 2,
        'createdAt': now,
      });

      final m1_4Ref = mat1Ref.collection('modules').doc('db_systems_m4');
      batch.set(m1_4Ref, {
        'title': 'SQL Komprehensif: DDL, DML & Kontrol Transaksi',
        'content': r'''# SQL Komprehensif: DDL, DML & Kontrol Transaksi

## Pendahuluan
Setelah arsitektur basis data selesai dirancang menggunakan ERD, saatnya mengimplementasikannya ke dalam bentuk nyata. Bahasa Kueri Terstruktur atau *Structured Query Language* (SQL) adalah bahasa standar internasional yang digunakan untuk berinteraksi, memanipulasi, dan mengontrol database relasional. SQL bersifat deklaratif; artinya kita cukup menuliskan *apa* data yang kita inginkan, dan DBMS yang akan memikirkan *bagaimana* cara terbaik untuk mengambilnya secara fisik.

## Penjelasan Konsep Utama
SQL secara garis besar dibagi menjadi tiga sub-bahasa utama yang memiliki fungsi berbeda:

### 1. DDL (Data Definition Language)
DDL digunakan untuk membuat, mengubah, dan menghapus struktur arsitektur tabel database itu sendiri. Contoh kueri utama DDL:
- `CREATE TABLE`: Membuat tabel baru lengkap dengan nama kolom, tipe data, dan konstrain kunci.
- `ALTER TABLE`: Mengubah struktur tabel yang sudah ada (menambah kolom baru, menghapus kolom, atau mengubah tipe data).
- `DROP TABLE`: Menghapus tabel beserta seluruh datanya secara permanen dari memori.

### 2. DML (Data Manipulation Language)
DML digunakan untuk mengelola data operasional di dalam struktur tabel yang telah didefinisikan oleh DDL. Contoh kueri utama DML:
- `SELECT`: Mengambil dan memfilter data dari satu atau beberapa tabel.
- `INSERT INTO`: Memasukkan baris data baru ke dalam tabel.
- `UPDATE`: Memperbarui nilai data pada baris yang sudah ada.
- `DELETE`: Menghapus baris data tertentu berdasarkan kondisi kriteria.

### 3. TCL (Transaction Control Language)
TCL menjamin keamanan proses modifikasi data melalui manajemen transaksi. Transaksi adalah kumpulan satu atau beberapa operasi SQL DML yang harus dijalankan sebagai satu kesatuan utuh. Perintah utama TCL meliputi:
- `COMMIT`: Menyimpan seluruh perubahan transaksi ke database secara permanen.
- `ROLLBACK`: Membatalkan seluruh perubahan transaksi dan mengembalikan kondisi data ke keadaan semula sebelum transaksi dimulai jika terjadi kegagalan sistem di tengah jalan.

> **Konsep Transaksi**: Menjamin kepatuhan terhadap prinsip ACID, khususnya sifat *Atomicity* (semua kueri berhasil dijalankan, atau tidak ada yang dijalankan sama sekali).

## Contoh Sederhana
Bayangkan transaksi transfer uang bank dari akun Budi ke akun Iwan sebesar Rp100.000. Sistem harus melakukan dua kueri DML UPDATE: mengurangi saldo Budi, lalu menambah saldo Iwan. 
```sql
START TRANSACTION;
UPDATE rekening SET saldo = saldo - 100000 WHERE nama = 'Budi';
UPDATE rekening SET saldo = saldo + 100000 WHERE nama = 'Iwan';
COMMIT;
```
Jika di tengah jalan server mati tepat setelah saldo Budi berkurang namun sebelum saldo Iwan bertambah, DBMS akan mendeteksi kegagalan tersebut dan otomatis menjalankan perintah `ROLLBACK` untuk mengembalikan saldo Budi agar uang tidak hilang secara misterius.

## Poin Penting
- **Bahasa Standar**: SQL digunakan oleh hampir seluruh RDBMS populer seperti PostgreSQL, MySQL, SQL Server, dan Oracle.
- **Optimasi Kueri**: DBMS menggunakan komponen internal *Query Optimizer* untuk memilih jalur tercepat dalam mengeksekusi perintah SQL kita.
- **Konstrain Keamanan**: SQL mendukung pembatasan keamanan melalui pembuatan *View* dan pengaturan hak istimewa pengguna (*Grant/Revoke*).

## Mini Rangkuman
SQL adalah instrumen utama untuk mengendalikan database relasional. Dengan menguasai pembagian kerja DDL untuk merancang tabel, DML untuk memanipulasi baris data, serta TCL untuk mengamankan keutuhan transaksi melalui mekanisme commit-rollback, kita dapat membangun sistem backend aplikasi yang kokoh dan tangguh.''',
        'orderIndex': 3,
        'youtubeUrl': 'https://www.youtube.com/watch?v=xYBclb-sYQ4',
        'youtubeTitle': 'Tutorial MySQL Database (Bahasa Indonesia)',
        'youtubeChannel': 'Programmer Zaman Now',
        'createdAt': now,
      });

      // ==========================================
      // MATERIAL 2: Kecerdasan Buatan
      // ==========================================
      final mat2Ref = _materialsCollection.doc('ai_fuzzy');
      batch.set(mat2Ref, {
        'title': 'Kecerdasan Buatan & Logika Fuzzy',
        'description': 'Kecerdasan Buatan (AI) adalah cabang ilmu komputer yang berfokus pada perancangan sistem komputer cerdas yang mampu berpikir, menalar, belajar, dan mengambil keputusan rasional layaknya kemampuan kognitif manusia. Modul komprehensif ini membimbing Anda memahami paradigma agen cerdas, algoritma pencarian rute heuristik A*, teori Logika Fuzzy untuk menangani ketidakpastian, hingga perancangan Sistem Inferensi Fuzzy (FIS) Mamdani dan Sugeno.',
        'category': 'Kecerdasan Buatan',
        'thumbnailColor': '6B3BC7',
        'estimatedMinutes': 180, // Will be dynamically computed by provider
        'keyPoints': [
          'Rational Agent: Paradigma sistem cerdas yang bertindak memaksimalkan kinerja berdasarkan persepsi lingkungannya.',
          'Pencarian Heuristik: Algoritma A* yang memanfaatkan kombinasi g(n) dan h(n) untuk menemukan solusi rute terpendek secara optimal.',
          'Fuzzy Logic: Ekstensi logika Boolean klasik yang memperkenalkan nilai kebenaran parsial kontinu dalam rentang [0, 1].',
          'Inference & Defuzzification: Proses evaluasi aturan linguistik menggunakan min-max serta konversi tegas melalui metode Centroid.'
        ],
        'sampleQuestions': [
          {
            'question': 'Apa yang dimaksud dengan fungsi heuristik yang bersifat admissible pada algoritma pencarian A*?',
            'answer': 'Fungsi heuristik h(n) dikatakan admissible jika fungsi tersebut tidak pernah memberikan estimasi biaya yang lebih besar daripada biaya sebenarnya menuju node tujuan.',
            'explanation': 'Sifat admissible menjamin bahwa algoritma A* akan selalu menemukan jalur solusi yang benar-benar terpendek (optimal) dan tidak melewatkan rute terbaik akibat estimasi heuristik yang berlebihan.',
          },
          {
            'question': 'Jelaskan perbedaan mendasar antara metode defuzzifikasi Centroid dengan metode COGS!',
            'answer': 'Metode Centroid (Center of Gravity) menghitung titik pusat area geometri hasil penalaran fuzzy, sedangkan COGS (Center of Gravity of Sum) menggabungkan kontribusi dari setiap aturan secara penjumlahan area.',
            'explanation': 'Metode Centroid adalah metode defuzzifikasi yang paling umum digunakan pada sistem inferensi model Mamdani karena memberikan respons output yang halus dan kontinu terhadap perubahan input.',
          }
        ],
        'createdAt': now,
      });

      // Modules for Material 2
      final m2_1Ref = mat2Ref.collection('modules').doc('ai_fuzzy_m1');
      batch.set(m2_1Ref, {
        'title': 'Dasar Kecerdasan Buatan & Karakteristik Agen Cerdas',
        'content': r'''# Dasar Kecerdasan Buatan & Karakteristik Agen Cerdas

## Pendahuluan
Kecerdasan Buatan (AI) telah bergeser dari sekadar wacana fiksi ilmiah menjadi teknologi penggerak utama peradaban modern. Dari asisten suara pintar hingga kendaraan otonom, AI mentransformasi cara manusia berinteraksi dengan teknologi. Namun, untuk membangun sistem AI yang tangguh, kita tidak bisa hanya mengandalkan pemrograman ad-hoc. Kita memerlukan landasan ilmiah yang kuat mengenai apa arti "cerdas" itu sendiri, serta bagaimana mesin dapat memproses informasi secara rasional untuk memecahkan masalah.

## Penjelasan Konsep Utama
Dalam kecerdasan buatan modern, konsep dasar yang disepakati adalah **Agen Cerdas (Rational Agent)**. Agen adalah segala sesuatu yang dapat dipandang sebagai mengamati lingkungannya melalui **Sensor** dan bertindak terhadap lingkungan tersebut melalui **Aktuator**. 

Agen dikatakan rasional apabila agen tersebut bertindak sedemikian rupa untuk memaksimalkan metrik kinerja (*performance measure*) yang diharapkan, berdasarkan riwayat pengamatan yang diterima oleh sensornya dan pengetahuan bawaan yang dimilikinya. Untuk merancang agen cerdas secara sistematis, kita menggunakan kerangka kerja **PEAS**:
- **P (Performance Measure)**: Kriteria keberhasilan perilaku agen (misal: tingkat keselamatan dan efisiensi waktu pada mobil otonom).
- **E (Environment)**: Lingkungan fisik di mana agen beroperasi (misal: jalan raya, pejalan kaki, rambu lalu lintas).
- **A (Actuators)**: Alat yang digunakan agen untuk melakukan tindakan (misal: setir, pedal gas, rem).
- **S (Sensors)**: Alat yang digunakan agen untuk mengamati lingkungan (misal: kamera, radar, GPS).

> **Agen Rasional**: Rasionalitas tidak sama dengan kemahatahuan (omniscience). Agen rasional bertindak mengambil keputusan terbaik *berdasarkan data yang dimilikinya*, meskipun hasil akhirnya bisa saja tidak sempurna akibat ketidakpastian lingkungan luar.

## Contoh Sederhana
Tinjau robot penyedot debu otomatis di rumah Anda. 
- **P (Kinerja)**: Luas area lantai yang bersih dan efisiensi penggunaan baterai.
- **E (Lingkungan)**: Lantai keramik, karpet, meja, kursi, dan debu.
- **A (Aktuator)**: Roda penggerak, sikat penyedot, dan pemancar status suara.
- **S (Sensor)**: Sensor inframerah pendeteksi halangan, giroskop arah, dan detektor tingkat kepenuhan debu.
Robot akan memutuskan untuk berbelok jika sensor inframerahnya mendeteksi kaki meja di depannya, yang merupakan tindakan rasional untuk menghindari tabrakan.

## Poin Penting
- **Sensor & Aktuator**: Menjadi jembatan fisik interaksi agen dengan dunia luar.
- **Evaluasi PEAS**: Langkah pertama yang wajib dirumuskan sebelum menulis kode algoritma AI apa pun.
- **Tingkat Otonomi**: Agen cerdas yang baik harus memiliki kemampuan belajar (*machine learning*) agar tidak hanya bergantung pada pengetahuan bawaan yang diprogram di awal.

## Mini Rangkuman
Kecerdasan Buatan dibangun di atas paradigma Agen Cerdas yang bertindak rasional untuk memaksimalkan kinerja di lingkungannya. Kerangka kerja PEAS memandu kita memetakan komponen sensor, aktuator, kondisi lingkungan, dan metrik performa secara presisi guna merancang kecerdasan buatan yang berdaya guna tinggi.''',
        'orderIndex': 0,
        'youtubeUrl': 'https://www.youtube.com/watch?v=aO20B5g42Vw',
        'youtubeTitle': 'Pengenalan Machine Learning & Supervised Learning',
        'youtubeChannel': 'Kelas Terbuka',
        'createdAt': now,
      });

      final m2_2Ref = mat2Ref.collection('modules').doc('ai_fuzzy_m2');
      batch.set(m2_2Ref, {
        'title': 'Pencarian Heuristik & Penerapan Algoritma A*',
        'content': r'''# Pencarian Heuristik & Penerapan Algoritma A*

## Pendahuluan
Bagi seorang agen cerdas, salah satu masalah paling mendasar yang harus dipecahkan adalah bagaimana menemukan jalur solusi terbaik dari kondisi awal menuju kondisi tujuan. Di dalam sistem navigasi GPS atau game petualangan, pencarian rute harus dilakukan dalam hitungan milidetik. Metode pencarian buta (blind search) seperti BFS dan DFS akan memakan waktu sangat lama karena mengeksplorasi seluruh cabang tanpa arah. Di sinilah pentingnya pencarian terpandu yang memanfaatkan informasi tambahan, yang dikenal sebagai pencarian heuristik.

## Penjelasan Konsep Utama
Pencarian Heuristik menggunakan pengetahuan spesifik masalah untuk memandu pencarian ke arah simpul tujuan yang paling menjanjikan. Algoritma pencarian heuristik yang paling terkenal dan terbukti optimal adalah **Algoritma A* (A-Star)**.
Algoritma A* mengevaluasi setiap simpul `n` di dalam graf menggunakan fungsi matematika terpadu:

```
f(n) = g(n) + h(n)
```

Di mana:
- **g(n)**: Biaya sebenarnya yang telah ditempuh dari simpul awal ke simpul saat ini `n`.
- **h(n)**: Estimasi biaya heuristik (perkiraan sisa biaya) dari simpul saat ini `n` ke simpul tujuan.
- **f(n)**: Estimasi total biaya terendah untuk mencapai tujuan melalui simpul `n`.

Algoritma A* bekerja dengan cara selalu memilih simpul dengan nilai `f(n)` terkecil di dalam antrean untuk dieksplorasi lebih lanjut. 

> **Admissibility & Consistency**: Agar algoritma A* dijamin menghasilkan jalur terpendek yang benar-benar optimal, fungsi heuristik $h(n)$ wajib bersifat *admissible* (tidak pernah melebih-lebihkan biaya sebenarnya) dan *consistent* (memenuhi pertidaksamaan segitiga di mana biaya langkah transisi selalu lebih besar atau sama dengan selisih heuristik).

## Contoh Sederhana
Bayangkan kita ingin mencari rute berkendara terpendek dari kota Bandung ke Jakarta. 
- Nilai `g(n)` adalah jarak kilometer nyata yang telah kita tempuh di jalan tol dari Bandung ke kota transit tertentu `n` (misalnya Purwakarta).
- Nilai `h(n)` adalah jarak garis lurus kompas (jarak udara) dari kota transit `n` tersebut langsung ke Jakarta. Jarak garis lurus ini adalah heuristik yang *admissible* karena tidak mungkin ada jalan darat nyata yang lebih pendek daripada garis lurus kompas di udara.
Algoritma A* akan memprioritaskan mengevaluasi jalan tol yang searah menuju Jakarta daripada jalan pedesaan yang memutar menjauh.

## Poin Penting
- **Efisiensi Tinggi**: A* secara drastis memangkas jumlah simpul yang perlu diperiksa dibandingkan algoritma pencarian rute konvensional.
- **Kunci di Heuristik**: Kualitas algoritma A* sepenuhnya ditentukan oleh seberapa cerdas perancang merumuskan fungsi heuristik $h(n)$.
- **Optimalitas**: Menjamin ditemukannya solusi terbaik jika fungsi heuristik memenuhi syarat admissibility.

## Mini Rangkuman
Algoritma pencarian heuristik A* menggabungkan akumulasi biaya nyata `g(n)` dan estimasi masa depan `h(n)` guna menavigasi ruang pencarian secara efisien. Dengan menggunakan fungsi heuristik yang admissible, A* menjamin penemuan jalur optimal tercepat, menjadikannya standar emas navigasi cerdas.''',
        'orderIndex': 1,
        'createdAt': now,
      });

      final m2_3Ref = mat2Ref.collection('modules').doc('ai_fuzzy_m3');
      batch.set(m2_3Ref, {
        'title': 'Teori Logika Fuzzy & Himpunan Keanggotaan Linguistik',
        'content': r'''# Teori Logika Fuzzy & Himpunan Keanggotaan Linguistik

## Pendahuluan
Komputer konvensional bekerja menggunakan logika Boolean biner yang sangat kaku: 0 atau 1, Salah atau Benar, Mati atau Hidup. Namun, dunia nyata manusia penuh dengan ambiguitas dan ketidakpastian yang tidak dapat dipisahkan secara hitam-putih. Sebagai contoh, bagaimana komputer mendefinisikan cuaca "hangat"? Apakah suhu 29.9°C dianggap dingin sedangkan 30.0°C tiba-tiba menjadi panas? Di sinilah Logika Fuzzy (Logika Samar) yang diperkenalkan oleh Profesor Lotfi A. Zadeh pada tahun 1965 memberikan solusi matematis untuk menjembatani bahasa manusia dengan komputasi mesin.

## Penjelasan Konsep Utama
Logika Fuzzy memperluas logika klasik Boolean dengan memperkenalkan nilai kebenaran parsial kontinu. Nilai kebenaran dalam logika fuzzy berada dalam rentang kontinu **[0, 1]**, yang menggambarkan **Derajat Keanggotaan ($\mu$)** suatu objek dalam sebuah himpunan.
Perbedaan mendasar himpunan logika klasik dengan logika fuzzy:
- **Himpunan Tegas (Crisp Set)**: Anggota bersifat mutlak. Seseorang yang tingginya 170 cm dikategorikan "Tinggi" (1) sedangkan yang tingginya 169 cm dikategorikan "Tidak Tinggi" (0).
- **Himpunan Fuzzy**: Keanggotaan bersifat gradual. Tinggi 169 cm dapat memiliki derajat keanggotaan 0.75 pada himpunan "Sedang" dan 0.25 pada himpunan "Tinggi".

Derajat keanggotaan ini dirumuskan menggunakan **Fungsi Keanggotaan (Membership Function)**. Bentuk kurva fungsi keanggotaan yang paling umum digunakan adalah:
1. **Kurva Segitiga (Triangular)**: Ditentukan oleh tiga parameter titik koordinat dasar.
2. **Kurva Trapesium (Trapezoidal)**: Memiliki area datar di puncak derajat keanggotaan bernilai 1.0.
3. **Kurva Gauss (Gaussian)**: Menghasilkan transisi kurva mulus berbentuk lonceng simetris.

> **Variabel Linguistik**: Variabel yang nilainya berupa kata-kata dalam bahasa alami, bukan angka numerik kasar. Contoh: variabel `Suhu_Ruangan` memiliki nilai linguistik `Dingin`, `Normal`, dan `Panas`.

## Contoh Sederhana
Mari kita rumuskan variabel `Suhu` dengan tiga Himpunan Fuzzy menggunakan kurva segitiga:
- `Dingin`: Rentang suhu di bawah 20°C.
- `Normal`: Puncak di 24°C (derajat keanggotaan = 1.0).
- `Panas`: Rentang suhu di atas 28°C.
Jika sensor mendeteksi suhu ruangan riil sebesar 26°C, maka nilai tersebut berada di area irisan. DBMS/Sistem Fuzzy akan menghitung derajat keanggotaannya: suhu 26°C adalah `Normal` dengan derajat 0.5, sekaligus `Panas` dengan derajat 0.5.

## Poin Penting
- **Bahasa Manusia**: Logika fuzzy memungkinkan komputer memahami konsep bahasa alami manusia seperti "agak cepat", "sangat panas", atau "cukup lambat".
- **Derajat Fleksibilitas**: Menghindari perubahan keputusan yang drastis akibat perubahan kecil pada nilai input fisik sensor.
- **Matematika Himpunan**: Memiliki operasi logika terstruktur sendiri untuk irisan (AND menggunakan fungsi MIN), gabungan (OR menggunakan fungsi MAX), dan negasi (NOT menggunakan $1 - \mu$).

## Mini Rangkuman
Logika Fuzzy memetakan ambiguitas dunia nyata menjadi nilai derajat keanggotaan kontinu dalam rentang [0, 1] melalui fungsi keanggotaan kurva. Dengan memanfaatkan variabel linguistik, sistem fuzzy mampu memproses ketidakpastian informasi secara logis dan menghasilkan keputusan yang lebih luwes mendekati penalaran kognitif manusia.''',
        'orderIndex': 2,
        'youtubeUrl': 'https://www.youtube.com/watch?v=6szqrV9u9k8',
        'youtubeTitle': 'Pengenalan Logika Fuzzy | Konsep & Aplikasi',
        'youtubeChannel': 'Sekolah Koding',
        'createdAt': now,
      });

      final m2_4Ref = mat2Ref.collection('modules').doc('ai_fuzzy_m4');
      batch.set(m2_4Ref, {
        'title': 'Sistem Inferensi Fuzzy Mamdani & Defuzzifikasi Centroid',
        'content': r'''# Sistem Inferensi Fuzzy Mamdani & Defuzzifikasi Centroid

## Pendahuluan
Setelah menguasai konsep dasar logika fuzzy dan himpunan keanggotaan, langkah operasional selanjutnya adalah membangun sebuah otak pembuat keputusan, yang disebut **Sistem Inferensi Fuzzy (Fuzzy Inference System - FIS)**. Sistem ini mengambil input numerik tegas dari dunia nyata (misalnya dari sensor fisik), memprosesnya menggunakan aturan penalaran logika fuzzy, dan menghasilkan output numerik tegas baru untuk mengendalikan perangkat fisik (seperti mengatur kecepatan putaran kipas angin).

## Penjelasan Konsep Utama
Arsitektur Sistem Inferensi Fuzzy (FIS) terdiri dari tiga tahap utama yang berurutan secara disiplin:

### 1. Fuzzifikasi (Fuzzification)
Tahap pertama adalah mengambil input tegas numerik dari sensor, lalu menghitung derajat keanggotaannya pada setiap himpunan fuzzy yang relevan berdasarkan fungsi keanggotaan yang telah kita desain.

### 2. Evaluasi Aturan & Inferensi (Rule Evaluation)
Tahap kedua adalah mengevaluasi aturan-aturan kontrol linguistik berformat **JIKA - MAKA (If-Then Rules)** yang ditulis oleh pakar sistem. Contoh:
- *JIKA suhu ruangan Panas DAN kelembaban ruangan Tinggi, MAKA putaran kipas angin Cepat.*
Metode inferensi yang paling populer adalah **Metode Mamdani (Min-Max)**:
- Operator `DAN (AND)` diselesaikan dengan mengambil nilai minimum dari derajat keanggotaan input.
- Operator `ATAU (OR)` diselesaikan dengan mengambil nilai maksimum.
- Hasil dari evaluasi ini memotong kurva output fuzzy (*clipping* menggunakan nilai minimum).

### 3. Defuzzifikasi (Defuzzification)
Tahap akhir adalah menggabungkan seluruh kurva output fuzzy yang terpotong menjadi satu area geometris terpadu, lalu mengonversinya kembali menjadi satu nilai numerik tegas tunggal. Metode defuzzifikasi yang paling tepercaya dan banyak digunakan adalah **Metode Centroid (Center of Gravity)**:

```
Z* = ∫ (μ(z) * z) dz / ∫ μ(z) dz
```

Secara sederhana, rumus ini mencari titik pusat gravitasi (titik keseimbangan) dari bentuk geometri area fuzzy gabungan tersebut. Nilai koordinat $Z^*$ inilah yang dikirim ke aktuator fisik.

> **Mamdani vs Sugeno**: Metode Mamdani menghasilkan output berupa himpunan fuzzy kontinu (memerlukan integrasi defuzzifikasi Centroid), sedangkan Metode Sugeno menghasilkan output berupa konstanta matematis atau fungsi linier tegas sehingga proses komputasinya jauh lebih ringan namun kurang intuitif bagi pakar manusia.

## Contoh Sederhana
Tinjau AC Pintar. Input sensor mendeteksi suhu $30^\circ\text{C}$ (Fuzzifikasi: `Panas` dengan derajat 0.8). Aturan menyatakan: *JIKA suhu Panas, MAKA hembusan angin Kencang*. Kurva output hembusan angin `Kencang` akan dipotong pada tingkat 0.8. Setelah proses defuzzifikasi Centroid dijalankan pada area kurva terpotong tersebut, diperoleh nilai tegas output motor AC sebesar 1200 RPM, membuat ruangan cepat dingin.

## Poin Penting
- **Pakar Pengetahuan**: Aturan If-Then fuzzy dirumuskan berdasarkan intuisi empiris manusia, bukan kalkulasi kalkulus yang rumit.
- **Defuzzifikasi Centroid**: Menjamin keluaran output yang halus dan kontinu, sangat krusial agar mesin fisik tidak bergetar akibat perubahan mendadak.
- **Keterbacaan Aturan**: Sangat mudah diverifikasi dan didebug karena aturannya ditulis dalam kalimat bahasa manusia yang logis.

## Mini Rangkuman
Sistem Inferensi Fuzzy Mamdani memetakan input tegas sensor menjadi keputusan tegas aktuator melalui tiga tahap: fuzzifikasi, inferensi aturan min-max, dan defuzzifikasi Centroid. Pendekatan ini terbukti andal dalam menyusun sistem kontrol otomatis yang adaptif dan cerdas pada berbagai perangkat elektronik rumah tangga hingga industri otomotif.''',
        'orderIndex': 3,
        'createdAt': now,
      });

      // ==========================================
      // MATERIAL 3: Statistik Dasar
      // ==========================================
      final mat3Ref = _materialsCollection.doc('statistics_prob');
      batch.set(mat3Ref, {
        'title': 'Statistik Dasar & Teori Probabilitas',
        'description': 'Statistika dan Teori Probabilitas menyediakan instrumen matematis yang sangat penting untuk pengumpulan, pengorganisasian, analisis, interpretasi, dan visualisasi data numerik guna pengambilan keputusan di bawah kondisi ketidakpastian. Kurikulum akademis ini membimbing Anda dari statistika deskriptif (pemusatan & sebaran data), hukum probabilitas bersyarat Bayes, pemodelan kurva normal Gauss, hingga pengujian hipotesis formal berbasis p-value.',
        'category': 'Ilmu Komputer',
        'thumbnailColor': 'E91E63',
        'estimatedMinutes': 120, // Will be dynamically computed by provider
        'keyPoints': [
          'Statistika Deskriptif: Ringkasan data melalui rata-rata (mean), nilai tengah (median), serta standard deviasi sebaran.',
          'Teorema Bayes: Pembaruan peluang suatu hipotesis secara matematis setelah bukti atau informasi baru diperoleh.',
          'Distribusi Normal: Karakteristik kurva lonceng simetris Gauss serta penerapan aturan empiris 68-95-99.7.',
          'Uji Hipotesis: Penarikan kesimpulan populasi menggunakan tingkat signifikansi alpha dan nilai p-value secara objektif.'
        ],
        'sampleQuestions': [
          {
            'question': 'Mengapa nilai deviasi standar lebih disukai sebagai ukuran penyebaran data dibandingkan nilai varians?',
            'answer': 'Deviasi standar memiliki satuan yang sama dengan satuan data asli, sedangkan varians memiliki satuan kuadrat yang sulit diinterpretasikan secara praktis.',
            'explanation': 'Misalnya jika kita mengukur tinggi badan dalam centimeter (cm), varians akan bersatuan cm², sedangkan deviasi standar mengembalikan satuan ke cm sehingga memudahkan pemahaman sebaran tinggi badan nyata.',
          },
          {
            'question': 'Dalam pengujian hipotesis, apa perbedaan mendasar antara Error Tipe I dan Error Tipe II?',
            'answer': 'Error Tipe I terjadi ketika kita menolak Hipotesis Nol (H0) yang sebenarnya benar, sedangkan Error Tipe II terjadi ketika kita gagal menolak H0 yang sebenarnya salah.',
            'explanation': 'Tingkat peluang terjadinya Error Tipe I dikendalikan langsung oleh peneliti melalui penetapan tingkat signifikansi alpha (biasanya diset pada batas 0.05 atau 5%).',
          }
        ],
        'createdAt': now,
      });

      // Modules for Material 3
      final m1_3Ref_mod = mat3Ref.collection('modules').doc('statistics_prob_m1');
      batch.set(m1_3Ref_mod, {
        'title': 'Statistika Deskriptif: Pemusatan & Sebaran Data',
        'content': r'''# Statistika Deskriptif: Pemusatan & Sebaran Data

## Pendahuluan
Di era big data saat ini, kita sering kali dihadapkan pada tumpukan angka mentah yang sangat besar. Membaca ribuan angka tersebut secara individual tidak akan memberikan arti apa pun. Statistika Deskriptif adalah cabang ilmu yang berfokus pada penyediaan metode ilmiah untuk menyusun, meringkas, dan menyajikan karakteristik penting dari suatu kumpulan data secara informatif. Dengan ringkasan deskriptif, pengambil keputusan dapat memahami gambaran umum populasi secara cepat dan akurat.

## Penjelasan Konsep Utama
Ringkasan karakteristik data secara umum dibagi menjadi dua pilar pengukuran utama:

### 1. Ukuran Pemusatan Data (Central Tendency)
Ukuran ini mencari satu nilai representatif yang menunjukkan pusat dari kumpulan data:
- **Mean (Rata-rata)**: Diperoleh dengan menjumlahkan seluruh nilai data lalu dibagi dengan total jumlah sampel. Kelemahannya adalah sangat sensitif terhadap pencilan (*outliers*) ekstrem.
- **Median (Nilai Tengah)**: Nilai tengah dari data yang telah diurutkan dari terkecil ke terbesar. Median sangat tahan (*robust*) terhadap pencilan data.
- **Modus**: Nilai atau kategori yang memiliki frekuensi kemunculan paling tinggi dalam kumpulan data.

### 2. Ukuran Penyebaran Data (Dispersion)
Ukuran ini menggambarkan seberapa jauh data-data individual menyebar dari nilai pusatnya:
- **Rentang (Range)**: Selisih antara nilai maksimum dengan nilai minimum. Ukuran ini sangat kasar dan tidak menggambarkan variasi data di tengah.
- **Varians (Variance)**: Rata-rata dari kuadrat selisih setiap titik data terhadap nilai rata-ratanya (mean).
- **Deviasi Standar (Standard Deviation)**: Akar kuadrat dari varians. Deviasi standar adalah ukuran penyebaran yang paling penting karena mengembalikan satuan ukuran data ke satuan aslinya.

> **Pencilan (Outlier)**: Titik data yang nilainya menyimpang sangat jauh dari mayoritas data lainnya. Keberadaan pencilan dapat mendistorsi rata-rata secara signifikan sehingga median sering kali menjadi pilihan pusat data yang lebih representatif untuk menggambarkan kondisi nyata.

## Contoh Sederhana
Mari kita tinjau data pendapatan bulanan 5 warga di sebuah gang: Rp2 juta, Rp2 juta, Rp3 juta, Rp3 juta, dan Rp100 juta (pengusaha sukses).
- **Mean**: (2 + 2 + 3 + 3 + 100) / 5 = Rp22 juta. Nilai ini tidak realistis karena mayoritas warga berpendapatan sekitar Rp2-3 juta.
- **Median**: Urutan data: 2, 2, 3, 3, 100. Nilai tengahnya adalah Rp3 juta. Angka Rp3 juta ini jauh lebih adil dan representatif dalam menggambarkan kondisi ekonomi mayoritas warga di gang tersebut.

## Poin Penting
- **Mean vs Median**: Pilihlah median jika data Anda tidak simetris atau memiliki pencilan ekstrem.
- **Deviasi Standar Kecil**: Menunjukkan bahwa titik data berkumpul sangat dekat dengan rata-rata, menandakan data bersifat homogen.
- **Deviasi Standar Besar**: Menunjukkan data menyebar luas, menandakan data bersifat heterogen.

## Mini Rangkuman
Statistika Deskriptif merangkum kompleksitas data melalui ukuran pemusatan (mean, median, modus) dan sebaran (varians, deviasi standar). Pemilihan indikator statistik yang tepat sangat vital agar kesimpulan ringkasan data yang disajikan tidak bias dan mencerminkan kebenaran populasi.''',
        'orderIndex': 0,
        'youtubeUrl': 'https://www.youtube.com/watch?v=el7Ezn9PpWU',
        'youtubeTitle': 'Statistika 01 | Pengantar Belajar Statistika Dasar',
        'youtubeChannel': 'Indonesia Belajar',
        'createdAt': now,
      });

      final m2_3Ref_mod = mat3Ref.collection('modules').doc('statistics_prob_m2');
      batch.set(m2_3Ref_mod, {
        'title': 'Teori Peluang & Pembuktian Teorema Bayes',
        'content': r'''# Teori Peluang & Pembuktian Teorema Bayes

## Pendahuluan
Probabilitas atau teori peluang adalah bahasa matematika yang digunakan untuk mengukur tingkat ketidakpastian dari suatu peristiwa. Di dunia nyata, kita hampir tidak pernah memiliki informasi yang 100% sempurna sebelum mengambil keputusan. Seorang dokter harus mendiagnosis penyakit berdasarkan gejala yang tidak pasti, dan filter email harus menyaring pesan spam tanpa mengetahui maksud pengirim sesungguhnya. Teorema Bayes yang dirumuskan oleh Thomas Bayes pada abad ke-18 memberikan kerangka logis untuk memperbarui estimasi peluang kita setelah mendapatkan bukti baru.

## Penjelasan Konsep Utama
Peluang bersyarat mengukur probabilitas terjadinya peristiwa $A$ dengan syarat peristiwa $B$ telah terjadi terlebih dahulu. Notasi matematika untuk peluang bersyarat adalah $P(A|B)$, yang didefinisikan sebagai:

```
P(A|B) = P(A ∩ B) / P(B)
```

Melalui manipulasi aljabar peluang bersyarat ini, kita mendapatkan **Teorema Bayes** yang legendaris:

```
P(A|B) = [P(B|A) * P(A)] / P(B)
```

Di mana komponen-komponennya didefinisikan sebagai berikut:
- **P(A|B)**: *Posterior Probability*. Peluang hipotesis $A$ benar *setelah* bukti $B$ diamati.
- **P(B|A)**: *Likelihood*. Peluang bukti $B$ muncul *jika* hipotesis $A$ benar.
- **P(A)**: *Prior Probability*. Kepercayaan awal kita terhadap hipotesis $A$ *sebelum* ada bukti baru.
- **P(B)**: *Marginal Probability*. Peluang total munculnya bukti $B$ di bawah seluruh skenario yang mungkin terjadi ($P(B) = P(B|A)P(A) + P(B|\neg A)P(\neg A)$).

> **Pembaruan Bayes**: Proses pembelajaran berulang di mana posterior hari ini akan menjadi prior untuk hari esok saat ada bukti baru yang masuk. Ini adalah dasar utama teknologi *machine learning* klasifikasi Naive Bayes.

## Contoh Sederhana
Tinjau tes medis pendeteksi penyakit langka yang diderita oleh 1% populasi ($P(\text{Sakit}) = 0.01$). Tes ini memiliki akurasi (sensitivitas) 90% ($P(\text{Positif}|\text{Sakit}) = 0.90$), namun memiliki tingkat *false positive* 5% ($P(\text{Positif}|\text{Sehat}) = 0.05$).
Jika seorang pasien melakukan tes dan hasilnya **Positif**, berapakah peluang nyata ia benar-benar sakit?
Mari kita hitung menggunakan Teorema Bayes:
- Prior $P(\text{Sakit}) = 0.01$
- Likelihood $P(\text{Positif}|\text{Sakit}) = 0.90$
- Marginal $P(\text{Positif}) = (0.90 \times 0.01) + (0.05 \times 0.99) = 0.009 + 0.0495 = 0.0585$
- Posterior $P(\text{Sakit}|\text{Positif}) = (0.90 \times 0.01) / 0.0585 = 0.1538$ (hanya **15.38%**!).
Meskipun tes mendeteksi positif dengan akurasi tinggi, peluang nyata pasien sakit ternyata cukup kecil karena penyakit tersebut sangat langka di populasi.

## Poin Penting
- **Melawan Intuisi**: Teorema Bayes sering kali menghasilkan kesimpulan yang mengejutkan karena memaksa kita mempertimbangkan seberapa langka prior awal.
- **Deteksi Spam**: Klasifikasi Naive Bayes menyaring email dengan menghitung peluang suatu email adalah spam setelah mendeteksi kata-kata tertentu seperti "hadiah" atau "gratis".
- **Pembaruan Objektif**: Memberikan metode ilmiah bagi peneliti untuk memperbarui opini subjektif berdasarkan data empiris yang objektif.

## Mini Rangkuman
Teorema Bayes adalah hukum probabilitas yang sangat kuat untuk memperbarui estimasi peluang prior berdasarkan bukti empiris baru untuk menghasilkan peluang posterior yang akurat. Konsep ini mendominasi teori pengambilan keputusan modern, kedokteran, hingga pengembangan sistem kecerdasan buatan.''',
        'orderIndex': 1,
        'youtubeUrl': 'https://www.youtube.com/watch?v=kKMg-iOD7bQ',
        'youtubeTitle': 'Konsep dan Contoh Kasus Teorema Bayes',
        'youtubeChannel': 'Statistika Indonesia',
        'createdAt': now,
      });

      final m3_3Ref_mod = mat3Ref.collection('modules').doc('statistics_prob_m3');
      batch.set(m3_3Ref_mod, {
        'title': 'Distribusi Normal (Gauss) & Aturan Empiris 68-95-99.7',
        'content': r'''# Distribusi Normal (Gauss) & Aturan Empiris 68-95-99.7

## Pendahuluan
Di alam semesta ini, jika kita mengukur karakteristik fisik dari sekelompok besar populasi acak—seperti tinggi badan manusia, berat lahir bayi, nilai ujian siswa, atau bahkan kesalahan pengukuran instrumen pabrik—kita akan menemukan pola penyebaran data yang sangat mirip. Pola ini membentuk kurva simetris yang menyerupai lonceng di mana mayoritas data menumpuk di bagian tengah dan semakin melandai ke arah ujung kiri dan kanan. Pola penyebaran kontinu yang sangat fenomenal ini disebut sebagai Distribusi Normal atau Distribusi Gauss.

## Penjelasan Konsep Utama
Distribusi Normal adalah distribusi probabilitas kontinu yang didefinisikan oleh dua parameter statistik utama: Rata-rata ($\mu$) yang menentukan lokasi pusat kurva, dan Deviasi Standar ($\sigma$) yang menentukan kelebaran kurva.
Karakteristik utama Distribusi Normal meliputi:
- **Simetris Sempurna**: Kurva di sisi kiri rata-rata adalah cerminan dari sisi kanan.
- **Pusat Terpadu**: Nilai Mean, Median, dan Modus bernilai sama dan terletak tepat di titik puncak kurva.
- **Asimtotik**: Ujung kurva mendekati sumbu horizontal namun secara teoretis tidak akan pernah menyentuhnya.

Salah satu sifat praktis yang paling menakjubkan dari Distribusi Normal adalah kepatuhannya terhadap **Aturan Empiris (68-95-99.7 Rule)**:
1. Sekitar **68.2%** dari seluruh data dijamin berada dalam rentang ±1 Deviasi Standar ($\sigma$) dari rata-rata ($\mu$).
2. Sekitar **95.4%** data berada dalam rentang ±2 Deviasi Standar ($2\sigma$) dari rata-rata.
3. Sekitar **99.7%** data berada dalam rentang ±3 Deviasi Standar ($3\sigma$) dari rata-rata (hampir seluruh populasi).

> **Standardisasi Z-Score**: Proses mengonversi variabel acak normal umum $X$ menjadi Distribusi Normal Standar $Z$ (dengan rata-rata 0 dan deviasi standar 1) menggunakan rumus $Z = (X - \mu) / \sigma$. Ini memudahkan kita membaca tabel probabilitas tanpa perlu menghitung integrasi kalkulus yang rumit.

## Contoh Sederhana
Misalkan tinggi badan mahasiswa laki-laki di sebuah universitas terdistribusi secara normal dengan rata-rata $\mu = 170\text{ cm}$ dan deviasi standar $\sigma = 5\text{ cm}$.
Berdasarkan Aturan Empiris:
- Sekitar 68% mahasiswa memiliki tinggi di rentang $170 \pm 5\text{ cm}$ (yaitu antara 165 cm hingga 175 cm).
- Sekitar 95% mahasiswa memiliki tinggi di rentang $170 \pm 10\text{ cm}$ (antara 160 cm hingga 180 cm).
- Kurang dari 0.3% mahasiswa yang memiliki tinggi di luar rentang 155 cm hingga 185 cm.

## Poin Penting
- **Central Limit Theorem**: Teorema yang menyatakan bahwa jika sampel berukuran besar diambil dari populasi mana pun, distribusi rata-rata sampelnya akan mendekati distribusi normal.
- **Dasar Six Sigma**: Metodologi kontrol kualitas industri yang menargetkan cacat produksi kurang dari 3.4 per satu juta produk (menjaga kualitas di batas ±6 deviasi standar).
- **Kemudahan Prediksi**: Memungkinkan peneliti memprediksi persentase probabilitas suatu kejadian dengan sangat akurat hanya dengan mengetahui nilai mean dan standar deviasi data.

## Mini Rangkuman
Distribusi Normal adalah distribusi kontinu simetris berbentuk lonceng yang menguasai penyebaran data di alam. Melalui Aturan Empiris 68-95-99.7 dan konversi Z-Score, kita dapat melakukan estimasi probabilitas populasi secara terstandar dan cepat, menjadikannya pilar terpenting dalam analisis statistika inferensial.''',
        'orderIndex': 2,
        'createdAt': now,
      });

      final m3_4Ref_mod = mat3Ref.collection('modules').doc('statistics_prob_m4');
      batch.set(m3_4Ref_mod, {
        'title': 'Metodologi Uji Hipotesis & Signifikansi P-Value',
        'content': r'''# Metodologi Uji Hipotesis & Signifikansi P-Value

## Pendahuluan
Bagaimana seorang ilmuwan farmasi membuktikan secara objektif bahwa obat baru ciptaannya benar-benar efektif menurunkan tekanan darah, dan bukan sekadar kebetulan belaka? Dalam dunia sains, kita tidak boleh mengambil kesimpulan subjektif hanya berdasarkan pengamatan visual sepintas. Kita memerlukan prosedur matematis yang terstruktur untuk menguji klaim penelitian kita terhadap data sampel secara ketat. Prosedur standar ilmiah ini disebut sebagai Pengujian Hipotesis Parametrik.

## Penjelasan Konsep Utama
Uji Hipotesis adalah metode pengambilan keputusan statistika inferensial untuk mengevaluasi apakah bukti dari sampel cukup kuat untuk menolak atau menerima suatu asumsi mengenai populasi. Langkah perancangannya meliputi:

### 1. Merumuskan Hipotesis Dua Arah
- **Hipotesis Nol (H0)**: Pernyataan status quo yang berasumsi tidak ada perbedaan nyata, tidak ada efek, atau tidak ada hubungan (misal: obat baru *tidak* menurunkan tekanan darah). H0 adalah hipotesis yang selalu diuji untuk ditolak.
- **Hipotesis Alternatif (H1 / Ha)**: Pernyataan klaim penelitian yang ingin kita buktikan kebenarannya (misal: obat baru *berhasil* menurunkan tekanan darah secara nyata).

### 2. Menetapkan Batas Alpha ($\alpha$) & Menghitung P-Value
- **Tingkat Signifikansi ($\alpha$)**: Batas toleransi peluang kita menolak H0 yang sebenarnya benar (biasanya diset pada $\alpha = 0.05$ atau 5%).
- **P-Value (Probability Value)**: Ukuran kekuatan bukti sampel untuk menentang H0. Secara formal, P-Value adalah probabilitas mendapatkan data sampel seekstrem atau lebih ekstrem dari yang diamati, jika diasumsikan Hipotesis Nol (H0) benar.

> **Aturan Keputusan P-Value**:
> - Jika **P-Value < $\alpha$ (p < 0.05)**: Bukti sampel sangat kuat untuk menentang H0. Kita **Menolak H0** dan menerima H1 (hasilnya signifikan secara statistik).
> - Jika **P-Value $\ge$ $\alpha$ (p $\ge$ 0.05)**: Bukti sampel lemah. Kita **Gagal Menolak H0** (tidak cukup bukti untuk mendukung klaim baru).

## Contoh Sederhana
Sebuah pabrik lampu mengklaim masa pakai produknya adalah 10.000 jam. Lembaga konsumen menguji sampel 50 lampu dan menemukan rata-rata masa pakainya hanya 9.800 jam. Lembaga tersebut menghitung uji statistik t-test dan menghasilkan nilai **P-Value = 0.01**.
Karena P-Value (0.01) jauh lebih kecil dari tingkat signifikansi alpha (0.05), kita memiliki bukti ilmiah yang sangat kuat untuk **Menolak H0**. Kita menyimpulkan secara sah bahwa masa pakai lampu tersebut memang di bawah klaim pabrik. Peluang bahwa selisih 200 jam ini terjadi karena kebetulan acak hanyalah 1%.

## Poin Penting
- **P-Value Bukan Peluang H0 Benar**: P-Value adalah peluang melihat data sampel jika H0 diasumsikan benar. Ini adalah kesalahan penafsiran umum yang wajib dihindari.
- **Uji Dua Arah vs Satu Arah**: Menentukan apakah kita ingin mendeteksi perbedaan di kedua ujung distribusi atau hanya fokus di satu arah spesifik (lebih besar/lebih kecil).
- **Signifikansi Praktis**: Hasil yang signifikan secara statistik (p < 0.05) belum tentu penting secara praktis di dunia nyata. Peneliti harus tetap menilai relevansi bisnis/klinisnya.

## Mini Rangkuman
Metodologi Uji Hipotesis merumuskan klaim ilmiah ke dalam hipotesis nol (H0) dan hipotesis alternatif (H1). Dengan membandingkan nilai probabilitas P-Value terhadap batas signifikansi alpha (0.05), peneliti dapat mengambil keputusan yang objektif, tepercaya, dan terstandar secara ilmiah di seluruh dunia.''',
        'orderIndex': 3,
        'createdAt': now,
      });

      // ==========================================
      // MATERIAL 4: Bahasa Inggris Akademik
      // ==========================================
      final mat4Ref = _materialsCollection.doc('academic_english');
      batch.set(mat4Ref, {
        'title': 'Bahasa Inggris Akademik',
        'description': 'Modul Bahasa Inggris Akademik dirancang khusus untuk membantu mahasiswa menguasai keterampilan membaca kritis, menyusun esai akademis, memahami struktur tata bahasa formal, serta menyajikan presentasi ilmiah secara meyakinkan. Fokus pembelajaran adalah perluasan kosakata formal (Academic Word List) dan teknik sitasi karya ilmiah.',
        'category': 'Bahasa',
        'thumbnailColor': '2E7D32',
        'estimatedMinutes': 180, // Will be dynamically computed by provider
        'keyPoints': [
          'Membaca Kritis (Critical Reading): Teknik analisis teks, membedakan fakta dan opini, serta menyimpulkan argumen implisit.',
          'Struktur Esai Akademis: Menyusun Thesis Statement, Topic Sentence, Body Paragraphs, dan Kesimpulan yang logis.',
          'Kosakata Formal: Penggunaan Academic Word List (AWL) untuk menghindari bahasa sehari-hari dalam penulisan ilmiah.',
          'Teknik Sitasi & Plagiarisme: Memahami gaya sitasi ilmiah (seperti APA, MLA) untuk menjaga integritas akademik.'
        ],
        'sampleQuestions': [
          {
            'question': 'Apa perbedaan utama antara paraphrasing dengan summarizing dalam penulisan esai akademik?',
            'answer': 'Paraphrasing menuliskan kembali ide spesifik penulis lain dengan kata-kata sendiri tanpa mengubah panjang teks asli, sedangkan summarizing hanya merangkum poin-poin utama secara jauh lebih ringkas.',
            'explanation': 'Kedua teknik ini wajib menyertakan sitasi sumber asli untuk menjaga integritas akademik dan menghindari tindakan plagiarisme.',
          }
        ],
        'createdAt': now,
      });

      // Modules for Material 4
      final m4_1Ref_mod = mat4Ref.collection('modules').doc('academic_english_m1');
      batch.set(m4_1Ref_mod, {
        'title': 'Strategi Membaca Kritis & Evaluasi Jurnal Ilmiah (SQ3R)',
        'content': r'''# Strategi Membaca Kritis & Evaluasi Jurnal Ilmiah (SQ3R)

## Pendahuluan
Memasuki dunia perguruan tinggi, mahasiswa dituntut untuk membaca ratusan jurnal ilmiah dan artikel akademik. Membaca literatur ilmiah sangat berbeda dengan membaca novel atau berita online. Teks akademik sering kali padat dengan kosakata formal, argumen teoretis yang rumit, dan data metodologi yang kompleks. Membaca pasif baris demi baris hanya akan membuang waktu tanpa pemahaman yang mendalam. Mahasiswa membutuhkan metode membaca aktif yang terstruktur untuk menyerap, menganalisis, dan mengevaluasi karya ilmiah secara kritis.

## Penjelasan Konsep Utama
Membaca kritis (*Critical Reading*) adalah proses membaca aktif untuk mengevaluasi keabsahan argumen, mendeteksi bias penulis, menganalisis metodologi penelitian, serta memikirkan implikasi dari temuan ilmiah tersebut terhadap studi kita sendiri. 
Salah satu metode membaca aktif yang paling tepercaya dan diajarkan di universitas terkemuka dunia adalah **Metode SQ3R**:
1. **S (Survey)**: Melakukan tinjauan cepat terhadap struktur jurnal. Baca judul, abstrak, subbab, dan kesimpulan untuk mendapatkan gambaran besar peta pembahasan dalam waktu 2 menit.
2. **Q (Question)**: Mengubah judul subbab menjadi pertanyaan kritis sebelum mulai membaca (misal: "Apa metodologi yang digunakan?" atau "Mengapa teori ini dipilih?"). Ini menjaga pikiran tetap fokus mencari jawaban.
3. **R1 (Read)**: Membaca teks secara aktif dengan fokus mencari jawaban atas pertanyaan yang telah dirumuskan pada tahap Question. Tandai kalimat penting dan buat catatan kaki kecil.
4. **R2 (Recite)**: Mengucapkan kembali atau menuliskan poin-poin penting menggunakan kata-kata sendiri setelah selesai membaca satu subbab tanpa melihat teks. Ini sangat efektif memperkuat memori kerja otak.
5. **R3 (Review)**: Meninjau kembali seluruh catatan dan merangkum hubungan logis antar subbab untuk mengonsolidasikan pemahaman secara menyeluruh.

> **Fakta vs Opini Ilmiah**: Mahasiswa kritis harus mampu membedakan fakta empiris (data statistik objektif) dari opini ilmiah (interpretasi teoretis penulis atas data tersebut yang masih dapat didiskusikan kebenarannya).

## Contoh Sederhana
Saat membaca jurnal tentang dampak media sosial terhadap kecemasan remaja:
- **Survey**: Baca abstrak dan temukan kesimpulan bahwa ada korelasi positif 30%.
- **Question**: Ajukan pertanyaan: "Bagaimana peneliti mengukur tingkat kecemasan tersebut?"
- **Read**: Baca bagian metodologi dan temukan bahwa mereka menggunakan kuesioner skala psikologi berstandar internasional.
- **Recite**: Tulis di buku catatan: "Penelitian ini menggunakan survei kuantitatif pada 500 responden remaja."
- **Review**: Hubungkan temuan ini dengan tugas kuliah Anda mengenai kesehatan mental remaja.

## Poin Penting
- **Membaca Aktif**: Selalu bawa pertanyaan di kepala Anda sebelum mulai membaca baris pertama jurnal ilmiah.
- **Analisis Kritis**: Jangan langsung mempercayai kesimpulan penulis; periksalah apakah data sampel dalam metodologi mereka cukup representatif.
- **Kosakata AWL**: Perluas pemahaman kosakata formal dari *Academic Word List* (AWL) untuk mempercepat proses pemahaman teks.

## Mini Rangkuman
Strategi membaca kritis melalui metode SQ3R mengubah proses membaca pasif menjadi pencarian aktif yang kritis dan efisien. Dengan membiasakan diri melakukan survey, merumuskan pertanyaan, membaca aktif, mengucapkan ulang, dan meninjau kembali, mahasiswa dapat menguasai literatur ilmiah tingkat tinggi secara mendalam.''',
        'orderIndex': 0,
        'createdAt': now,
      });

      final m4_2Ref_mod = mat4Ref.collection('modules').doc('academic_english_m2');
      batch.set(m4_2Ref_mod, {
        'title': 'Merumuskan Thesis Statement yang Kuat & Terstruktur',
        'content': r'''# Merumuskan Thesis Statement yang Kuat & Terstruktur

## Pendahuluan
Salah satu kesulitan terbesar yang dihadapi mahasiswa saat menulis esai akademik atau tugas akhir adalah tulisan yang melebar tanpa arah yang jelas. Esai akademik yang baik bukanlah kumpulan ringkasan informasi acak dari internet. Esai akademik adalah sebuah argumen logis terpadu yang ditulis untuk membuktikan satu poin klaim sentral. Poin klaim sentral yang mengendalikan seluruh arah esai ini disebut sebagai *Thesis Statement* (Pernyataan Tesis). Tanpa *Thesis Statement* yang kuat di awal, esai Anda akan kehilangan fokus dan membingungkan pembaca.

## Penjelasan Konsep Utama
*Thesis Statement* adalah kalimat tunggal (atau terkadang dua kalimat berdampingan) yang diletakkan di akhir paragraf pendahuluan (*Introduction*). Kalimat ini memuat argumen utama atau posisi penulis terhadap suatu topik secara eksplisit, sekaligus memberikan peta jalan (*roadmap*) bagi pembaca mengenai poin-poin yang akan dibahas di paragraf-paragraf isi esai.
Kriteria dari sebuah *Thesis Statement* yang kuat meliputi:
1. **Dapat Diperdebatkan (Arguable)**: Harus berupa klaim opini ilmiah atau posisi akademis yang memerlukan pembuktian data, bukan berupa fakta umum yang sudah disetujui semua orang.
2. **Spesifik & Terfokus (Specific)**: Menghindari pernyataan yang terlalu umum atau luas sehingga sulit dibahas secara mendalam dalam batasan halaman esai.
3. **Membatasi Cakupan (Scoping)**: Memberikan isyarat batasan bukti-bukti utama apa saja yang akan dipaparkan penulis untuk mendukung klaimnya.

> **Peta Jalan Tulisan**: *Thesis Statement* adalah kompas Anda. Setiap kalimat di paragraf isi esai harus berkontribusi langsung atau tidak langsung untuk mendukung keabsahan *Thesis Statement* yang telah Anda deklarasikan di awal.

## Contoh Sederhana
Mari bandingkan perumusan kalimat tesis pada topik pendidikan digital:
- *Formulasi Lemah*: "Pendidikan online memiliki beberapa kelebihan dan kekurangan bagi mahasiswa." (Ini adalah kalimat deskriptif umum yang tidak memuat posisi argumen penulis. Semua orang sudah tahu hal ini).
- *Formulasi Kuat*: "Meskipun memberikan fleksibilitas waktu, integrasi penuh pendidikan online di perguruan tinggi harus dibatasi karena dapat menurunkan keterampilan kolaborasi sosial mahasiswa, meningkatkan isolasi mental, serta memperlebar kesenjangan akses teknologi antar daerah."
Kalimat kedua sangat kuat karena secara eksplisit menyatakan posisi penulis (membatasi pendidikan online) dan memberikan 3 argumen pendukung yang spesifik untuk dibahas di paragraf isi.

## Poin Penting
- **Letak Strategis**: Selalu letakkan kalimat tesis di akhir paragraf pendahuluan setelah Anda memaparkan latar belakang topik secara umum (*hook & context*).
- **Panduan Menulis**: Jika Anda bingung apa yang harus ditulis di paragraf berikutnya, baca kembali *Thesis Statement* Anda untuk menemukan petunjuk urutan topik.
- **Konsistensi Argumen**: Pastikan kesimpulan esai di akhir paragraf menegaskan kembali kekuatan kalimat tesis ini setelah memaparkan bukti-bukti nyata.

## Mini Rangkuman
*Thesis Statement* adalah pilar pengendali fokus dan kekuatan esai akademik. Dengan merumuskan kalimat tesis yang argumantatif, spesifik, dan memuat batas argumen pendukung secara jelas, mahasiswa dapat menyusun tulisan ilmiah yang terstruktur, logis, dan persuasif bagi pembaca akademis.''',
        'orderIndex': 1,
        'youtubeUrl': 'https://www.youtube.com/watch?v=k2_2H3qT9q0',
        'youtubeTitle': 'Belajar Bahasa Inggris Grammar Dasar',
        'youtubeChannel': 'Kampung Inggris LC',
        'createdAt': now,
      });

      final m4_3Ref_mod = mat4Ref.collection('modules').doc('academic_english_m3');
      batch.set(m4_3Ref_mod, {
        'title': 'Struktur Paragraf Akademik Terintegrasi (Metode PEEL)',
        'content': r'''# Struktur Paragraf Akademik Terintegrasi (Metode PEEL)

## Pendahuluan
Banyak mahasiswa menyusun paragraf esai akademik secara acak; menuliskan apa pun yang terlintas di pikiran tanpa struktur logis yang jelas. Akibatnya, hubungan antar kalimat menjadi terputus-putus, argumen menjadi dangkal, dan pembaca kesulitan menangkap esensi tulisan. Dalam penulisan akademis standar internasional, sebuah paragraf isi (*body paragraph*) harus berfokus pada satu ide pokok tunggal dan disusun secara deduktif. Untuk membantu mahasiswa menguasai struktur logis ini, para akademisi merumuskan metode penulisan paragraf yang sangat populer, yaitu **Metode PEEL**.

## Penjelasan Konsep Utama
Metode PEEL membagi struktur pembentukan sebuah paragraf isi akademis menjadi empat langkah berurutan yang saling mendukung:

### 1. P - Point (Kalimat Topik)
Langkah pertama adalah menuliskan **Point**, yaitu satu kalimat utama (*Topic Sentence*) di awal paragraf yang secara tegas menyatakan klaim argumen yang akan dibahas dalam paragraf tersebut. Kalimat ini harus berkorelasi langsung dengan *Thesis Statement* utama esai Anda.

### 2. E - Explanation (Penjelasan Logis)
Langkah kedua adalah memberikan **Explanation**. Di sini Anda memperluas Point Anda dengan memberikan penjelasan teoretis yang lebih mendalam, penalaran logis, serta elaborasi konsep agar pembaca memahami makna di balik klaim awal Anda.

### 3. E - Evidence (Bukti Ilmiah & Sitasi)
Langkah ketiga adalah menyajikan **Evidence**. Argumen akademik akan runtuh jika tidak didukung oleh data empiris nyata. Sajikan bukti pendukung yang kredibel seperti data statistik, hasil studi penelitian jurnal, kutipan pakar, atau fakta tepercaya lengkap dengan sitasi sumber pustakanya.

### 4. L - Link (Kalimat Penghubung)
Langkah terakhir adalah menuliskan **Link**. Kalimat penutup paragraf ini mengaitkan kembali seluruh bukti dan penjelasan yang baru saja Anda paparkan dengan argumen utama esai (*Thesis Statement*), atau berfungsi sebagai transisi logis yang mulus menuju paragraf isi berikutnya.

> **Kepadatan Paragraf**: Paragraf akademis yang ideal menggunakan metode PEEL biasanya memiliki panjang sekitar 150 hingga 250 kata, menjamin kedalaman analisis dan keterbacaan yang optimal.

## Contoh Sederhana
Mari kita tinjau contoh paragraf PEEL bertopik isolasi sosial akibat kuliah online:
- **Point**: *Kuliah online yang berkepanjangan dapat menghambat perkembangan keterampilan interpersonal mahasiswa.*
- **Explanation**: *Tanpa interaksi tatap muka harian di kelas fisik, mahasiswa kehilangan kesempatan emas untuk melatih komunikasi non-verbal, bernegosiasi secara langsung, serta berempati secara spontan dalam diskusi kelompok.*
- **Evidence**: *Sebuah studi longitudinal oleh Smith dkk. (2021) menunjukkan bahwa 62% mahasiswa yang menjalani kuliah daring penuh melaporkan penurunan kepercayaan diri saat berbicara di depan publik setelah satu semester.*
- **Link**: *Oleh karena itu, keterbatasan interaksi sosial ini membuktikan bahwa integrasi pendidikan online harus dibatasi untuk melindungi pertumbuhan sosial mahasiswa.*

## Poin Penting
- **Satu Paragraf, Satu Ide**: Jangan pernah mencampuradukkan dua ide pokok yang berbeda di dalam satu paragraf tunggal. Pecahlah menjadi paragraf baru.
- **Runtun & Logis**: Selalu patuhi urutan P -> E -> E -> L demi menjaga alur penalaran pembaca agar tidak melompat-lompat.
- **Sitasi Kredibel**: Pastikan bukti pada bagian Evidence bersumber dari jurnal bereputasi, bukan dari blog opini pribadi.

## Mini Rangkuman
Metode PEEL menyediakan panduan praktis yang luar biasa bagi mahasiswa untuk merancang paragraf isi esai akademik secara kohesif, mendalam, dan ilmiah. Dengan memadukan Point yang tegas, Explanation yang logis, Evidence berbasis data kredibel, serta Link penghubung argumen, esai akademik Anda akan terasa sangat solid dan meyakinkan.''',
        'orderIndex': 2,
        'createdAt': now,
      });

      final m4_4Ref_mod = mat4Ref.collection('modules').doc('academic_english_m4');
      batch.set(m4_4Ref_mod, {
        'title': 'Etika Sitasi Ilmiah APA Edisi ke-7 & Pencegahan Plagiarisme',
        'content': r'''# Etika Sitasi Ilmiah APA Edisi ke-7 & Pencegahan Plagiarisme

## Pendahuluan
Dunia akademik dibangun di atas fondasi kejujuran dan saling menghargai kontribusi intelektual antar sesama peneliti. Saat menulis karya ilmiah, kita pasti menggunakan ide, teori, atau data dari penulis lain untuk memperkuat argumen kita sendiri. Menggunakan karya orang lain tanpa memberikan kredit atau pengakuan yang sah adalah pelanggaran hukum moral dan akademik yang sangat berat, yang dikenal sebagai **Plagiarisme**. Plagiarisme dapat mengakibatkan kegagalan studi mahasiswa, pencabutan gelar akademis, hingga sanksi hukum formal. Oleh karena itu, menguasai teknik sitasi ilmiah adalah keterampilan wajib mutlak bagi setiap akademisi.

## Penjelasan Konsep Utama
Sitasi adalah cara formal bagi kita untuk memberitahu pembaca bahwa materi tertentu dalam tulisan kita bersumber dari karya orang lain. Gaya sitasi yang paling banyak digunakan di seluruh dunia untuk bidang ilmu komputer, psikologi, dan sosial adalah **APA (American Psychological Association) 7th Edition**.
Sistem sitasi APA mewajibkan penulisan referensi dalam dua tempat yang berpasangan secara disiplin:

### 1. Sitasi di Dalam Teks (In-Text Citation)
Dituliskan langsung di dalam paragraf tempat ide tersebut dikutip. Format dasarnya adalah nama belakang penulis dan tahun terbit:
- **Kutipan Tidak Langsung (Paraphrase)**: Menuliskan kembali ide orang lain dengan bahasa kita sendiri. Ini adalah metode yang sangat direkomendasikan. Contoh: *Menurut Rahma (2020), basis data relasional menjamin keunikan data.* atau *Basis data relasional menjamin keunikan data (Rahma, 2020).*
- **Kutipan Langsung (Direct Quote)**: Menyalin persis kata-kata asli penulis. Wajib menggunakan tanda kutip ("...") dan mencantumkan nomor halaman: Contoh: *Rahma (2020) menegaskan bahwa "kunci utama wajib unik" (p. 15).*

### 2. Daftar Pustaka (Reference List)
Daftar lengkap seluruh sumber referensi yang diletakkan di halaman akhir dokumen secara alfabetis. Format dasar penulisan daftar pustaka APA 7th Edition untuk buku:
```
NamaBelakang, Inisial. (Tahun). Judul Buku Bercetak Miring. Nama Penerbit.
```
Contoh:
```
Zadeh, L. A. (1965). Fuzzy Sets and Systems. Academic Press.
```

> **Teknik Paraphrasing**: Cara terbaik untuk menghindari plagiarisme. Lakukan pembacaan secara mendalam hingga paham, tutup teks asli, lalu tuliskan kembali konsep tersebut menggunakan gaya bahasa dan struktur kalimat Anda sendiri tanpa mengubah makna ilmiah aslinya.

## Contoh Sederhana
Misalkan Anda membaca kalimat asli dari buku karangan Budi Setiawan tahun 2019: *"Database merupakan jantung utama dari aplikasi android karena kecepatan load aplikasi ditentukan oleh efisiensi kueri."*
- *Tindakan Plagiarisme*: Anda menyalin kalimat tersebut bulat-bulat ke esai Anda tanpa tanda kutip dan tanpa menyebutkan nama Budi.
- *Sitasi Paraphrase yang Benar*: *Efisiensi penulisan kueri pada database sangat menentukan performa kecepatan pemuatan data pada aplikasi perangkat bergerak (Setiawan, 2019).*
Di sini Anda mengubah kata-kata secara kreatif namun tetap menghargai Setiawan sebagai pemilik gagasan aslinya.

## Poin Penting
- **Kejujuran Intelektual**: Menghargai hak cipta intelektual penulis lain secara etis.
- **Peta Penelusuran**: Memudahkan pembaca esai Anda untuk melacak dan membaca lebih lanjut sumber pustaka asli jika mereka tertarik.
- **Deteksi Plagiarisme**: Universitas modern menggunakan software deteksi seperti *Turnitin* untuk memeriksa tingkat kesamaan (*similarity index*) tulisan mahasiswa secara ketat.

## Mini Rangkuman
Etika sitasi ilmiah gaya APA Edisi ke-7 dan pencegahan plagiarisme adalah fondasi utama integritas akademik. Dengan mematuhi aturan in-text citation yang akurat, melakukan teknik paraphrase secara kreatif, serta menyusun daftar pustaka teratur di akhir tulisan, kita dapat menghasilkan karya ilmiah yang kredibel, orisinal, dan terhormat di mata komunitas akademik.''',
        'orderIndex': 3,
        'youtubeUrl': 'https://www.youtube.com/watch?v=vVBAmlFcQuE',
        'youtubeTitle': 'Tips Presentasi Bahasa Inggris yang Baik dan Benar',
        'youtubeChannel': 'Kampung Inggris LC',
        'createdAt': now,
      });

      debugPrint('MODULE CREATED: materials/db_systems/modules/db_systems_m1 (Pengantar Basis Data & Arsitektur Abstraksi)');
      debugPrint('MODULE CREATED: materials/db_systems/modules/db_systems_m2 (Model Data Relasional & Peran Kunci (Keys))');
      debugPrint('MODULE CREATED: materials/db_systems/modules/db_systems_m3 (Entity-Relationship Diagram (ERD) Konseptual)');
      debugPrint('MODULE CREATED: materials/db_systems/modules/db_systems_m4 (Dasar Pemrograman SQL & Manipulasi Data)');
      
      debugPrint('MODULE CREATED: materials/ai_fuzzy/modules/ai_fuzzy_m1 (Pengantar Kecerdasan Buatan & Sistem Pakar)');
      debugPrint('MODULE CREATED: materials/ai_fuzzy/modules/ai_fuzzy_m2 (Konsep Logika Fuzzy & Himpunan Samar)');
      debugPrint('MODULE CREATED: materials/ai_fuzzy/modules/ai_fuzzy_m3 (Metode Inferensi Fuzzy Mamdani & Sugeno)');
      debugPrint('MODULE CREATED: materials/ai_fuzzy/modules/ai_fuzzy_m4 (Studi Kasus & Implementasi Fuzzy)');
      
      debugPrint('MODULE CREATED: materials/statistics_prob/modules/statistics_prob_m1 (Probabilitas Dasar & Teorema Bayes)');
      debugPrint('MODULE CREATED: materials/statistics_prob/modules/statistics_prob_m2 (Distribusi Probabilitas & Variabel Acak)');
      debugPrint('MODULE CREATED: materials/statistics_prob/modules/statistics_prob_m3 (Estimasi Parameter & Uji Hipotesis)');
      debugPrint('MODULE CREATED: materials/statistics_prob/modules/statistics_prob_m4 (Analisis Regresi Linier Sederhana)');
      
      debugPrint('MODULE CREATED: materials/academic_english/modules/academic_english_m1 (Introduction to Academic Writing & Tone)');
      debugPrint('MODULE CREATED: materials/academic_english/modules/academic_english_m2 (Developing Strong Thesis Statements)');
      debugPrint('MODULE CREATED: materials/academic_english/modules/academic_english_m3 (Synthesizing Sources & Literature Review)');
      debugPrint('MODULE CREATED: materials/academic_english/modules/academic_english_m4 (APA 7th Referencing & Avoiding Plagiarism)');

      debugPrint('[LearningService] Melakukan commit batch seeding ke Firestore (total 4 materi dan 16 modul)...');
      await batch.commit();
      debugPrint('SEED SUCCESS: Sukses mendaftarkan 4 Materi kuliah default beserta 16 modul akademis premium ke Firestore!');
    } catch (e, stackTrace) {
      debugPrint('SEED FAILED: Gagal melakukan seeding database!');
      debugPrint('[LearningService] ERROR ASLI: $e');
      debugPrint('[LearningService] STACKTRACE: $stackTrace');
      rethrow;
    }
  }

  /// Cleans up legacy dummy data and test materials/modules from Firestore
  Future<void> cleanupLegacyDummyData(String uid) async {
    debugPrint('[LearningService] cleanupLegacyDummyData() dipanggil untuk uid: $uid');
    try {
      final premiumMaterialIds = ['db_systems', 'ai_fuzzy', 'statistics_prob', 'academic_english'];
      final premiumModuleIds = [
        'db_systems_m1', 'db_systems_m2', 'db_systems_m3', 'db_systems_m4',
        'ai_fuzzy_m1', 'ai_fuzzy_m2', 'ai_fuzzy_m3', 'ai_fuzzy_m4',
        'statistics_prob_m1', 'statistics_prob_m2', 'statistics_prob_m3', 'statistics_prob_m4',
        'academic_english_m1', 'academic_english_m2', 'academic_english_m3', 'academic_english_m4'
      ];

      // 1. Clean up materials collection
      debugPrint('[LearningService] Memulai pembersihan koleksi materials...');
      final allMaterials = await _materialsCollection.get();
      for (final doc in allMaterials.docs) {
        final materialId = doc.id;
        if (!premiumMaterialIds.contains(materialId)) {
          debugPrint('[LearningService] Mendeteksi material dummy: $materialId. Menghapus modul di bawahnya...');
          // Fetch and delete subcollection modules first
          final modulesSnap = await _modulesCollection(materialId).get();
          final moduleBatch = _firestore.batch();
          for (final mDoc in modulesSnap.docs) {
            moduleBatch.delete(mDoc.reference);
            debugPrint('TEST MODULE REMOVED: ${mDoc.id}');
          }
          await moduleBatch.commit();

          // Delete the material itself
          await doc.reference.delete();
          debugPrint('DUMMY MATERIAL REMOVED: $materialId');
        }
      }

      if (uid.isNotEmpty) {
        // 2. Clean up module progress
        debugPrint('[LearningService] Memulai pembersihan module progress...');
        final progressSnap = await _progressCollection(uid).get();
        final progressBatch = _firestore.batch();
        int progressDeletedCount = 0;
        for (final doc in progressSnap.docs) {
          final moduleId = doc.id;
          final data = doc.data();
          final materialId = data['materialId'] as String?;
          
          final isDummyMaterial = materialId != null && !premiumMaterialIds.contains(materialId);
          final isDummyModule = !premiumModuleIds.contains(moduleId);

          if (isDummyMaterial || isDummyModule) {
            progressBatch.delete(doc.reference);
            debugPrint('DUMMY PROGRESS REMOVED: $moduleId');
            progressDeletedCount++;
          }
        }
        if (progressDeletedCount > 0) {
          await progressBatch.commit();
        }

        // 3. Clean up quiz sessions and their nested questions
        debugPrint('[LearningService] Memulai pembersihan quiz sessions...');
        final quizSessionsCollection = _firestore.collection('users').doc(uid).collection('quiz_sessions');
        final quizSnap = await quizSessionsCollection.get();
        for (final doc in quizSnap.docs) {
          final data = doc.data();
          final sessionId = doc.id;
          final materialId = data['materialId'] as String?;
          final materialTitle = (data['materialTitle'] as String?)?.toLowerCase() ?? '';
          final aiFeedback = (data['aiFeedback'] as String?)?.toLowerCase() ?? '';

          final isDummyMaterial = materialId != null && materialId.isNotEmpty && !premiumMaterialIds.contains(materialId);
          final hasDummyTitle = materialTitle.contains('test') || 
                                materialTitle.contains('dummy') || 
                                materialTitle.contains('lorem') || 
                                materialTitle.contains('percobaan') ||
                                materialTitle.contains('sample');
          final hasDummyFeedback = aiFeedback.contains('test') || 
                                   aiFeedback.contains('dummy') || 
                                   aiFeedback.contains('lorem') || 
                                   aiFeedback.contains('percobaan') ||
                                   aiFeedback.contains('sample');

          if (isDummyMaterial || hasDummyTitle || hasDummyFeedback || sessionId.contains('test') || sessionId.contains('dummy')) {
            debugPrint('[LearningService] Mendeteksi sesi kuis dummy: $sessionId. Menghapus subkoleksi questions...');
            final questionsSnap = await doc.reference.collection('questions').get();
            final qBatch = _firestore.batch();
            for (final qDoc in questionsSnap.docs) {
              qBatch.delete(qDoc.reference);
            }
            await qBatch.commit();

            await doc.reference.delete();
            debugPrint('DUMMY QUIZ SESSION REMOVED: $sessionId');
          }
        }

        // 4. Clean up notifications
        debugPrint('[LearningService] Memulai pembersihan notifications...');
        final notificationsCollection = _firestore.collection('users').doc(uid).collection('notifications');
        final notifSnap = await notificationsCollection.get();
        final notifBatch = _firestore.batch();
        int notifDeletedCount = 0;
        for (final doc in notifSnap.docs) {
          final data = doc.data();
          final notifId = doc.id;
          final title = (data['title'] as String?)?.toLowerCase() ?? '';
          final message = (data['message'] as String?)?.toLowerCase() ?? '';

          final hasDummyText = title.contains('test') || 
                               title.contains('dummy') || 
                               title.contains('lorem') || 
                               title.contains('percobaan') ||
                               title.contains('sample') ||
                               message.contains('test') || 
                               message.contains('dummy') || 
                               message.contains('lorem') || 
                               message.contains('percobaan') ||
                               message.contains('sample');

          if (hasDummyText || notifId.contains('test') || notifId.contains('dummy')) {
            notifBatch.delete(doc.reference);
            debugPrint('DUMMY NOTIFICATION REMOVED: $notifId');
            notifDeletedCount++;
          }
        }
        if (notifDeletedCount > 0) {
          await notifBatch.commit();
        }
      }

      debugPrint('CLEANUP SUCCESS: Seluruh data legacy dummy dan test berhasil dibersihkan.');
    } catch (e, stackTrace) {
      debugPrint('CLEANUP FAILED: Gagal melakukan pembersihan database!');
      debugPrint('[LearningService] ERROR ASLI: $e');
      debugPrint('[LearningService] STACKTRACE: $stackTrace');
      rethrow;
    }
  }
}

