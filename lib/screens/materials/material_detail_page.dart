import 'package:flutter/material.dart';
import '../../utils/theme_context.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/material_model.dart';
import '../../models/module_model.dart';
import '../../providers/ai_chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/statistics_provider.dart';
import '../../providers/learning_provider.dart';
import '../quiz/quiz_session_list_page.dart';
import 'module_detail_page.dart';

class MaterialDetailPage extends StatefulWidget {
  final MaterialModel material;

  const MaterialDetailPage({
    super.key,
    required this.material,
  });

  @override
  State<MaterialDetailPage> createState() => _MaterialDetailPageState();
}

class _MaterialDetailPageState extends State<MaterialDetailPage> {
  // Keeps track of which sample questions are expanded in our interactive accordion
  final Map<int, bool> _expandedQuestions = {};

  @override
  void initState() {
    super.initState();
    // Initially, all accordion questions are collapsed
    for (int i = 0; i < widget.material.sampleQuestions.length; i++) {
      _expandedQuestions[i] = false;
    }

    // Record "material" opened activity dynamically
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final statsProvider = Provider.of<StatisticsProvider>(context, listen: false);
        final uid = authProvider.currentUser.uid;
        if (uid.isNotEmpty) {
          statsProvider.saveActivity(uid, 'material', widget.material.title);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final learningProvider = Provider.of<LearningProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final uid = authProvider.currentUser.uid;
    
    // Find the latest state of this material from provider to ensure perfectly synced progress ratios.
    final mat = learningProvider.materials.firstWhere(
      (m) => m.id == widget.material.id,
      orElse: () => widget.material,
    );

    final modules = learningProvider.allModules[mat.id] ?? [];
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
          child: Column(
            children: [
              // 1. Sleek Navigation Header
              _buildHeader(context),

              // 2. Scrollable Detail Content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 36.0 : 20.0,
                    vertical: 10.0,
                  ),
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 2a. Premium Title & Metadata Card
                          _buildTitleCard(mat, isTablet),
                          SizedBox(height: 20),

                          // 2b. Progress Visual Card
                          _buildProgressVisualCard(mat),
                          SizedBox(height: 20),

                          // 2c. Complete Description Card
                          _buildSectionTitle('Deskripsi Materi'),
                          SizedBox(height: 10),
                          _buildDescriptionCard(mat),
                          SizedBox(height: 24),

                          // 2c-2. Modul Pembelajaran Checklist
                          _buildSectionTitle('Daftar Modul Pembelajaran'),
                          SizedBox(height: 10),
                          if (modules.isEmpty)
                            _buildEmptyModulesCard(mat, learningProvider.isLoading, uid)
                          else
                            Column(
                              children: modules.map((mod) {
                                final isCompleted = learningProvider.isModuleCompleted(mod.id);
                                return _buildModuleTile(context, mat, mod, isCompleted);
                              }).toList(),
                            ),
                          SizedBox(height: 24),

                          // 2d. Key Points Summary Panel
                          _buildSectionTitle('Poin Ringkasan Akademik'),
                          SizedBox(height: 10),
                          _buildKeyPointsPanel(mat),
                          SizedBox(height: 24),

                          // 2e. Interactive Sample Questions (Accordion)
                          if (mat.sampleQuestions.isNotEmpty) ...[
                            _buildSectionTitle('Latihan Mandiri & Contoh Soal'),
                            SizedBox(height: 4),
                            Text(
                              'Ketuk kartu soal untuk membuka jawaban dan pembahasan',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: context.colors.textSecondary.withAlpha(200),
                              ),
                            ),
                            SizedBox(height: 10),
                            _buildSampleQuestionsAccordion(mat),
                          ],

                          SizedBox(height: 100), // Spacing for floating action button
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      // 3. Floating Bottom Action Button
      bottomNavigationBar: _buildBottomActionBar(context, mat),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: context.colors.textPrimary,
              size: 20,
            ),
          ),
          Text(
            'Detail Materi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: context.colors.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          // Empty placeholder to balance the back button
          SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildTitleCard(MaterialModel mat, bool isTablet) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.colors.cardBg,
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
            // Category tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: mat.color.withAlpha(25),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                mat.category.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: mat.color,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            SizedBox(height: 12),

            // Title
            Text(
              mat.title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: context.colors.textPrimary,
                height: 1.25,
              ),
            ),
            SizedBox(height: 16),

            Divider(color: context.colors.progressTrack, height: 1),
            SizedBox(height: 16),

            // Metadata Row
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.menu_book_rounded, color: mat.color, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cakupan Modul',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: context.colors.textLight,
                              ),
                            ),
                            Text(
                              mat.modules.split(' • ').first,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: context.colors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 32, color: context.colors.progressTrack),
                SizedBox(width: 16),
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.schedule_rounded, color: mat.color, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Estimasi Waktu',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: context.colors.textLight,
                              ),
                            ),
                            Text(
                              mat.estimatedTime,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: context.colors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressVisualCard(MaterialModel mat) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.colors.cardBg,
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
                Text(
                  'Progress Belajar Anda',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: context.colors.textPrimary,
                  ),
                ),
                Text(
                  '${(mat.progress * 100).round()}%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: mat.color,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),

            // Animated Visual Progress Bar with gradient effects
            Container(
              height: 12,
              width: double.infinity,
              decoration: BoxDecoration(
                color: context.colors.progressTrack,
                borderRadius: BorderRadius.circular(100),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: LinearProgressIndicator(
                  value: mat.progress,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(mat.color),
                ),
              ),
            ),
            SizedBox(height: 10),

            // Friendly progress descriptor text
            Text(
              mat.progress == 0.0
                  ? 'Belum dimulai. Mari kita mulai belajar modul ini!'
                  : mat.progress == 1.0
                      ? 'Luar biasa! Materi ini telah selesai Anda pelajari.'
                      : '${mat.modules.split(' • ').last} selesai. Lanjutkan konsistensi belajar Anda!',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionCard(MaterialModel mat) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.colors.cardBg,
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
        child: Text(
          mat.description,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: context.colors.textSecondary,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildKeyPointsPanel(MaterialModel mat) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.colors.cardBg,
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
          children: mat.keyPoints.map((point) {
            final parts = point.split(': ');
            final title = parts.first;
            final body = parts.length > 1 ? parts.last : '';

            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 2.0),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: mat.color.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.star_rounded,
                      color: mat.color,
                      size: 14,
                    ),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 13.5,
                          color: context.colors.textSecondary,
                          height: 1.45,
                        ),
                        children: [
                          TextSpan(
                            text: '$title: ',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: context.colors.textPrimary,
                            ),
                          ),
                          TextSpan(text: body),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSampleQuestionsAccordion(MaterialModel mat) {
    return Column(
      children: List.generate(mat.sampleQuestions.length, (index) {
        final item = mat.sampleQuestions[index];
        final isExpanded = _expandedQuestions[index] ?? false;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: context.colors.cardBg,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                setState(() {
                  _expandedQuestions[index] = !isExpanded;
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'SOAL',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.question,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: context.colors.textPrimary,
                              height: 1.35,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                          color: context.colors.textLight,
                          size: 20,
                        ),
                      ],
                    ),

                    // Expandable Section
                    AnimatedCrossFade(
                      firstChild: SizedBox(width: double.infinity),
                      secondChild: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 16),
                          Divider(color: context.colors.progressTrack, height: 1),
                          SizedBox(height: 16),

                          // Answer Card
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'JAWAB',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item.answer,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: context.colors.textPrimary,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),

                          // Explanation Card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: mat.color.withAlpha(12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: mat.color.withAlpha(20)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.info_outline_rounded, color: mat.color, size: 16),
                                    SizedBox(width: 6),
                                    Text(
                                      'Penjelasan & Konsep',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        color: mat.color,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Text(
                                  item.explanation,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                    color: context.colors.textSecondary,
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 300),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w900,
        color: context.colors.textPrimary,
        letterSpacing: -0.2,
      ),
    );
  }

  Widget _buildBottomActionBar(BuildContext context, MaterialModel mat) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.cardBg.withAlpha(220), // 85% solid background
        border: Border(
          top: BorderSide(
            color: Colors.black.withAlpha(5),
            width: 1.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        context.colors.primaryGradientStart,
                        context.colors.primaryGradientEnd,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: context.colors.primaryGradientStart.withAlpha(80),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        final prompt = 'Jelaskan kembali materi ${mat.title} dengan bahasa sederhana';
                        Provider.of<AIChatProvider>(context, listen: false).setPrefilledPrompt(
                          prompt,
                          title: mat.title,
                          autoSend: true,
                        );
                        Navigator.of(context).pop('tanya_ai');
                      },
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.auto_awesome_rounded, color: context.colors.cardBg, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Tanya AI',
                              style: TextStyle(
                                color: context.colors.cardBg,
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                letterSpacing: 0.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: context.colors.cardBg,
                    border: Border.all(color: context.colors.primaryGradientStart, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: context.colors.primaryGradientStart.withAlpha(20),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => QuizSessionListPage(
                              materialId: mat.id,
                              materialTitle: mat.title,
                            ),
                          ),
                        );
                      },
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.quiz_rounded, color: context.colors.primaryGradientStart, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Mulai Kuis',
                              style: TextStyle(
                                color: context.colors.primaryGradientStart,
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                letterSpacing: 0.1,
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
        ),
      ),
    );
  }

  Widget _buildEmptyModulesCard(MaterialModel mat, bool isLoading, String uid) {
    final learningProvider = Provider.of<LearningProvider>(context, listen: false);
    final errorMessage = learningProvider.errorMessage;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
      decoration: BoxDecoration(
        color: context.colors.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isLoading ? mat.color.withAlpha(20) : Colors.amber.withAlpha(50),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isLoading ? mat.color.withAlpha(12) : Colors.amber.withAlpha(12),
              shape: BoxShape.circle,
            ),
            child: isLoading
                ? SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 3.0,
                      valueColor: AlwaysStoppedAnimation<Color>(mat.color),
                    ),
                  )
                : Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.amber,
                    size: 32,
                  ),
          ),
          SizedBox(height: 16),
          Text(
            isLoading ? 'Menghubungkan Database' : 'Modul Belum Tersedia',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: context.colors.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          SizedBox(height: 6),
          Text(
            isLoading
                ? 'Harap tunggu sebentar, modul akademik sedang disinkronisasikan ke Firestore...'
                : 'Peta pembelajaran modular untuk materi ini belum terdaftar di database.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: context.colors.textSecondary,
              height: 1.4,
            ),
          ),
          if (errorMessage != null && !isLoading) ...[
            SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withAlpha(10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withAlpha(30), width: 1),
              ),
              child: SelectableText(
                'Detail Error Database:\n$errorMessage',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontFamily: 'monospace',
                  color: Colors.red.shade800,
                  height: 1.4,
                ),
              ),
            ),
          ],
          if (!isLoading) ...[
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () async {
                await HapticFeedback.mediumImpact();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.0,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Menjalankan uji koneksi & sinkronisasi database...',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: mat.color,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      duration: const Duration(seconds: 3),
                    ),
                  );

                  try {
                    debugPrint('[UI] Memulai seeder test sederhana dari tombol UI...');
                    await learningProvider.runSimpleSeederTest();
                    debugPrint('[UI] Seeder test sederhana BERHASIL! Memulai pembersihan data dummy...');
                    await learningProvider.cleanupLegacyDummyData(uid);
                    debugPrint('[UI] Pembersihan database selesai! Melanjutkan inisialisasi learning stream...');
                    await learningProvider.initLearning(uid);
                    
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Database berhasil disinkronkan & modul telah dimuat!',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    }
                  } catch (e) {
                    debugPrint('[UI] Kegagalan tombol sinkronisasi: $e');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Gagal sinkron: ${e.toString().replaceFirst('Exception: ', '')}',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    }
                  }
                }
              },
              icon: Icon(Icons.sync_rounded, size: 16, color: Colors.white),
              label: Text(
                'Sinkronkan Ulang Database',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: mat.color,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModuleTile(BuildContext context, MaterialModel mat, ModuleModel module, bool isCompleted) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.colors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCompleted ? mat.color.withAlpha(80) : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ModuleDetailPage(
                  material: mat,
                  module: module,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Custom checkbox / checkmark with custom decoration
                GestureDetector(
                  onTap: () async {
                    // Trigger haptic feedback satisfying tap
                    await HapticFeedback.lightImpact();
                    final authProvider = Provider.of<AuthProvider>(context, listen: false);
                    final learningProvider = Provider.of<LearningProvider>(context, listen: false);
                    final uid = authProvider.currentUser.uid;
                    if (uid.isNotEmpty) {
                      final newStatus = !isCompleted;
                      await learningProvider.markModuleAsCompleted(
                        uid: uid,
                        materialId: mat.id,
                        moduleId: module.id,
                        completed: newStatus,
                      );
                      
                      // Show nice message
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(
                                newStatus ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                                color: context.colors.cardBg,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  newStatus 
                                      ? '🎉 Modul "${module.title}" ditandai selesai!' 
                                      : 'Modul "${module.title}" dibatalkan selesai.',
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: newStatus ? Colors.green.shade600 : Colors.grey.shade800,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      );

                      // Also trigger statistics saving if completed
                      if (newStatus) {
                        final statsProvider = Provider.of<StatisticsProvider>(context, listen: false);
                        await statsProvider.saveActivity(uid, 'material', mat.title);
                      }
                    }
                  },
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isCompleted ? mat.color : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isCompleted ? mat.color : context.colors.textLight.withAlpha(100),
                        width: 2,
                      ),
                    ),
                    child: isCompleted
                        ? Icon(Icons.check_rounded, color: context.colors.cardBg, size: 18)
                        : null,
                  ),
                ),
                SizedBox(width: 16),

                // Title and duration details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        module.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: context.colors.textPrimary,
                          height: 1.3,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.schedule_rounded, color: context.colors.textLight.withAlpha(150), size: 12),
                          SizedBox(width: 4),
                          Text(
                            '${module.estimatedMinutes} Menit',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: context.colors.textLight,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8),

                // Arrow icon styled to go to reader
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: context.colors.textLight.withAlpha(100),
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
