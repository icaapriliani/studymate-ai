StudyMate AI — Blueprint Aplikasi 

1. Deskripsi Aplikasi
StudyMate AI adalah aplikasi mobile berbasis Flutter yang dirancang sebagai platform belajar modern dengan bantuan Artificial Intelligence (AI). Aplikasi ini membantu mahasiswa dalam:
•	Belajar materi modular
•	Bertanya kepada AI Tutor
•	Mengerjakan quiz AI dinamis
•	Melacak progress belajar secara realtime
•	Melihat statistik pembelajaran
•	Menyimpan riwayat pembelajaran dan percakapan
Aplikasi menggunakan:
•	Flutter
•	Firebase Authentication
•	Cloud Firestore
•	Gemini AI API
•	Provider State Management
•	Clean Architecture
2. Tujuan Aplikasi
Tujuan utama StudyMate AI:
1.	Membantu mahasiswa belajar lebih interaktif
2.	Memberikan pengalaman belajar modern berbasis AI
3.	Menyediakan progress belajar realtime
4.	Menampilkan statistik pembelajaran personal
5.	Memberikan quiz yang berbeda untuk setiap sesi pengguna
6.	Menjadi platform belajar yang ringan namun realistis
3. Fitur Utama Aplikasi
A. Authentication System
Fitur:
•	Register akun
•	Login akun
•	Logout
•	Penyimpanan data user ke Firestore
Teknologi:
•	Firebase Authentication
•	Cloud Firestore
Data User:
•	UID
•	Email
•	Display Name
•	Created At
B. AI Tutor Chat
Fitur:
•	Chat dengan AI Gemini
•	Riwayat chat tersimpan
•	Obrolan baru
•	Multi-session chat
•	Error handling AI
•	Loading realtime
Teknologi:
•	Gemini AI API
•	Firestore Chat History
Struktur Database:
users/{uid}/chat_sessions/{sessionId}/messages/{messageId}
Isi Pesan:
•	text
•	sender
•	timestamp
C. Modular Learning System
Konsep:
Satu materi memiliki beberapa modul pembelajaran.
Contoh:
Materi:
•	Sistem Manajemen Basis Data
Modul:
•	Pengantar Database
•	ERD
•	SQL Dasar
•	Primary Key
D. Realtime Learning Progress
Fitur:
•	Progress realtime
•	Tandai modul selesai
•	Sinkronisasi otomatis
•	Progress material dihitung otomatis
Rumus Progress:
jumlah modul selesai / total modul
Struktur Database:
users/{uid}/module_progress/{moduleId}
Field:
•	materialId
•	completed
•	completedAt
•	lastReadAt
E. Dynamic AI Quiz
Fitur:
•	Quiz dibuat AI Gemini
•	Soal berbeda setiap sesi
•	Multi-session quiz
•	AI Feedback
•	Riwayat hasil quiz
Alur:
1.	User membuka materi
2.	Generate quiz AI
3.	Gemini membuat soal pilihan ganda
4.	User menjawab
5.	AI memberikan evaluasi
6.	Hasil disimpan ke Firestore
Struktur Database:
users/{uid}/quiz_sessions/{sessionId}
Subcollection:
questions/{questionId}
F. Statistics & Learning Analytics
Fitur:
•	Progress belajar
•	Total modul selesai
•	Quiz completion
•	Daily streak
•	Weekly activity
•	Learning activity tracking
Data Realtime:
•	Home Page
•	Statistics Page
•	Modular Progress
G. Notification System
Fitur:
•	Notifikasi pengingat belajar
•	Reminder aktivitas
•	Integrasi dengan progress belajar
4. Struktur Database Firestore
A. Users
users/{uid}
Field:
•	displayName
•	email
•	createdAt
•	photoUrl
B. Materials
materials/{materialId}
Field:
•	title
•	description
•	category
•	thumbnailColor
•	estimatedMinutes
•	createdAt
C. Modules
materials/{materialId}/modules/{moduleId}
Field:
•	title
•	content
•	orderIndex
•	estimatedMinutes
•	createdAt
D. Module Progress
users/{uid}/module_progress/{moduleId}
Field:
•	materialId
•	completed
•	completedAt
•	lastReadAt
E. AI Chat Sessions
users/{uid}/chat_sessions/{sessionId}
Subcollection:
messages/{messageId}
F. Quiz Sessions
users/{uid}/quiz_sessions/{sessionId}
Subcollection:
questions/{questionId}
5. Arsitektur Aplikasi
Aplikasi menggunakan:
Clean Architecture
Layer:
A. Presentation Layer
Berisi:
•	Pages
•	Widgets
•	Providers
B. Domain Layer
Berisi:
•	Repository Interfaces
•	Business Logic
C. Data Layer
Berisi:
•	Repository Implementations
•	Services
•	Firebase Integration
6. State Management
Menggunakan:
Provider
Provider utama:
•	AuthProvider
•	AIChatProvider
•	LearningProvider
•	StatisticsProvider
•	QuizProvider
•	NotificationProvider
7. Teknologi yang Digunakan
Teknologi	Fungsi
Flutter	Framework utama
Firebase Auth	Login/Register
Cloud Firestore	Database realtime
Gemini AI	AI Tutor & Quiz
Provider	State Management
Flutter Local Notifications	Reminder belajar
Flutter Dotenv	API Key Management

8. Tampilan Halaman
A. Splash Screen
Menampilkan logo dan inisialisasi aplikasi.
 
B. Login & Register
Autentikasi pengguna.
 
C. Home Page
Menampilkan:
•	Statistik realtime
•	Progress belajar
•	Shortcut fitur
•	Course shelf
 
D. Materials Page
Menampilkan daftar materi pembelajaran.
 
E. Material Detail Page
Menampilkan:
•	Informasi materi
•	Progress
•	Daftar modul
F. Module Detail Page
Menampilkan isi pembelajaran modul.
G. AI Tutor Page
Halaman chat AI.
H. Quiz Page
Quiz AI pilihan ganda.
 
I. Statistics Page
Analisis progress belajar pengguna.
 
J. Profile Page
Informasi akun pengguna.
 
9. Keunggulan Aplikasi
A. Realtime System
Data otomatis sinkron.
B. AI Integration
Menggunakan Gemini AI.
C. Dynamic Quiz
Soal berbeda tiap sesi.
D. Clean Architecture
Kode lebih terstruktur.
E. Modular Learning
Belajar bertahap per modul.
F. Personalized Experience
Progress dan riwayat tersimpan per user.
10. Status Pengembangan Saat Ini
Sudah Selesai
•	Authentication
•	Firestore Integration
•	AI Tutor Chat
•	Chat History
•	Multi-session Chat
•	Dynamic AI Quiz
•	Modular Learning System
•	Realtime Progress
•	Statistics Integration
•	Notification System
•	Firestore Cleanup
•	Seeder Materials
11. Kesimpulan
StudyMate AI merupakan aplikasi pembelajaran modern berbasis Flutter dan Artificial Intelligence yang mengintegrasikan:
•	sistem belajar modular,
•	AI Tutor,
•	quiz dinamis,
•	progress realtime,
•	dan statistik pembelajaran.
Aplikasi dirancang menggunakan Clean Architecture agar scalable, maintainable, dan siap dikembangkan lebih lanjut menjadi platform e-learning yang lebih besar di masa depan.

