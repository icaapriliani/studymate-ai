import 'dart:ui';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

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
              // Main Scrollable Content
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Center(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 600),
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 32.0 : 20.0,
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
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            border: Border.all(
                                              color: AppColors.glassBorder,
                                              width: 1.5,
                                            ),
                                          ),
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              const Icon(
                                                Icons
                                                    .notifications_none_outlined,
                                                color: AppColors.textPrimary,
                                                size: 22,
                                              ),
                                              // Red active dot
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
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
                                                    color:
                                                        AppColors.textSecondary,
                                                    height: 1.3,
                                                  ),
                                                ),
                                                SizedBox(height: 12),
                                                Text(
                                                  '12j / 15j selesai',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w800,
                                                    color: AppColors
                                                        .primaryGradientStart,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          // Animated circular indicator
                                          Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              SizedBox(
                                                width: 72,
                                                height: 72,
                                                child: CircularProgressIndicator(
                                                  value: 0.8,
                                                  strokeWidth: 8,
                                                  backgroundColor:
                                                      AppColors.progressTrack,
                                                  valueColor:
                                                      const AlwaysStoppedAnimation<
                                                          Color>(
                                                    AppColors
                                                        .primaryGradientStart,
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
                                      // Daily checklist badges
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
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
                                                            AppColors
                                                                .primaryGradientStart,
                                                            AppColors
                                                                .primaryGradientEnd,
                                                          ],
                                                        )
                                                      : null,
                                                  color: done
                                                      ? null
                                                      : AppColors.progressTrack,
                                                ),
                                                child: Center(
                                                  child: Icon(
                                                    Icons.check,
                                                    color: done
                                                        ? Colors.white
                                                        : Colors.transparent,
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
                                                      ? AppColors
                                                          .primaryGradientStart
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
                                      color: AppColors.primaryGradientStart
                                          .withAlpha(76),
                                      blurRadius: 25,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  children: [
                                    // Abstract floating glowing star graphics in background
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                              color:
                                                  Colors.white.withAlpha(220),
                                              height: 1.4,
                                            ),
                                          ),
                                          const SizedBox(height: 24),
                                          ElevatedButton(
                                            onPressed: () {
                                              // Handle navigation to AI Chat
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.white,
                                              foregroundColor: AppColors
                                                  .primaryGradientStart,
                                              elevation: 4,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 32,
                                                vertical: 14,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(100),
                                              ),
                                            ),
                                            child: const Text(
                                              'Start Chatting',
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

                              // 4. Continue Learning Header
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                      // View all action
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
                                      margin: EdgeInsets.only(
                                        right: 16,
                                        left: index == 0 ? 0 : 0,
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                // Pastel circular icon badge
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
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: AppColors
                                                          .textSecondary,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
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
                                            // Progress bar
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Container(
                                                    height: 6,
                                                    decoration: BoxDecoration(
                                                      color: AppColors
                                                          .progressTrack,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              100),
                                                    ),
                                                    child: ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              100),
                                                      child:
                                                          LinearProgressIndicator(
                                                        value:
                                                            course['progress'],
                                                        backgroundColor:
                                                            Colors.transparent,
                                                        valueColor:
                                                            AlwaysStoppedAnimation<
                                                                Color>(
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
                              // Spacer for floating bottom bar padding
                              const SizedBox(height: 85),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
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
                              _buildNavItem(
                                  1, Icons.auto_awesome_rounded, 'AI Tutor'),
                              _buildNavItem(2, Icons.folder_rounded, 'Materi'),
                              _buildNavItem(3, Icons.person_rounded, 'Profil'),
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
}
