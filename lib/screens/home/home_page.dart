import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/theme_context.dart';
import '../auth/login_page.dart';
import '../ai_tutor/ai_tutor_page.dart';
import '../materials/materials_page.dart';
import '../materials/material_detail_page.dart';
import '../profile/edit_profile_page.dart';
import '../../models/material_model.dart';
import '../../providers/statistics_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/learning_provider.dart';
import '../notification/notification_page.dart';

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
        final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
        final learningProvider = Provider.of<LearningProvider>(context, listen: false);
        final uid = authProvider.currentUser.uid;
        if (uid.isNotEmpty) {
          statsProvider.initStatistics(uid);
          notificationProvider.initNotifications(uid);
          learningProvider.initLearning(uid);
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              context.colors.bgGradientStart,
              context.colors.bgGradientEnd,
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
                            color: context.colors.glassBg,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: context.colors.glassBorder,
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
        ? context.colors.primaryGradientStart
        : context.colors.textLight.withAlpha(180);

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
          SizedBox(height: 4),
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
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final learningProvider = Provider.of<LearningProvider>(context);
    final user = authProvider.currentUser;

    return Consumer<StatisticsProvider>(
      builder: (context, statsProvider, child) {
        // Handle loading state gracefully
        if (statsProvider.isLoading && statsProvider.activities.isEmpty) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(context.colors.primaryGradientStart),
            ),
          );
        }

        // Handle error state gracefully in Indonesian
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
                      Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
                      SizedBox(height: 16),
                      Text(
                        statsProvider.errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: context.colors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () => statsProvider.refreshStatistics(user.uid),
                        icon: Icon(Icons.refresh_rounded),
                        label: Text('Coba Lagi'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.colors.primaryGradientStart,
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

        final double quizProgress = (statsProvider.weeklyQuizTarget > 0 
            ? statsProvider.quizzesCompletedThisWeek / statsProvider.weeklyQuizTarget 
            : 0.0).clamp(0.0, 1.0);

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
          final match = learningProvider.materials.firstWhere(
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

        // Fallback to top 3 dynamic materials if empty
        final displayList = recentlyOpened.isNotEmpty
            ? recentlyOpened.take(3).toList()
            : (learningProvider.materials.isNotEmpty 
                ? learningProvider.materials.take(3).toList()
                : MaterialModel.dummyMaterials.take(3).toList());

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
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.displayName.isNotEmpty
                                      ? 'Hai, ${user.displayName} 👋'
                                      : 'Hai, Alex Rivers 👋',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: context.colors.textPrimary,
                                    letterSpacing: -0.5,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  "Mari jelajahi belajarmu hari ini",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: context.colors.textSecondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 16),
                          // Glassmorphic Notification Button
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const NotificationPage(),
                              ),
                            ),
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
                                      color: context.colors.glassBg,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: context.colors.glassBorder,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Icon(
                                          Icons.notifications_none_outlined,
                                          color: context.colors.textPrimary,
                                          size: 22,
                                        ),
                                        if (notificationProvider.unreadCount > 0)
                                          Positioned(
                                            top: 6,
                                            right: 6,
                                            child: Container(
                                              padding: const EdgeInsets.all(3),
                                              decoration: BoxDecoration(
                                                color: Colors.redAccent,
                                                shape: BoxShape.circle,
                                              ),
                                              constraints: const BoxConstraints(
                                                minWidth: 16,
                                                minHeight: 16,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  '${notificationProvider.unreadCount}',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 8,
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
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

                      SizedBox(height: 24),

                      // 2. Weekly Progress Card (Interactive!)
                      GestureDetector(
                        onTap: () => _showTargetSettingsDialog(context, user.uid, statsProvider),
                        child: Container(
                          decoration: BoxDecoration(
                            color: context.colors.cardBg,
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
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  'Progres Target Mingguan',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w800,
                                                    color: context.colors.textPrimary,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              SizedBox(width: 6),
                                              Icon(Icons.edit_rounded, size: 14, color: context.colors.primaryGradientStart),
                                            ],
                                          ),
                                          SizedBox(height: 6),
                                          Text(
                                            "Ketuk untuk menyesuaikan target mingguan kuis kamu.",
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: context.colors.textSecondary,
                                              height: 1.3,
                                            ),
                                          ),
                                          SizedBox(height: 12),
                                          Text(
                                            '${statsProvider.quizzesCompletedThisWeek} kuis / ${statsProvider.weeklyQuizTarget} kuis selesai',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                              color: context.colors.primaryGradientStart,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        SizedBox(
                                          width: 72,
                                          height: 72,
                                          child: CircularProgressIndicator(
                                            value: quizProgress,
                                            strokeWidth: 8,
                                            backgroundColor: context.colors.progressTrack,
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              context.colors.primaryGradientStart,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '${statsProvider.learningProgressPercentage}%',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w900,
                                            color: context.colors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                                SizedBox(height: 20),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.center,
                                  child: SizedBox(
                                    width: constraints.maxWidth - 48,
                                    child: Row(
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
                                                    ? LinearGradient(
                                                        colors: [
                                                          context.colors.primaryGradientStart,
                                                          context.colors.primaryGradientEnd,
                                                        ],
                                                      )
                                                    : null,
                                                color: done ? null : context.colors.progressTrack,
                                              ),
                                              child: Center(
                                                child: Icon(
                                                  Icons.check,
                                                  color: done ? Colors.white : Colors.transparent,
                                                  size: 14,
                                                ),
                                              ),
                                            ),
                                            SizedBox(height: 6),
                                            Text(
                                              dayData['day'] as String,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                                color: done
                                                    ? context.colors.primaryGradientStart
                                                    : context.colors.textLight,
                                              ),
                                            )
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 28),

                      // 3. AI Tutor CTA Card
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              context.colors.primaryGradientStart,
                              context.colors.primaryGradientEnd,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: context.colors.primaryGradientStart.withAlpha(76),
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
                                  SizedBox(height: 12),
                                  Text(
                                    'Tanya StudyMate AI',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Tanyakan apa saja, ringkas materi, atau buat kuis secara instan!',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white.withAlpha(220),
                                      height: 1.4,
                                    ),
                                  ),
                                  SizedBox(height: 24),
                                  ElevatedButton(
                                    onPressed: () {
                                      // Switch to AI Tutor Tab (Index 2)
                                      setState(() {
                                        _currentIndex = 2;
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: context.colors.primaryGradientStart,
                                      elevation: 4,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 32,
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(100),
                                      ),
                                    ),
                                    child: Text(
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

                      SizedBox(height: 28),

                      // 4. Lanjutkan Belajar Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Lanjutkan Belajar',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: context.colors.textPrimary,
                                letterSpacing: -0.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 16),
                          GestureDetector(
                            onTap: () {
                              // Switch to Materi Tab (Index 1)
                              setState(() {
                                _currentIndex = 1;
                              });
                            },
                            child: Text(
                              'Lihat Semua',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: context.colors.primaryGradientStart,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 16),

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
                            final bgColor = material.color.withAlpha(30);
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
                                  color: context.colors.cardBg,
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
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              material.category,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                                color: context.colors.textSecondary,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        material.title,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: context.colors.textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: 6),
                                      Text(
                                        material.modules,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: context.colors.textLight,
                                        ),
                                      ),
                                      const Spacer(),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Container(
                                              height: 6,
                                              decoration: BoxDecoration(
                                                color: context.colors.progressTrack,
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
                                          SizedBox(width: 10),
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
                      SizedBox(height: 85),
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
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(context.colors.primaryGradientStart),
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
                      Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
                      SizedBox(height: 16),
                      Text(
                        statsProvider.errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: context.colors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () => statsProvider.refreshStatistics(uid),
                        icon: Icon(Icons.refresh_rounded),
                        label: Text('Coba Lagi'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.colors.primaryGradientStart,
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
                      Text(
                        'Statistik Belajar',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: context.colors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Pantau performa dan jam belajar mingguanmu',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: context.colors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 24),

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

                      SizedBox(height: 28),

                      // Visual Activity Bar Chart Container
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: context.colors.cardBg,
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
                              Text(
                                'Aktivitas Belajar (Frekuensi)',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: context.colors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 24),
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
                      SizedBox(height: 85),
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
        color: context.colors.cardBg,
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
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: context.colors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 4),
                Icon(icon, color: color, size: 20),
              ],
            ),
            SizedBox(height: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      val,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: context.colors.textPrimary,
                      ),
                    ),
                  ),
                  SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      sub,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: context.colors.textLight,
                      ),
                    ),
                  ),
                ],
              ),
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
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: context.colors.textSecondary,
          ),
        ),
        SizedBox(height: 8),
        Container(
          width: 14,
          height: 120 * ratio + 8, // scale height dynamically
          decoration: BoxDecoration(
            gradient: ratio > 0
                ? LinearGradient(
                    colors: [
                      context.colors.primaryGradientStart,
                      context.colors.primaryGradientEnd,
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  )
                : null,
            color: ratio > 0 ? null : context.colors.progressTrack,
            borderRadius: BorderRadius.circular(100),
          ),
        ),
        SizedBox(height: 8),
        Text(
          day,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: context.colors.textLight,
          ),
        ),
      ],
    );
  }

  // --- SCREEN 5: PROFIL ---
  Widget _buildProfil(BuildContext context, bool isTablet) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final user = authProvider.currentUser;
    final String initials = user.displayName.isNotEmpty
        ? user.displayName
            .trim()
            .split(' ')
            .where((String e) => e.isNotEmpty)
            .map((e) => e[0])
            .take(2)
            .join()
            .toUpperCase()
        : 'U';

    String themeName = 'Sistem';
    if (themeProvider.themeMode == ThemeMode.light) {
      themeName = 'Terang';
    } else if (themeProvider.themeMode == ThemeMode.dark) {
      themeName = 'Gelap';
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Profil Saya',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: context.colors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  SizedBox(height: 24),

                  // Avatar & Credentials Card
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: context.colors.cardBg,
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
                              gradient: LinearGradient(
                                colors: [
                                  context.colors.primaryGradientStart,
                                  context.colors.primaryGradientEnd,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: context.colors.primaryGradientStart.withAlpha(60),
                                  blurRadius: 15,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                initials,
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            user.displayName.isNotEmpty ? user.displayName : 'Tanpa Nama',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: context.colors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            user.email.isNotEmpty ? user.email : 'Email tidak tersedia',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: context.colors.textSecondary,
                            ),
                          ),
                          SizedBox(height: 8),
                          if (user.nim != null || user.major != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: context.colors.primaryGradientStart.withAlpha(30),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                '${user.nim != null ? "NIM ${user.nim}" : ""} ${(user.nim != null && user.major != null) ? "•" : ""} ${user.major ?? ""}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: context.colors.primaryGradientStart,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 24),

                  // Option Settings List
                  Container(
                    decoration: BoxDecoration(
                      color: context.colors.cardBg,
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
                            icon: Icons.dark_mode_outlined,
                            title: 'Tema Aplikasi',
                            subtitle: themeName,
                            onTap: () => _showThemeSelector(context),
                          ),
                          _buildProfileOption(
                            icon: Icons.info_outline_rounded, 
                            title: 'Tentang StudyMate AI', 
                            subtitle: 'Info rilis aplikasi v1.0.0',
                          ),
                          _buildProfileOption(
                            icon: Icons.delete_outline_rounded,
                            title: 'Hapus Akun Saya',
                            subtitle: 'Hapus akun dan data secara permanen',
                            iconColor: Colors.redAccent,
                            textColor: Colors.redAccent,
                            onTap: () => _confirmDeleteAccount(context),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 24),

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
                          side: BorderSide(color: Colors.redAccent, width: 1.5),
                        ),
                      ),
                      child: Text(
                        'Keluar dari Akun',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 100),
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
    Color? iconColor,
    Color? textColor,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor != null ? iconColor.withAlpha(20) : context.colors.progressTrack,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor ?? context.colors.primaryGradientStart, size: 18),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: textColor ?? context.colors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: context.colors.textLight,
        ),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: context.colors.textLight, size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: onTap,
    );
  }

  void _showThemeSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 40,
                    offset: const Offset(0, -10),
                  ),
                ],
              ),
              padding: const EdgeInsets.only(
                top: 16,
                left: 24,
                right: 24,
                bottom: 40,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // HandleBar drag indicator
                  Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withAlpha(50)
                          : Colors.black.withAlpha(30),
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Pilih Tema Aplikasi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: context.colors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Pilih tampilan yang paling nyaman untuk matamu.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: context.colors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 24),
                  
                  // Options
                  _buildThemeOptionTile(
                    context: context,
                    icon: Icons.light_mode_rounded,
                    title: 'Terang (Light)',
                    isSelected: themeProvider.themeMode == ThemeMode.light,
                    onTap: () {
                      themeProvider.setThemeMode(ThemeMode.light);
                      Navigator.pop(context);
                    },
                  ),
                  SizedBox(height: 12),
                  _buildThemeOptionTile(
                    context: context,
                    icon: Icons.dark_mode_rounded,
                    title: 'Gelap (Dark)',
                    isSelected: themeProvider.themeMode == ThemeMode.dark,
                    onTap: () {
                      themeProvider.setThemeMode(ThemeMode.dark);
                      Navigator.pop(context);
                    },
                  ),
                  SizedBox(height: 12),
                  _buildThemeOptionTile(
                    context: context,
                    icon: Icons.settings_brightness_rounded,
                    title: 'Sistem (System)',
                    isSelected: themeProvider.themeMode == ThemeMode.system,
                    onTap: () {
                      themeProvider.setThemeMode(ThemeMode.system);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildThemeOptionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? context.colors.primaryGradientStart.withAlpha(20)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? context.colors.primaryGradientStart
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? context.colors.primaryGradientStart
                  : context.colors.textPrimary,
              size: 22,
            ),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                  color: isSelected
                      ? context.colors.primaryGradientStart
                      : context.colors.textPrimary,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: context.colors.primaryGradientStart,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: context.colors.cardBg.withAlpha(240),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: context.colors.glassBorder, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(15),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.all(28.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withAlpha(20),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.redAccent,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Konfirmasi Hapus Akun',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: context.colors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Text(
                      'Data Anda akan dihapus permanen termasuk chat, progres, dan kuis. Apakah Anda yakin?',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: context.colors.textSecondary,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.start,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                          child: Text(
                            'Batal',
                            style: TextStyle(
                              color: context.colors.textSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                            _deleteAccount(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                          child: const Text(
                            'Hapus',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
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

  Future<void> _deleteAccount(BuildContext context) async {
    HapticFeedback.heavyImpact();
    
    // Show premium glassmorphic loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: context.colors.cardBg.withAlpha(240),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: context.colors.glassBorder, width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(context.colors.primaryGradientStart),
                ),
                const SizedBox(height: 16),
                Text(
                  'Menghapus Akun...',
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.deleteAccount();

    if (context.mounted) {
      // Dismiss loading dialog
      Navigator.of(context).pop();

      if (success) {
        // Show success snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Akun dan semua data berhasil dihapus'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Transition smoothly to LoginPage
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const LoginPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Terjadi kesalahan saat menghapus akun.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showTargetSettingsDialog(BuildContext context, String uid, StatisticsProvider statsProvider) {
    int tempTarget = statsProvider.weeklyQuizTarget;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                constraints: const BoxConstraints(maxWidth: 400),
                decoration: BoxDecoration(
                  color: context.colors.cardBg.withAlpha(240),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: context.colors.glassBorder, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(15),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: Padding(
                    padding: const EdgeInsets.all(28.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Atur Target Belajar',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: context.colors.textPrimary,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.close_rounded, color: context.colors.textLight),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                        Divider(height: 24),
                        Text(
                          'Tentukan berapa banyak kuis yang ingin kamu selesaikan setiap minggunya untuk tetap konsisten belajar.',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: context.colors.textSecondary,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (tempTarget > 1) {
                                  setDialogState(() {
                                    tempTarget--;
                                  });
                                }
                              },
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: context.colors.progressTrack,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.remove_rounded, color: context.colors.primaryGradientStart, size: 24),
                              ),
                            ),
                            SizedBox(width: 24),
                            Text(
                              '$tempTarget',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: context.colors.textPrimary,
                              ),
                            ),
                            SizedBox(width: 24),
                            GestureDetector(
                              onTap: () {
                                if (tempTarget < 50) {
                                  setDialogState(() {
                                    tempTarget++;
                                  });
                                }
                              },
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: context.colors.progressTrack,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.add_rounded, color: context.colors.primaryGradientStart, size: 24),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Kuis per minggu',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: context.colors.textLight,
                          ),
                        ),
                        SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () async {
                              await statsProvider.updateWeeklyTarget(uid, tempTarget);
                              if (context.mounted) {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Target kuis mingguan berhasil diperbarui! 🎯'),
                                    backgroundColor: Colors.green,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.colors.primaryGradientStart,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              'Simpan Target',
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
      },
    );
  }
}
