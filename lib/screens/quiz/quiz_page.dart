import 'package:flutter/material.dart';
import '../../utils/theme_context.dart';
import 'package:provider/provider.dart';
import '../../models/quiz_session_model.dart';
import '../../providers/quiz_provider.dart';

class QuizPage extends StatefulWidget {
  final QuizSessionModel session;

  const QuizPage({
    super.key,
    required this.session,
  });

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  void _submitQuiz(BuildContext context) async {
    final provider = Provider.of<QuizProvider>(context, listen: false);
    
    if (provider.isLoading) return;

    if (provider.selectedAnswers.length < provider.currentQuestions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap jawab semua pertanyaan terlebih dahulu.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final success = await provider.submitQuizSession();
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Gagal mengirim jawaban kuis. Silakan coba lagi.'),
          backgroundColor: Colors.redAccent,
        ),
      );
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
          'Kuis: ${widget.session.materialTitle}',
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
      body: Consumer<QuizProvider>(
        builder: (context, provider, child) {
          if (provider.errorMessage != null && provider.currentQuestions.isEmpty) {
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

          if (provider.currentQuestions.isEmpty) {
            return Center(
              child: Text(
                'Belum ada pertanyaan kuis untuk sesi ini.',
                style: TextStyle(color: context.colors.textSecondary),
              ),
            );
          }

          // If the session in the provider is completed, show result view
          final isCompleted = provider.currentSession?.completed ?? widget.session.completed;
          if (isCompleted) {
            return _buildResultView(context, provider);
          }

          // Gunakan Stack agar ListView kuis tetap ter-mount dan posisi scroll tidak hilang
          return Stack(
            children: [
              _buildQuizForm(context, provider),
              if (provider.isLoading)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child: Center(
                    child: Card(
                      color: context.colors.cardBg,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(context.colors.primaryGradientStart),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Sedang memproses...',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: context.colors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Kalkulasi nilai dan merangkum feedback...',
                              style: TextStyle(
                                fontSize: 12,
                                color: context.colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildQuizForm(BuildContext context, QuizProvider provider) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(),
            itemCount: provider.currentQuestions.length,
            itemBuilder: (context, index) {
              final quiz = provider.currentQuestions[index];

              return Card(
                elevation: 0,
                color: context.colors.cardBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: context.colors.textPrimary.withAlpha(20)),
                ),
                margin: const EdgeInsets.only(bottom: 20),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: context.colors.primaryGradientStart.withAlpha(25),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: context.colors.primaryGradientStart,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                quiz.question,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: context.colors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      ...quiz.options.map((option) {
                        final isSelected = provider.selectedAnswers[quiz.id] == option;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: InkWell(
                            onTap: () => provider.selectAnswer(quiz.id, option),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? context.colors.primaryGradientStart.withAlpha(12) : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? context.colors.primaryGradientStart : context.colors.textPrimary.withAlpha(30),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                    color: isSelected ? context.colors.primaryGradientStart : context.colors.textSecondary.withAlpha(150),
                                    size: 20,
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      option,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isSelected ? context.colors.primaryGradientStart : context.colors.textPrimary,
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
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
              child: ElevatedButton(
                onPressed: provider.isLoading ? null : () => _submitQuiz(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.primaryGradientStart,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Kirim Jawaban',
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
    );
  }

  Widget _buildResultView(BuildContext context, QuizProvider provider) {
    final session = provider.currentSession ?? widget.session;
    final isPassed = session.score >= 70;

    int correctAnswers = 0;
    for (var q in provider.currentQuestions) {
      if (q.userAnswer == q.correctAnswer) {
        correctAnswers++;
      }
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isPassed ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPassed ? Icons.workspace_premium_rounded : Icons.lightbulb_outline_rounded,
              size: 64,
              color: isPassed ? Colors.green : Colors.orange,
            ),
          ),
          SizedBox(height: 24),
          Text(
            isPassed ? 'Luar Biasa!' : 'Tetap Semangat!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: context.colors.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Kamu berhasil menyelesaikan kuis ${session.materialTitle}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: context.colors.textSecondary,
            ),
          ),
          SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: _buildScoreCard(
                  'Skor Kamu',
                  '${session.score}',
                  context.colors.primaryGradientStart,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildScoreCard(
                  'Jawaban Benar',
                  '$correctAnswers/${session.totalQuestions}',
                  Colors.green,
                ),
              ),
            ],
          ),
          SizedBox(height: 32),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.colors.cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.colors.primaryGradientStart.withAlpha(50)),
              boxShadow: [
                BoxShadow(
                  color: context.colors.primaryGradientStart.withAlpha(12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: context.colors.primaryGradientStart, size: 24),
                    SizedBox(width: 12),
                    Text(
                      'AI Feedback',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: context.colors.textPrimary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Text(
                  session.aiFeedback,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: context.colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          
          // Review Jawaban
          SizedBox(height: 32),
          Text(
            'Review Jawaban',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.colors.textPrimary,
            ),
          ),
          SizedBox(height: 16),
          ...provider.currentQuestions.map((q) {
            final isCorrect = q.userAnswer == q.correctAnswer;
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 0,
              color: context.colors.cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: context.colors.textPrimary.withAlpha(20)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      q.question,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: context.colors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Jawabanmu: ${q.userAnswer ?? '-'}',
                      style: TextStyle(
                        color: isCorrect ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (!isCorrect) ...[
                      SizedBox(height: 4),
                      Text(
                        'Jawaban Benar: ${q.correctAnswer}',
                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                    ],
                    SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Penjelasan:\n${q.explanation}',
                        style: TextStyle(
                          fontSize: 13,
                          color: context.colors.textPrimary,
                        ),
                      ),
                    )
                  ],
                ),
              ),
            );
          }),

          SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: context.colors.primaryGradientStart),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Kembali ke Daftar Sesi',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: context.colors.primaryGradientStart,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
