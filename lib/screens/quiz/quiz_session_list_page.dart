import 'package:flutter/material.dart';
import '../../utils/theme_context.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/quiz_provider.dart';
import '../../providers/auth_provider.dart';
import 'quiz_page.dart';

class QuizSessionListPage extends StatefulWidget {
  final String materialId;
  final String materialTitle;

  const QuizSessionListPage({
    super.key,
    required this.materialId,
    required this.materialTitle,
  });

  @override
  State<QuizSessionListPage> createState() => _QuizSessionListPageState();
}

class _QuizSessionListPageState extends State<QuizSessionListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = Provider.of<AuthProvider>(context, listen: false).currentUser.uid;
      Provider.of<QuizProvider>(context, listen: false).fetchQuizSessions(uid);
    });
  }

  void _generateNewSession(BuildContext context) async {
    final provider = Provider.of<QuizProvider>(context, listen: false);
    
    // Show generating dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 16),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(context.colors.primaryGradientStart),
            ),
            SizedBox(height: 24),
            Text(
              'Menyusun Kuis Baru dengan AI...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: context.colors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Tunggu sebentar ya, Gemini AI sedang meracik soal khusus untukmu.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: context.colors.textSecondary,
              ),
            ),
            SizedBox(height: 8),
          ],
        ),
      ),
    );

    final success = await provider.generateNewSession(widget.materialId, widget.materialTitle);
    
    if (context.mounted) {
      Navigator.pop(context); // Close dialog

      if (success && provider.currentSession != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuizPage(session: provider.currentSession!),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Gagal membuat sesi baru.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.bgGradientStart,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Daftar Sesi Kuis',
          style: TextStyle(
            color: context.colors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.colors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: context.colors.primaryGradientStart.withAlpha(12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.materialTitle,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: context.colors.primaryGradientStart,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Kamu bisa mengulang atau membuat kuis baru tanpa batas untuk sesi lama. Kuis baru dibatasi 5 per hari.',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<QuizProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.sessions.isEmpty) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(context.colors.primaryGradientStart),
                    ),
                  );
                }

                if (provider.errorMessage != null && provider.sessions.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        provider.errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  );
                }
                
                // Filter sessions by material
                final materialSessions = provider.sessions
                    .where((s) => s.materialId == widget.materialId)
                    .toList();

                if (materialSessions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.quiz_outlined, size: 80, color: context.colors.textSecondary.withAlpha(80)),
                        SizedBox(height: 16),
                        Text(
                          'Belum ada sesi kuis.',
                          style: TextStyle(color: context.colors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  physics: const BouncingScrollPhysics(),
                  itemCount: materialSessions.length,
                  separatorBuilder: (context, index) => SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final session = materialSessions[index];
                    final dateStr = DateFormat('dd MMM yyyy, HH:mm').format(session.createdAt);

                    return InkWell(
                      onTap: () async {
                        await provider.loadSession(session);
                        if (context.mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => QuizPage(session: session),
                            ),
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: context.colors.cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: context.colors.textPrimary.withAlpha(20)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: session.completed 
                                    ? Colors.green.withOpacity(0.1) 
                                    : Colors.orange.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                session.completed ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
                                color: session.completed ? Colors.green : Colors.orange,
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    session.completed ? 'Skor: ${session.score}' : 'Belum Selesai',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: session.completed ? context.colors.textPrimary : Colors.orange,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    dateStr,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: context.colors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: context.colors.textSecondary,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.colors.cardBg,
              boxShadow: [
                BoxShadow(
                  color: context.colors.glassShadow,
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () => _generateNewSession(context),
                  icon: Icon(Icons.add_task_rounded, color: Colors.white),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colors.primaryGradientStart,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  label: Text(
                    'Generate Quiz Baru',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
