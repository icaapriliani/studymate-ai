import 'dart:ui';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../auth/login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  // Mock course data
  final List<Map<String, dynamic>> _courses = [
    {
      'title': 'Database Systems',
      'category': 'Ilmu Komputer',
      'progress': 0.45,
      'chapterInfo': 'Bab 4 dari 12',
      'icon': Icons.storage_rounded,
      'color': const Color(0xFFE2EDF9),
      'iconColor': const Color(0xFF1E58C1),
    },
    {
      'title': 'Artificial Intelligence',
      'category': 'Kecerdasan Buatan',
      'progress': 0.68,
      'chapterInfo': 'Bab 6 dari 18',
      'icon': Icons.psychology_rounded,
      'color': const Color(0xFFEDE4F9),
      'iconColor': const Color(0xFF6B3BC7),
    },
    {
      'title': 'Academic Writing',
      'category': 'Bahasa & Penelitian',
      'progress': 0.25,
      'chapterInfo': 'Bab 2 dari 8',
      'icon': Icons.history_edu_rounded,
      'color': const Color(0xFFE8F5E9),
      'iconColor': const Color(0xFF2E7D32),
    }
  ];

  // Daily checklist progress
  final List<Map<String, dynamic>> _days = [
    {'day': 'S', 'done': true}, // Senin
    {'day': 'S', 'done': true}, // Selasa
    {'day': 'R', 'done': true}, // Rabu
    {'day': 'K', 'done': true}, // Kamis
    {'day': 'J', 'done': false}, // Jumat
    {'day': 'S', 'done': false}, // Sabtu
    {'day': 'M', 'done': false}, // Minggu
  ];

  // Mock chat messages for AI Tutor
  final List<Map<String, dynamic>> _chatMessages = [
    {
      'isSender': false,
      'text': 'Halo Alex! Ada materi yang ingin kamu diskusikan hari ini? Aku bisa membantumu meringkas bab, menjelaskan konsep sulit, atau membuat kuis.',
      'time': '08:30',
    },
    {
      'isSender': true,
      'text': 'Tolong jelaskan perbedaan mendasar antara SQL dan NoSQL.',
      'time': '08:32',
    },
    {
      'isSender': false,
      'text': 'Tentu! Perbedaan utama terletak pada model data & skalabilitas:\n\n1. **SQL (Relasional)**: Menggunakan tabel kaku (baris/kolom) dan skema tetap. Sangat cocok untuk transaksi kompleks yang butuh konsistensi tinggi.\n2. **NoSQL (Non-Relasional)**: Menggunakan struktur fleksibel (seperti dokumen JSON, graf, atau key-value). Sangat ideal untuk skala data raksasa dan struktur yang cepat berubah.',
      'time': '08:33',
    }
  ];

  // Mock materials for Library tab
  final List<Map<String, dynamic>> _materials = [
    {
      'title': 'Sistem Manajemen Basis Data',
      'modules': '12 Modul • 4 Bab Selesai',
      'progress': 0.45,
      'color': const Color(0xFF1E58C1),
    },
    {
      'title': 'Kecerdasan Buatan & Logika Fuzzy',
      'modules': '18 Modul • 6 Bab Selesai',
      'progress': 0.68,
      'color': const Color(0xFF6B3BC7),
    },
    {
      'title': 'Bahasa Inggris Akademik',
      'modules': '8 Modul • 2 Bab Selesai',
      'progress': 0.25,
      'color': const Color(0xFF2E7D32),
    },
    {
      'title': 'Statistika & Probabilitas',
      'modules': '14 Modul • 0 Bab Selesai',
      'progress': 0.0,
      'color': Colors.grey,
    }
  ];

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.shortestSide > 600;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.bgGradientStart,
              AppColors.bgGradientEnd,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              // Main Multi-Screen Content via IndexedStack
              Positioned.fill(
                child: IndexedStack(
                  index: _currentIndex,
                  children: [
                    _buildBeranda(context, isTablet),
                    _buildMateri(context, isTablet),
                    _buildAITutor(context, isTablet),
                    _buildStatistik(context, isTablet),
                    _buildProfil(context, isTablet),
                  ],
                ),
              ),

              // 6. Floating Glassmorphic Bottom Navigation Bar
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 20.0,
                    right: 20.0,
                    bottom: 16.0,
                  ),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 560),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(12),
                          blurRadius: 25,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: 18.0,
                          sigmaY: 18.0,
                        ),
                        child: Container(
                          height: 68,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(204), // 80% white
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withAlpha(150),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildNavItem(0, Icons.home_rounded, 'Beranda'),
                              _buildNavItem(1, Icons.folder_rounded, 'Materi'),
                              _buildNavItem(2, Icons.auto_awesome_rounded, 'AI Tutor'),
                              _buildNavItem(3, Icons.bar_chart_rounded, 'Statistik'),
                              _buildNavItem(4, Icons.person_rounded, 'Profil'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Floating NavItem builder
  Widget _buildNavItem(int index, IconData icon, String label) {
    final bool isSelected = _currentIndex == index;
    final Color itemColor = isSelected
        ? AppColors.primaryGradientStart
        : AppColors.textLight.withAlpha(180);

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: itemColor,
            size: isSelected ? 24 : 22,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
              color: itemColor,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  // --- SCREEN 1: BERANDA ---
  Widget _buildBeranda(BuildContext context, bool isTablet) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Header (Greeting & Notification)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Hai, Alex Rivers 👋',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Mari jelajahi belajarmu hari ini",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      // Glassmorphic Notification Button
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(5),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(
                              sigmaX: 10,
                              sigmaY: 10,
                            ),
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.glassBg,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.glassBorder,
                                  width: 1.5,
                                ),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  const Icon(
                                    Icons.notifications_none_outlined,
                                    color: AppColors.textPrimary,
                                    size: 22,
                                  ),
                                  Positioned(
                                    top: 14,
                                    right: 14,
                                    child: Container(
                                      width: 7,
                                      height: 7,
                                      decoration: const BoxDecoration(
                                        color: Colors.redAccent,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // 2. Weekly Progress Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(8),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      'Progres Target Mingguan',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      "Semangat! Kamu hampir mencapai target minggu ini.",
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textSecondary,
                                        height: 1.3,
                                      ),
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      '12j / 15j selesai',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primaryGradientStart,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 72,
                                    height: 72,
                                    child: CircularProgressIndicator(
                                      value: 0.8,
                                      strokeWidth: 8,
                                      backgroundColor: AppColors.progressTrack,
                                      valueColor: const AlwaysStoppedAnimation<Color>(
                                        AppColors.primaryGradientStart,
                                      ),
                                    ),
                                  ),
                                  const Text(
                                    '80%',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: _days.map((dayData) {
                              final bool done = dayData['done'];
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: done
                                          ? const LinearGradient(
                                              colors: [
                                                AppColors.primaryGradientStart,
                                                AppColors.primaryGradientEnd,
                                              ],
                                            )
                                          : null,
                                      color: done ? null : AppColors.progressTrack,
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.check,
                                        color: done ? Colors.white : Colors.transparent,
                                        size: 14,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    dayData['day'],
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: done
                                          ? AppColors.primaryGradientStart
                                          : AppColors.textLight,
                                    ),
                                  )
                                ],
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 3. AI Tutor CTA Card
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.primaryGradientStart,
                          AppColors.primaryGradientEnd,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryGradientStart.withAlpha(76),
                          blurRadius: 25,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -20,
                          top: -20,
                          child: Icon(
                            Icons.auto_awesome,
                            size: 140,
                            color: Colors.white.withAlpha(20),
                          ),
                        ),
                        Positioned(
                          left: 20,
                          bottom: -30,
                          child: Icon(
                            Icons.psychology_outlined,
                            size: 100,
                            color: Colors.white.withAlpha(15),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(28.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(
                                    Icons.auto_awesome_rounded,
                                    color: Colors.amberAccent,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'STUDYMATE AI TUTOR',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.5,
                                      color: Colors.amberAccent,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Tanya StudyMate AI',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tanyakan apa saja, ringkas materi, atau buat kuis secara instan!',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withAlpha(220),
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: () {
                                  // Switch to AI Tutor Tab (Index 2)
                                  setState(() {
                                    _currentIndex = 2;
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppColors.primaryGradientStart,
                                  elevation: 4,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                ),
                                child: const Text(
                                  'Tanya Sekarang',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // 4. Lanjutkan Belajar Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Lanjutkan Belajar',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          // Switch to Materi Tab (Index 1)
                          setState(() {
                            _currentIndex = 1;
                          });
                        },
                        child: const Text(
                          'Lihat Semua',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryGradientStart,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 5. Course Shelf (Horizontal ListView)
                  SizedBox(
                    height: 185,
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      scrollDirection: Axis.horizontal,
                      itemCount: _courses.length,
                      itemBuilder: (context, index) {
                        final course = _courses[index];
                        return Container(
                          width: 240,
                          margin: const EdgeInsets.only(
                            right: 16,
                            bottom: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(5),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: course['color'],
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        course['icon'],
                                        color: course['iconColor'],
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        course['category'],
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.textSecondary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  course['title'],
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  course['chapterInfo'],
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textLight,
                                  ),
                                ),
                                const Spacer(),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: AppColors.progressTrack,
                                          borderRadius: BorderRadius.circular(100),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(100),
                                          child: LinearProgressIndicator(
                                            value: course['progress'],
                                            backgroundColor: Colors.transparent,
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              course['iconColor'],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      '${(course['progress'] * 100).round()}%',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        color: course['iconColor'],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 85),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- SCREEN 2: MATERI ---
  Widget _buildMateri(BuildContext context, bool isTablet) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Materi Belajar',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Temukan modul kuliah dan bahan belajarmu',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(5),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const TextField(
                      style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.search_rounded, color: AppColors.textLight, size: 20),
                        hintText: 'Cari modul atau materi kuliah...',
                        hintStyle: TextStyle(color: AppColors.textLight, fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Filter Categories Shelf
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _buildFilterPill('Semua', true),
                        _buildFilterPill('Ilmu Komputer', false),
                        _buildFilterPill('Kecerdasan Buatan', false),
                        _buildFilterPill('Bahasa', false),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Materials List
                  Column(
                    children: _materials.map((mat) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(5),
                              blurRadius: 15,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      mat['title'],
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  Icon(Icons.more_vert_rounded, color: AppColors.textLight.withAlpha(150)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                mat['modules'],
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: AppColors.progressTrack,
                                        borderRadius: BorderRadius.circular(100),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(100),
                                        child: LinearProgressIndicator(
                                          value: mat['progress'],
                                          backgroundColor: Colors.transparent,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            mat['color'],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '${(mat['progress'] * 100).round()}%',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      color: mat['color'],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 85),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterPill(String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Material(
        color: isSelected ? AppColors.primaryGradientStart : Colors.white,
        borderRadius: BorderRadius.circular(100),
        elevation: isSelected ? 4 : 1,
        shadowColor: isSelected ? AppColors.primaryGradientStart.withAlpha(80) : Colors.black12,
        child: InkWell(
          borderRadius: BorderRadius.circular(100),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- SCREEN 3: AI TUTOR ---
  Widget _buildAITutor(BuildContext context, bool isTablet) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                // Chat Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                  child: Row(
                    children: [
                      // Glowing green status avatar
                      Stack(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primaryGradientStart,
                                  AppColors.primaryGradientEnd,
                                ],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.auto_awesome_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.greenAccent,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Tutor AI StudyMate',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Aktif Sekarang',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Conversation Box
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white70,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(36),
                        topRight: Radius.circular(36),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(36),
                        topRight: Radius.circular(36),
                      ),
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                        itemCount: _chatMessages.length,
                        itemBuilder: (context, index) {
                          final msg = _chatMessages[index];
                          final isSender = msg['isSender'];
                          return Align(
                            alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              constraints: BoxConstraints(
                                maxWidth: constraints.maxWidth * 0.75,
                              ),
                              decoration: BoxDecoration(
                                color: isSender ? AppColors.primaryGradientStart : Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(20),
                                  topRight: const Radius.circular(20),
                                  bottomLeft: Radius.circular(isSender ? 20 : 4),
                                  bottomRight: Radius.circular(isSender ? 4 : 20),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(4),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      msg['text'],
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: isSender ? Colors.white : AppColors.textPrimary,
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Align(
                                      alignment: Alignment.bottomRight,
                                      child: Text(
                                        msg['time'],
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: isSender ? Colors.white70 : AppColors.textLight,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                // Typing Panel Input Box
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 12,
                    bottom: 85,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.progressTrack,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: const TextField(
                            style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
                            decoration: InputDecoration(
                              hintText: 'Tanya StudyMate AI...',
                              hintStyle: TextStyle(color: AppColors.textLight, fontSize: 14),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryGradientStart,
                              AppColors.primaryGradientEnd,
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- SCREEN 4: STATISTIK ---
  Widget _buildStatistik(BuildContext context, bool isTablet) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Statistik Belajar',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Pantau performa dan jam belajar mingguanmu',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Mini Status Grid Cards
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.4,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildStatGridCard('Total Jam', '38 Jam', '+12% minggu ini', Icons.schedule_rounded, const Color(0xFF1E58C1)),
                      _buildStatGridCard('Rata-rata', '4.2 Jam', 'Sangat Produktif', Icons.insights_rounded, const Color(0xFF6B3BC7)),
                      _buildStatGridCard('Selesai', '80%', '12 dari 15 target', Icons.check_circle_rounded, const Color(0xFF2E7D32)),
                      _buildStatGridCard('Poin XP', '2,450 XP', 'Level 5 Pelajar', Icons.stars_rounded, Colors.orange),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Visual Activity Bar Chart Container
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(5),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Aktivitas Belajar (Menit)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Custom Painted/Drawn Vertical Bars
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _buildBarChartColumn('Sen', 120, 0.5),
                              _buildBarChartColumn('Sel', 180, 0.75),
                              _buildBarChartColumn('Rab', 240, 1.0),
                              _buildBarChartColumn('Kam', 150, 0.6),
                              _buildBarChartColumn('Jum', 90, 0.35),
                              _buildBarChartColumn('Sab', 45, 0.18),
                              _buildBarChartColumn('Min', 0, 0.0),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 85),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatGridCard(String title, String val, String sub, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary,
                  ),
                ),
                Icon(icon, color: color, size: 20),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  val,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sub,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChartColumn(String day, int val, double ratio) {
    return Column(
      children: [
        Text(
          val > 0 ? '$val' : '-',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 14,
          height: 120 * ratio + 8, // scale height dynamically
          decoration: BoxDecoration(
            gradient: ratio > 0
                ? const LinearGradient(
                    colors: [
                      AppColors.primaryGradientStart,
                      AppColors.primaryGradientEnd,
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  )
                : null,
            color: ratio > 0 ? null : AppColors.progressTrack,
            borderRadius: BorderRadius.circular(100),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          day,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppColors.textLight,
          ),
        ),
      ],
    );
  }

  // --- SCREEN 5: PROFIL ---
  Widget _buildProfil(BuildContext context, bool isTablet) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Profil Saya',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Avatar & Credentials Card
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(5),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 28.0, horizontal: 20.0),
                      child: Column(
                        children: [
                          // Glassmorphic Gradient Avatar
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.primaryGradientStart,
                                  AppColors.primaryGradientEnd,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryGradientStart.withAlpha(60),
                                  blurRadius: 15,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                'AR',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Alex Rivers',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'alex.rivers@university.edu',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2EDF9),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: const Text(
                              'NIM 22091020304 • Ilmu Komputer',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primaryGradientStart,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Option Settings List
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(5),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          _buildProfileOption(Icons.person_outline_rounded, 'Informasi Akun', 'Edit biodata dan nim mahasiswa'),
                          _buildProfileOption(Icons.track_changes_rounded, 'Target Jam Belajar', '15 jam per minggu aktif'),
                          _buildProfileOption(Icons.language_rounded, 'Bahasa Utama', 'Bahasa Indonesia'),
                          _buildProfileOption(Icons.security_rounded, 'Keamanan Akun', 'Sandi & Otentikasi dua arah'),
                          _buildProfileOption(Icons.info_outline_rounded, 'Tentang StudyMate AI', 'Info rilis aplikasi v1.0.0'),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Functional Log Out Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: TextButton(
                      onPressed: () {
                        // Smooth navigation transition back to LoginPage
                        Navigator.of(context).pushReplacement(
                          PageRouteBuilder(
                            pageBuilder: (context, animation, secondaryAnimation) => const LoginPage(),
                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                              return FadeTransition(opacity: animation, child: child);
                            },
                            transitionDuration: const Duration(milliseconds: 500),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.red.withAlpha(15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: Colors.redAccent, width: 1.5),
                        ),
                      ),
                      child: const Text(
                        'Keluar dari Akun',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileOption(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.progressTrack,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.primaryGradientStart, size: 18),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.textLight,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textLight, size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: () {},
    );
  }
}
