import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../models/material_model.dart';
import '../../models/module_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/learning_provider.dart';
import '../../providers/statistics_provider.dart';

class ModuleDetailPage extends StatefulWidget {
  final MaterialModel material;
  final ModuleModel module;

  const ModuleDetailPage({
    super.key,
    required this.material,
    required this.module,
  });

  @override
  State<ModuleDetailPage> createState() => _ModuleDetailPageState();
}

class _ModuleDetailPageState extends State<ModuleDetailPage> {
  late ScrollController _scrollController;
  double _scrollProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()
      ..addListener(() {
        if (_scrollController.hasClients) {
          final maxScroll = _scrollController.position.maxScrollExtent;
          final currentScroll = _scrollController.position.pixels;
          setState(() {
            _scrollProgress = maxScroll > 0 ? (currentScroll / maxScroll).clamp(0.0, 1.0) : 1.0;
          });
        }
      });

    // Record last read timestamp in Firestore
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final learningProvider = Provider.of<LearningProvider>(context, listen: false);
        final uid = authProvider.currentUser.uid;
        if (uid.isNotEmpty) {
          // Simply update the local/remote timestamp without changing completed status
          learningProvider.markModuleAsCompleted(
            uid: uid,
            materialId: widget.material.id,
            moduleId: widget.module.id,
            completed: learningProvider.isModuleCompleted(widget.module.id),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mat = widget.material;
    final mod = widget.module;
    final learningProvider = Provider.of<LearningProvider>(context);
    final isCompleted = learningProvider.isModuleCompleted(mod.id);

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
          child: Column(
            children: [
              // 1. Premium Transparent Header with Reading Progress Bar
              _buildHeader(context, mat, mod),

              // 2. Reading Content Area
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category & Duration tag
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: mat.color.withAlpha(20),
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Text(
                                  mat.category.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: mat.color,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.schedule_rounded, color: AppColors.textLight.withAlpha(180), size: 14),
                              const SizedBox(width: 4),
                              Text(
                                '${mod.estimatedMinutes} Menit Membaca',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textLight,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Module Title
                          Text(
                            mod.title,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                              height: 1.3,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Divider(color: AppColors.progressTrack, height: 1),
                          const SizedBox(height: 24),

                          // Custom Premium Academic Markdown Text Parser
                          _buildContentRenderer(mod.content, mat.color),

                          const SizedBox(height: 120), // Padding to avoid overlap with floating bottom bar
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
      
      // 3. Floating Glassmorphic Completion Action Bar
      bottomNavigationBar: _buildFloatingActionBar(context, mat, mod, isCompleted),
    );
  }

  Widget _buildHeader(BuildContext context, MaterialModel mat, ModuleModel mod) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(100),
        border: Border(
          bottom: BorderSide(
            color: Colors.black.withAlpha(5),
            width: 1.0,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppColors.textPrimary,
                    size: 20,
                  ),
                ),
                Expanded(
                  child: Text(
                    mod.title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 48), // Balanced alignment
              ],
            ),
          ),
          
          // Micro-animated reading progress indicator
          Container(
            height: 3,
            width: double.infinity,
            color: AppColors.progressTrack,
            child: Align(
              alignment: Alignment.centerLeft,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                width: MediaQuery.of(context).size.width * _scrollProgress,
                color: mat.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Parses academic content into styled UI blocks dynamically.
  Widget _buildContentRenderer(String rawText, Color accentColor) {
    final List<String> lines = rawText.split('\n');
    final List<Widget> blocks = [];
    
    bool inCodeBlock = false;
    List<String> currentCodeLines = [];

    List<String> currentBlockquoteLines = [];

    void commitBlockquote() {
      if (currentBlockquoteLines.isNotEmpty) {
        blocks.add(_buildCalloutWidget(currentBlockquoteLines.join('\n'), accentColor));
        currentBlockquoteLines.clear();
      }
    }

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      // Code Block Toggles
      if (line.trim().startsWith('```')) {
        commitBlockquote();
        if (inCodeBlock) {
          // Render code block
          inCodeBlock = false;
          blocks.add(_buildCodeBlockWidget(currentCodeLines.join('\n')));
          currentCodeLines.clear();
        } else {
          inCodeBlock = true;
        }
        continue;
      }

      if (inCodeBlock) {
        currentCodeLines.add(line);
        continue;
      }

      // Blockquote/Callout line parsing
      if (line.trimLeft().startsWith('>')) {
        String stripped = line.trimLeft().substring(1);
        if (stripped.startsWith(' ')) {
          stripped = stripped.substring(1);
        }
        currentBlockquoteLines.add(stripped);
        continue;
      } else {
        commitBlockquote();
      }

      // H1 Header
      if (line.startsWith('# ')) {
        blocks.add(Padding(
          padding: const EdgeInsets.only(top: 28.0, bottom: 14.0),
          child: Text(
            line.substring(2),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
        ));
      }
      // H2 Header
      else if (line.startsWith('## ')) {
        blocks.add(Padding(
          padding: const EdgeInsets.only(top: 24.0, bottom: 10.0),
          child: Text(
            line.substring(3),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
        ));
      }
      // Bullet Items
      else if (line.trim().startsWith('- ') || line.trim().startsWith('* ')) {
        final text = line.trim().substring(2);
        blocks.add(Padding(
          padding: const EdgeInsets.only(bottom: 12.0, left: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8.0),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: RichText(
                  text: _parseInlineStyles(text),
                ),
              ),
            ],
          ),
        ));
      }
      // Standard Paragraph Text
      else if (line.trim().isNotEmpty) {
        blocks.add(Padding(
          padding: const EdgeInsets.only(bottom: 18.0),
          child: RichText(
            text: _parseInlineStyles(line),
          ),
        ));
      }
    }

    // Commit any trailing open blocks
    commitBlockquote();
    if (inCodeBlock && currentCodeLines.isNotEmpty) {
      blocks.add(_buildCodeBlockWidget(currentCodeLines.join('\n')));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: blocks,
    );
  }

  /// Builds a beautifully styled glassmorphic academic Callout Card with customizable colors and icons.
  Widget _buildCalloutWidget(String textContent, Color accentColor) {
    final lines = textContent.split('\n');
    final List<Widget> children = [];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        children.add(const SizedBox(height: 8));
      } else if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
        final text = trimmed.substring(2);
        children.add(Padding(
          padding: const EdgeInsets.only(bottom: 6.0, left: 4.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8.0),
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: RichText(
                  text: _parseInlineStyles(text, isCallout: true),
                ),
              ),
            ],
          ),
        ));
      } else {
        children.add(Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: RichText(
            text: _parseInlineStyles(line, isCallout: true),
          ),
        ));
      }
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20.0, top: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: accentColor.withAlpha(12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withAlpha(38),
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lightbulb_outline_rounded,
              color: accentColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  /// Parses inline markdown styling like **bold** elements into structured TextSpans
  TextSpan _parseInlineStyles(String text, {bool isCallout = false}) {
    final List<TextSpan> spans = [];
    final RegExp boldPattern = RegExp(r'\*\*(.*?)\*\*');
    
    int start = 0;
    for (final match in boldPattern.allMatches(text)) {
      // Plain text before match
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start)));
      }
      // Bold text
      spans.add(TextSpan(
        text: match.group(1),
        style: TextStyle(
          fontWeight: FontWeight.w900,
          color: AppColors.textPrimary,
          fontStyle: isCallout ? FontStyle.italic : FontStyle.normal,
        ),
      ));
      start = match.end;
    }
    
    // Plain text after all matches
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }

    return TextSpan(
      style: TextStyle(
        fontSize: isCallout ? 15.0 : 16.0,
        color: isCallout ? AppColors.textPrimary.withAlpha(220) : AppColors.textSecondary,
        height: 1.6,
        fontWeight: FontWeight.w500,
        fontStyle: isCallout ? FontStyle.italic : FontStyle.normal,
      ),
      children: spans.isEmpty ? [TextSpan(text: text)] : spans,
    );
  }

  Widget _buildCodeBlockWidget(String code) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20.0, top: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Text(
          code,
          style: TextStyle(
            fontFamily: 'Courier',
            fontSize: 13,
            color: Colors.greenAccent.shade200,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionBar(BuildContext context, MaterialModel mat, ModuleModel mod, bool isCompleted) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(204), // 80% white glass
            border: Border(
              top: BorderSide(
                color: Colors.white.withAlpha(120),
                width: 1.5,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: LinearGradient(
                          colors: isCompleted
                              ? [Colors.grey.shade700, Colors.grey.shade800]
                              : [mat.color, mat.color.withAlpha(200)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isCompleted
                                ? Colors.black12
                                : mat.color.withAlpha(90),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () async {
                            // Medium impact haptic feedback for satisfying confirmation
                            await HapticFeedback.mediumImpact();

                            final authProvider = Provider.of<AuthProvider>(context, listen: false);
                            final learningProvider = Provider.of<LearningProvider>(context, listen: false);
                            final uid = authProvider.currentUser.uid;

                            if (uid.isNotEmpty) {
                              final newStatus = !isCompleted;
                              await learningProvider.markModuleAsCompleted(
                                uid: uid,
                                materialId: mat.id,
                                moduleId: mod.id,
                                completed: newStatus,
                              );

                              // Success toast localized
                              ScaffoldMessenger.of(context).clearSnackBars();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(
                                        newStatus ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          newStatus
                                              ? '🎉 Hore! Modul "${mod.title}" ditandai selesai!'
                                              : 'Modul "${mod.title}" dibatalkan selesai.',
                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: newStatus ? Colors.green.shade600 : Colors.grey.shade800,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                              );

                              // If completed, register dynamic activity in stats provider to advance weekly analytics
                              if (newStatus) {
                                final statsProvider = Provider.of<StatisticsProvider>(context, listen: false);
                                await statsProvider.saveActivity(uid, 'material', mat.title);
                              }
                            }
                          },
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isCompleted ? Icons.check_circle_rounded : Icons.task_alt_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  isCompleted ? 'Sudah Selesai (Batal?)' : 'Tandai Selesai',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14.5,
                                    letterSpacing: 0.2,
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
        ),
      ),
    );
  }
}
