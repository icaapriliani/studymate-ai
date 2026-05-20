import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_page.dart';
import '../ai_tutor/ai_tutor_page.dart';
import '../materials/materials_page.dart';
import '../materials/material_detail_page.dart';
import '../profile/edit_profile_page.dart';
import '../../models/material_model.dart';
import '../../providers/statistics_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final statsProvider = Provider.of<StatisticsProvider>(context, listen: false);
        final uid = authProvider.currentUser.uid;
        if (uid.isNotEmpty) {
          statsProvider.initStatistics(uid);
        }
      }
    });
  }


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
                    MaterialsPage(
                      onTanyaAI: () {
                        setState(() {
                          _currentIndex = 2; // Switch to AI Tutor
                        });
                      },
                    ),
                    const AITutorPage(showBackButton: false, bottomPadding: 80.0),
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
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Consumer<StatisticsProvider>(
      builder: (context, statsProvider, child) {
        final int weeklyTotal = statsProvider.getWeeklyTotalActivities();
        final double estimatedHours = weeklyTotal * 1.5;
        final int targetHours = user.studyTargetHours ?? 15;
        final double progress = (estimatedHours / targetHours).clamp(0.0, 1.0);

        final weeklyCounts = statsProvider.getWeeklyActivityCounts();
        final daysList = [
          {'day': 'S', 'done': weeklyCounts[0] > 0}, // Senin
          {'day': 'S', 'done': weeklyCounts[1] > 0}, // Selasa
          {'day': 'R', 'done': weeklyCounts[2] > 0}, // Rabu
          {'day': 'K', 'done': weeklyCounts[3] > 0}, // Kamis
          {'day': 'J', 'done': weeklyCounts[4] > 0}, // Jumat
          {'day': 'S', 'done': weeklyCounts[5] > 0}, // Sabtu
          {'day': 'M', 'done': weeklyCounts[6] > 0}, // Minggu
        ];

        // Filter activities belonging to type "material"
        final materialActivities = statsProvider.activities
            .where((a) => a.type == 'material')
            .toList();

        // Extract unique materials in order of activity timestamp (descending)
        final List<MaterialModel> recentlyOpened = [];
        final Set<String> addedTitles = {};

        for (final act in materialActivities) {
          final match = MaterialModel.dummyMaterials.firstWhere(
            (mat) => mat.title.trim().toLowerCase() == act.title.trim().toLowerCase(),
            orElse: () => const MaterialModel(
              id: '',
              title: '',
              modules: '',
              description: '',
              keyPoints: [],
              sampleQuestions: [],
              progress: 0.0,
              estimatedTime: '',
              color: Colors.grey,
              category: '',
            ),
          );
          if (match.id.isNotEmpty && !addedTitles.contains(match.title)) {
            recentlyOpened.add(match);
            addedTitles.add(match.title);
          }
        }

        // Fallback to top 3 dummy materials if empty
        final displayList = recentlyOpened.isNotEmpty
            ? recentlyOpened.take(3).toList()
            : MaterialModel.dummyMaterials.take(3).toList();

        IconData getIconForCategory(String category) {
          switch (category.toLowerCase()) {
            case 'kecerdasan buatan':
              return Icons.psychology_rounded;
            case 'ilmu komputer':
              return Icons.storage_rounded;
            case 'bahasa':
            case 'bahasa & penelitian':
              return Icons.history_edu_rounded;
            default:
              return Icons.menu_book_rounded;
          }
        }

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
                            children: [
                              Text(
                                user.displayName.isNotEmpty
                                    ? 'Hai, ${user.displayName} 👋'
                                    : 'Hai, Alex Rivers 👋',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
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
                          GestureDetector(
                            onTap: () => _showNotificationDialog(context),
                            child: Container(
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
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // 2. Weekly Progress Card
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _currentIndex = 3; // Switch to Statistik Tab
                          });
                        },
                        child: Container(
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
                                        children: [
                                          const Text(
                                            'Progres Target Mingguan',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          const Text(
                                            "Semangat! Kamu hampir mencapai target minggu ini.",
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.textSecondary,
                                              height: 1.3,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            '${estimatedHours.toStringAsFixed(1)}j / ${targetHours}j selesai',
                                            style: const TextStyle(
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
                                            value: progress,
                                            strokeWidth: 8,
                                            backgroundColor: AppColors.progressTrack,
                                            valueColor: const AlwaysStoppedAnimation<Color>(
                                              AppColors.primaryGradientStart,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '${(progress * 100).round()}%',
                                          style: const TextStyle(
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
                                  children: daysList.map((dayData) {
                                    final bool done = dayData['done'] as bool;
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
                                          dayData['day'] as String,
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
                          itemCount: displayList.length,
                          itemBuilder: (context, index) {
                            final material = displayList[index];
                            final iconColor = material.color;
                            final bgColor = material.color.withOpacity(0.12);
                            final icon = getIconForCategory(material.category);

                            return GestureDetector(
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (context, animation, secondaryAnimation) =>
                                        MaterialDetailPage(material: material),
                                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                      return FadeTransition(opacity: animation, child: child);
                                    },
                                    transitionDuration: const Duration(milliseconds: 300),
                                  ),
                                );
                                if (result == 'tanya_ai') {
                                  setState(() {
                                    _currentIndex = 2; // Switch to AI Tutor
                                  });
                                }
                              },
                              child: Container(
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
                                              color: bgColor,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              icon,
                                              color: iconColor,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              material.category,
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
                                        material.title,
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
                                        material.modules,
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
                                                  value: material.progress,
                                                  backgroundColor: Colors.transparent,
                                                  valueColor: AlwaysStoppedAnimation<Color>(
                                                    iconColor,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            '${(material.progress * 100).round()}%',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w900,
                                              color: iconColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
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
      },
    );
  }

  // --- SCREEN 4: STATISTIK ---
  Widget _buildStatistik(BuildContext context, bool isTablet) {
    final authProvider = Provider.of<AuthProvider>(context);
    final uid = authProvider.currentUser.uid;

    return Consumer<StatisticsProvider>(
      builder: (context, statsProvider, child) {
        // If loading and no data exists yet, show a clean, modern progress indicator
        if (statsProvider.isLoading && statsProvider.activities.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGradientStart),
            ),
          );
        }

        // If there's an error and no data, show a beautiful error card with a retry button
        if (statsProvider.errorMessage != null && statsProvider.activities.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        statsProvider.errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () => statsProvider.refreshStatistics(uid),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Coba Lagi'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGradientStart,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        final weeklyCounts = statsProvider.getWeeklyActivityCounts();
        final maxCount = weeklyCounts.reduce((max, element) => element > max ? element : max);

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
                          _buildStatGridCard(
                            'Percakapan AI',
                            '${statsProvider.totalConversations}',
                            'Obrolan Tutor AI',
                            Icons.forum_rounded,
                            const Color(0xFF1E58C1),
                          ),
                          _buildStatGridCard(
                            'Total Pesan',
                            '${statsProvider.totalPesan}',
                            'Tanya & Jawab AI',
                            Icons.question_answer_rounded,
                            const Color(0xFF6B3BC7),
                          ),
                          _buildStatGridCard(
                            'Materi Dibuka',
                            '${statsProvider.totalMateriDibuka}',
                            'Materi Pelajaran',
                            Icons.menu_book_rounded,
                            const Color(0xFF2E7D32),
                          ),
                          _buildStatGridCard(
                            'Total Aktivitas',
                            '${statsProvider.activities.length}',
                            'Aktivitas Belajar',
                            Icons.insights_rounded,
                            Colors.orange,
                          ),
                          _buildStatGridCard(
                            'Kuis Selesai',
                            '${statsProvider.totalQuizTaken}',
                            'Total Kuis',
                            Icons.quiz_rounded,
                            const Color(0xFFE91E63),
                          ),
                          _buildStatGridCard(
                            'Rata-rata Skor',
                            '${statsProvider.averageQuizScore}',
                            'Skor Kuis',
                            Icons.score_rounded,
                            const Color(0xFF009688),
                          ),
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
                                'Aktivitas Belajar (Frekuensi)',
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
                                  _buildBarChartColumn('Sen', weeklyCounts[0], maxCount > 0 ? weeklyCounts[0] / maxCount : 0.0),
                                  _buildBarChartColumn('Sel', weeklyCounts[1], maxCount > 0 ? weeklyCounts[1] / maxCount : 0.0),
                                  _buildBarChartColumn('Rab', weeklyCounts[2], maxCount > 0 ? weeklyCounts[2] / maxCount : 0.0),
                                  _buildBarChartColumn('Kam', weeklyCounts[3], maxCount > 0 ? weeklyCounts[3] / maxCount : 0.0),
                                  _buildBarChartColumn('Jum', weeklyCounts[4], maxCount > 0 ? weeklyCounts[4] / maxCount : 0.0),
                                  _buildBarChartColumn('Sab', weeklyCounts[5], maxCount > 0 ? weeklyCounts[5] / maxCount : 0.0),
                                  _buildBarChartColumn('Min', weeklyCounts[6], maxCount > 0 ? weeklyCounts[6] / maxCount : 0.0),
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
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final String initials = user.displayName.isNotEmpty
        ? user.displayName
            .trim()
            .split(' ')
            .where((e) => e.isNotEmpty)
            .map((e) => e[0])
            .take(2)
            .join()
            .toUpperCase()
        : 'U';

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
                            child: Center(
                              child: Text(
                                initials,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            user.displayName.isNotEmpty ? user.displayName : 'Tanpa Nama',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.email.isNotEmpty ? user.email : 'Email tidak tersedia',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (user.nim != null || user.major != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE2EDF9),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                '${user.nim != null ? "NIM ${user.nim}" : ""} ${(user.nim != null && user.major != null) ? "•" : ""} ${user.major ?? ""}',
                                style: const TextStyle(
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
                          _buildProfileOption(
                            icon: Icons.person_outline_rounded, 
                            title: 'Informasi Akun', 
                            subtitle: 'Edit biodata dan nim mahasiswa',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const EditProfilePage()),
                              );
                            }
                          ),
                          _buildProfileOption(
                            icon: Icons.track_changes_rounded, 
                            title: 'Target Jam Belajar', 
                            subtitle: '${user.studyTargetHours ?? 15} jam per minggu aktif',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const EditProfilePage()),
                              );
                            }
                          ),
                          _buildProfileOption(
                            icon: Icons.security_rounded, 
                            title: 'Keamanan Akun', 
                            subtitle: 'Ubah kata sandi',
                            onTap: () async {
                              if (user.email.isEmpty) return;
                              final success = await authProvider.resetPassword(user.email);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(success 
                                      ? 'Tautan atur ulang kata sandi telah dikirim ke ${user.email}' 
                                      : (authProvider.errorMessage ?? 'Gagal mengirim email reset')),
                                    backgroundColor: success ? Colors.green : Colors.red,
                                  ),
                                );
                              }
                            }
                          ),
                          _buildProfileOption(
                            icon: Icons.info_outline_rounded, 
                            title: 'Tentang StudyMate AI', 
                            subtitle: 'Info rilis aplikasi v1.0.0',
                          ),
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
                      onPressed: () async {
                        // Perform real sign out from Firebase
                        await authProvider.signOut();
                        
                        if (context.mounted) {
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
                        }
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

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
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
      onTap: onTap,
    );
  }

  void _showNotificationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(235),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(20),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.notifications_active_rounded, color: AppColors.primaryGradientStart, size: 24),
                            SizedBox(width: 10),
                            Text(
                              'Notifikasi',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppColors.textLight),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const Divider(height: 24, thickness: 1),
                    _buildNotifItem(
                      icon: Icons.auto_awesome_rounded,
                      color: const Color(0xFF6B3BC7),
                      title: 'Jawaban Tutor AI Baru!',
                      desc: 'Tutor AI baru saja merespons pertanyaan Anda tentang DBMS.',
                      time: 'Baru saja',
                    ),
                    const SizedBox(height: 12),
                    _buildNotifItem(
                      icon: Icons.stars_rounded,
                      color: Colors.orange,
                      title: 'Prestasi Baru Diraih!',
                      desc: 'Selamat! Anda telah konsisten belajar selama 3 hari berturut-turut.',
                      time: '2 jam yang lalu',
                    ),
                    const SizedBox(height: 12),
                    _buildNotifItem(
                      icon: Icons.quiz_rounded,
                      color: const Color(0xFF2E7D32),
                      title: 'Kuis Mingguan Tersedia',
                      desc: 'Uji pemahaman Anda tentang Basis Data dengan kuis terbaru.',
                      time: '1 hari yang lalu',
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGradientStart,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Tutup',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotifItem({
    required IconData icon,
    required Color color,
    required String title,
    required String desc,
    required String time,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                desc,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                time,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
