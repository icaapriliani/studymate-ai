import 'package:flutter/material.dart';

class MaterialModel {
  final String id;
  final String title;
  final String modules;
  final String description;
  final List<String> keyPoints;
  final List<SampleQuestionModel> sampleQuestions;
  final double progress;
  final String estimatedTime;
  final Color color;
  final String category;

  const MaterialModel({
    required this.id,
    required this.title,
    required this.modules,
    required this.description,
    required this.keyPoints,
    required this.sampleQuestions,
    required this.progress,
    required this.estimatedTime,
    required this.color,
    required this.category,
  });

  static final List<MaterialModel> dummyMaterials = [
    MaterialModel(
      id: 'db_systems',
      title: 'Sistem Manajemen Basis Data',
      modules: '12 Modul • 4 Bab Selesai',
      description: 'Sistem Manajemen Basis Data (DBMS) adalah perangkat lunak yang dirancang untuk mengelola, menyimpan, memanipulasi, dan mengambil data secara efisien dan aman. DBMS menjadi tulang punggung bagi sebagian besar aplikasi modern dengan menyediakan abstraksi data, integritas data, kontrol konkurensi, keamanan, serta mekanisme pemulihan data setelah terjadinya kegagalan sistem.',
      keyPoints: [
        'Model Relasional: Menggunakan tabel bertipe baris-kolom untuk representasi hubungan logis data.',
        'Bahasa Kueri Terstruktur (SQL): Digunakan untuk Data Definition Language (DDL) dan Data Manipulation Language (DML).',
        'Karakteristik ACID: Menjamin keandalan transaksi (Atomicity, Consistency, Isolation, Durability).',
        'Normalisasi: Proses pengorganisasian data (1NF, 2NF, 3NF, BCNF) untuk mengeliminasi redundansi dan anomali data.',
        'Konsep Kunci Database: Memahami perbedaan Primary Key, Foreign Key, dan Candidate Key.'
      ],
      sampleQuestions: [
        SampleQuestionModel(
          question: 'Apa perbedaan utama antara DDL (Data Definition Language) dan DML (Data Manipulation Language)?',
          answer: 'DDL digunakan untuk mendefinisikan skema atau struktur database, sedangkan DML digunakan untuk mengelola data di dalam struktur tersebut.',
          explanation: 'Perintah DDL meliputi CREATE, ALTER, dan DROP (berdampak langsung pada arsitektur tabel). Perintah DML meliputi SELECT, INSERT, UPDATE, dan DELETE (berdampak pada konten data di dalam tabel tanpa mengubah struktur fisiknya).',
        ),
        SampleQuestionModel(
          question: 'Jelaskan konsep "Durability" dalam transaksi ACID!',
          answer: 'Durability menjamin bahwa setelah transaksi berhasil dikomit, perubahan datanya bersifat permanen dan tidak akan hilang bahkan jika sistem mengalami kegagalan daya atau crash.',
          explanation: 'Mekanisme ini biasanya dicapai dengan menulis catatan transaksi (transaction logs) ke dalam penyimpanan non-volatile sebelum perubahan fisik diaplikasikan ke database utama.',
        )
      ],
      progress: 0.45,
      estimatedTime: '4 Jam 30 Menit',
      color: const Color(0xFF1E58C1),
      category: 'Ilmu Komputer',
    ),
    MaterialModel(
      id: 'ai_fuzzy',
      title: 'Kecerdasan Buatan & Logika Fuzzy',
      modules: '18 Modul • 6 Bab Selesai',
      description: 'Kecerdasan Buatan (AI) berfokus pada pengembangan sistem cerdas yang mampu meniru kemampuan kognitif manusia. Modul ini membahas representasi pengetahuan, teknik pencarian jalur (searching), jaringan saraf tiruan dasar, serta Logika Fuzzy sebagai metode penanganan ambiguitas dan ketidakpastian informasi dalam pengambilan keputusan dunia nyata.',
      keyPoints: [
        'Pencarian Heuristik: Algoritma seperti A* Search yang menggunakan fungsi estimasi biaya untuk menemukan jalur optimal.',
        'Representasi Pengetahuan: Struktur formal seperti Semantic Networks dan Ontologi untuk memetakan pemahaman mesin.',
        'Logika Fuzzy: Ekstensi logika klasik boolean yang mengenal nilai kebenaran parsial antara benar (1) dan salah (0).',
        'Fuzzifikasi & Defuzzifikasi: Proses konversi variabel riil (crisp) menjadi nilai linguistik fuzzy dan sebaliknya.',
        'Jaringan Saraf Dasar: Pengenalan struktur Perseptron tunggal dan mekanisme aktivasi fungsi.'
      ],
      sampleQuestions: [
        SampleQuestionModel(
          question: 'Bagaimana cara kerja Logika Fuzzy berbeda dari Logika Boolean tradisional?',
          answer: 'Logika Boolean hanya mengenal dua kondisi mutlak (0 atau 1, Salah atau Benar), sedangkan Logika Fuzzy mengenal nilai di antara keduanya (derajat keanggotaan dalam rentang [0, 1]).',
          explanation: 'Misalnya, dalam logika Boolean suhu 30°C langsung dikategorikan panas (1) atau dingin (0). Dalam logika Fuzzy, suhu tersebut bisa memiliki derajat keanggotaan 0.7 "hangat" dan 0.3 "panas".',
        )
      ],
      progress: 0.68,
      estimatedTime: '6 Jam 15 Menit',
      color: const Color(0xFF6B3BC7),
      category: 'Kecerdasan Buatan',
    ),
    MaterialModel(
      id: 'academic_english',
      title: 'Bahasa Inggris Akademik',
      modules: '8 Modul • 2 Bab Selesai',
      description: 'Modul Bahasa Inggris Akademik dirancang khusus untuk membantu mahasiswa menguasai keterampilan membaca kritis, menyusun esai akademis, memahami struktur tata bahasa formal, serta menyajikan presentasi ilmiah secara meyakinkan. Fokus pembelajaran adalah perluasan kosakata formal (Academic Word List) dan teknik sitasi karya ilmiah.',
      keyPoints: [
        'Membaca Kritis (Critical Reading): Teknik analisis teks, membedakan fakta dan opini, serta menyimpulkan argumen implisit.',
        'Struktur Esai Akademis: Menyusun Thesis Statement, Topic Sentence, Body Paragraphs, dan Kesimpulan yang logis.',
        'Kosakata Formal: Penggunaan Academic Word List (AWL) untuk menghindari bahasa sehari-hari dalam penulisan ilmiah.',
        'Teknik Sitasi & Plagiarisme: Memahami gaya sitasi ilmiah (seperti APA, MLA) untuk menjaga integritas akademik.',
        'Presentasi Ilmiah: Teknik penyampaian argumen lisan yang terstruktur menggunakan istilah transisi akademis.'
      ],
      sampleQuestions: [
        SampleQuestionModel(
          question: 'Apa fungsi utama dari sebuah "Thesis Statement" dalam esai akademik?',
          answer: 'Thesis Statement berfungsi sebagai gagasan pokok atau argumen sentral dari seluruh esai yang diletakkan di akhir paragraf pendahuluan.',
          explanation: 'Pernyataan tesis ini bertindak sebagai peta jalan bagi pembaca, mendefinisikan posisi penulis secara jelas dan membatasi cakupan analisis esai.',
        )
      ],
      progress: 0.25,
      estimatedTime: '3 Jam 00 Menit',
      color: const Color(0xFF2E7D32),
      category: 'Bahasa',
    ),
    MaterialModel(
      id: 'statistics_prob',
      title: 'Statistika & Probabilitas',
      modules: '14 Modul • 0 Bab Selesai',
      description: 'Statistika dan Probabilitas memberikan landasan matematis untuk pengumpulan, analisis, interpretasi, presentasi, dan pengambilan keputusan berdasarkan data. Modul ini membimbing mahasiswa dari konsep dasar peluang, distribusi diskrit dan kontinu, uji hipotesis parameter, hingga analisis regresi linier sederhana.',
      keyPoints: [
        'Ukuran Pemusatan Data: Memahami Mean, Median, Modus, serta ukuran penyebaran seperti Standard Deviasi.',
        'Probabilitas Bersyarat: Aturan Bayes untuk memperbarui estimasi peluang berdasarkan bukti baru yang relevan.',
        'Distribusi Teoretis: Karakteristik Distribusi Normal (Bell Curve), Distribusi Binomial, dan Distribusi Poisson.',
        'Uji Hipotesis: Langkah pengujian statistik menggunakan parameter p-value, signifikansi alpha, serta penolakan H0.',
        'Korelasi & Regresi: Menghitung hubungan sebab-akibat antar variabel acak secara kuantitatif.'
      ],
      sampleQuestions: [
        SampleQuestionModel(
          question: 'Kapan kita harus menggunakan Median daripada Mean sebagai ukuran pemusatan data?',
          answer: 'Kita menggunakan Median ketika distribusi data sangat condong (skewed) atau memiliki pencilan (outliers) ekstrem yang dapat mendistorsi nilai rata-rata (mean).',
          explanation: 'Mean sangat sensitif terhadap nilai ekstrem. Sebagai contoh, rata-rata pendapatan di suatu wilayah bisa tampak sangat tinggi hanya karena satu orang miliarder, sedangkan median akan mencerminkan nilai tengah pendapatan yang lebih realistis bagi mayoritas warga.',
        )
      ],
      progress: 0.0,
      estimatedTime: '5 Jam 45 Menit',
      color: Colors.grey,
      category: 'Ilmu Komputer',
    )
  ];
}

class SampleQuestionModel {
  final String question;
  final String answer;
  final String explanation;

  const SampleQuestionModel({
    required this.question,
    required this.answer,
    required this.explanation,
  });
}
