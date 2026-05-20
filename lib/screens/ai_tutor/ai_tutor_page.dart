import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../models/chat_model.dart';
import '../../providers/ai_chat_provider.dart';
import '../../providers/auth_provider.dart';

class AITutorPage extends StatefulWidget {
  final bool showBackButton;
  final double bottomPadding;

  const AITutorPage({
    super.key,
    this.showBackButton = true,
    this.bottomPadding = 0.0,
  });

  @override
  State<AITutorPage> createState() => _AITutorPageState();
}

class _AITutorPageState extends State<AITutorPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final chatProvider = Provider.of<AIChatProvider>(context, listen: false);
      if (authProvider.currentUser.isNotEmpty) {
        chatProvider.loadConversations(authProvider.currentUser.uid).then((_) {
          if (chatProvider.conversations.isNotEmpty) {
            chatProvider
                .selectConversation(authProvider.currentUser.uid, chatProvider.conversations.first.id)
                .then((_) {
              _scrollToBottom(isAnimated: false);
            });
          } else {
            chatProvider.startNewChat();
            _scrollToBottom(isAnimated: false);
          }
        });
      } else {
        _scrollToBottom(isAnimated: false);
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Gently scrolls the list view to the very bottom to display the latest messages.
  void _scrollToBottom({bool isAnimated = true}) {
    if (_scrollController.hasClients) {
      if (isAnimated) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      } else {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    }
  }

  /// Initiates sending the prompt to the AI chat provider.
  Future<void> _handleSendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<AIChatProvider>(context, listen: false);
    final uid = authProvider.currentUser.uid;
    
    // Smooth scroll down when user message is added
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    await chatProvider.sendMessage(text, uid);

    // Smooth scroll down when AI message arrives or error occurs
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    // Display SnackBar if there was an error
    if (chatProvider.errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(chatProvider.errorMessage!),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<AIChatProvider>(context);
    final isTablet = MediaQuery.of(context).size.shortestSide > 600;

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildHistoryDrawer(context, chatProvider),
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
              // 1. Premium Glassmorphism Navigation & Tutor Status Header
              _buildHeader(context, chatProvider, isTablet),

              // 2. Chat Log / Message Stream Area
              Expanded(
                child: (chatProvider.isHistoryLoading || (chatProvider.isLoading && chatProvider.messages.isEmpty))
                    ? _buildHistoryLoadingState()
                    : chatProvider.messages.isEmpty
                        ? _buildEmptyState(isTablet)
                        : _buildChatList(chatProvider),
              ),

              // 3. User Textfield Input Area
              _buildInputArea(chatProvider, isTablet),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a high-quality glassmorphic top navigation bar with tutor status indicators.
  Widget _buildHeader(BuildContext context, AIChatProvider provider, bool isTablet) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 24.0 : 16.0,
        vertical: 12.0,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.4),
        border: const Border(
          bottom: BorderSide(
            color: AppColors.glassBorder,
            width: 1.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Back button
          if (widget.showBackButton) ...[
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: 8),
          ],

          // Custom Painted AI Avatar with glowing border
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.6),
              border: Border.all(color: Colors.white, width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.glassShadow,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ClipOval(
              child: CustomPaint(
                painter: _AITutorLogoPainter(),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Name and real-time typing status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'StudyMate AI Tutor',
                  style: TextStyle(
                    fontSize: isTablet ? 18.0 : 15.0,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: provider.isLoading ? Colors.amber : const Color(0xFF2ECC71),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      provider.isLoading ? 'Sedang mengetik...' : 'Aktif & Siap Membantu',
                      style: TextStyle(
                        fontSize: isTablet ? 12.0 : 10.5,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // History / Drawer button
          IconButton(
            icon: const Icon(Icons.history_rounded, color: AppColors.textSecondary),
            tooltip: 'Riwayat Obrolan',
            onPressed: () {
              _scaffoldKey.currentState?.openDrawer();
            },
          ),
        ],
      ),
    );
  }

  /// Builds a friendly onboarding empty-state illustrating how to interact with StudyMate AI.
  Widget _buildEmptyState(bool isTablet) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Floating stylized icon card
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.glassShadow,
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: SizedBox(
                width: isTablet ? 80 : 60,
                height: isTablet ? 80 : 60,
                child: CustomPaint(
                  painter: _AITutorLogoPainter(),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Welcome Text
            Text(
              'Halo, Saya StudyMate AI!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isTablet ? 26.0 : 20.0,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Tanyakan apa saja seputar materi pelajaran, tugas, '
              'atau minta penjelasan konsep yang sulit dipahami. '
              'Mari belajar bersama dengan cerdas!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isTablet ? 16.0 : 13.5,
                color: AppColors.textSecondary,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 32),

            // Pre-made quick action helper prompts
            _buildQuickPromptCard('💡 Jelaskan konsep fotosintesis secara ringkas.', isTablet),
            const SizedBox(height: 12),
            _buildQuickPromptCard('✍️ Bantu saya membuat kerangka karangan esai.', isTablet),
          ],
        ),
      ),
    );
  }

  /// Helper widget for rendering a quick-tap learning template.
  Widget _buildQuickPromptCard(String promptText, bool isTablet) {
    return GestureDetector(
      onTap: () {
        _messageController.text = promptText;
      },
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white, width: 1),
          boxShadow: const [
            BoxShadow(
              color: AppColors.glassShadow,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                promptText,
                style: TextStyle(
                  fontSize: isTablet ? 14.0 : 12.5,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  /// Displays a premium loading spinner while historical messages are being fetched.
  Widget _buildHistoryLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.glassShadow,
                  blurRadius: 15,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3.5,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGradientStart),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Memuat riwayat percakapan...',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a premium, customized sidebar displaying all previous chat history log documents.
  Widget _buildHistoryDrawer(BuildContext context, AIChatProvider chatProvider) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Drawer(
      child: Container(
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
              // Drawer User Profile Header
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.4),
                  border: const Border(
                    bottom: BorderSide(color: AppColors.glassBorder, width: 1.5),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.primaryGradientStart.withOpacity(0.2),
                      backgroundImage: user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null,
                      child: user.photoUrl.isEmpty
                          ? Text(
                              user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : 'U',
                              style: const TextStyle(
                                color: AppColors.primaryGradientStart,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.displayName.isNotEmpty ? user.displayName : 'Pengguna StudyMate',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user.email.isNotEmpty ? user.email : 'Email tidak terdaftar',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Button: Obrolan Baru
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: GestureDetector(
                  onTap: () {
                    chatProvider.startNewChat();
                    Navigator.of(context).pop(); // Close Drawer
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primaryGradientStart, AppColors.primaryGradientEnd],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryGradientStart.withOpacity(0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Obrolan Baru',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Drawer Section Label
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 4.0),
                child: Row(
                  children: [
                    const Icon(Icons.history_rounded, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      'RIWAYAT PERCAKAPAN',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),

              // Conversations List
              Expanded(
                child: chatProvider.isHistoryLoading
                    ? const Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGradientStart),
                          ),
                        ),
                      )
                    : chatProvider.conversations.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0),
                              child: Text(
                                'Belum ada riwayat obrolan.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 10.0),
                            itemCount: chatProvider.conversations.length,
                            itemBuilder: (context, index) {
                              final conv = chatProvider.conversations[index];
                              final isActive = chatProvider.activeConversationId == conv.id;

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? Colors.white.withOpacity(0.8)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    border: isActive
                                        ? Border.all(color: Colors.white, width: 1)
                                        : null,
                                  ),
                                  child: ListTile(
                                    dense: true,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    leading: Icon(
                                      Icons.chat_bubble_outline_rounded,
                                      size: 18,
                                      color: isActive
                                          ? AppColors.primaryGradientStart
                                          : AppColors.textSecondary,
                                    ),
                                    title: Text(
                                      conv.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                                        color: isActive
                                            ? AppColors.textPrimary
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                                      color: Colors.redAccent.withOpacity(0.7),
                                      onPressed: () => _showDeleteConversationDialog(context, chatProvider, conv.id),
                                    ),
                                    onTap: () {
                                      chatProvider.selectConversation(user.uid, conv.id).then((_) {
                                        _scrollToBottom(isAnimated: false);
                                      });
                                      Navigator.of(context).pop(); // Close Drawer
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Opens a custom material dialog confirming if the user wants to delete a specific conversation.
  void _showDeleteConversationDialog(BuildContext context, AIChatProvider provider, String conversationId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Hapus Obrolan Ini?',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: const Text(
            'Percakapan ini dan seluruh pesannya akan dihapus secara permanen dari riwayat obrolan Anda.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.3,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Batal',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                provider.deleteConversation(authProvider.currentUser.uid, conversationId);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Percakapan berhasil dihapus.'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Hapus',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Builds the ListView containing all chat bubble items and the typing indicator.
  Widget _buildChatList(AIChatProvider provider) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      itemCount: provider.messages.length + (provider.isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        // Render typing indicator bubble at the end if loading
        if (index == provider.messages.length) {
          return _buildTypingIndicatorBubble();
        }

        final message = provider.messages[index];
        return _buildChatBubble(message);
      },
    );
  }

  /// Formats and renders a premium speech bubble depending on the message type.
  Widget _buildChatBubble(ChatMessage message) {
    final isUser = message is UserMessage;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Subtly show AI icon beside AI messages
          if (!isUser) ...[
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 8, bottom: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.6),
                border: Border.all(color: Colors.white, width: 1),
              ),
              child: ClipOval(
                child: CustomPaint(
                  painter: _AITutorLogoPainter(),
                ),
              ),
            ),
          ],
          
          Flexible(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.scale(
                    scale: 0.95 + (0.05 * value),
                    alignment: isUser ? Alignment.bottomRight : Alignment.bottomLeft,
                    child: child,
                  ),
                );
              },
              child: GestureDetector(
                onLongPress: () {
                  // Premium micro-interaction: long press to copy text
                  Clipboard.setData(ClipboardData(text: message.text));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Teks pesan berhasil disalin ke papan klip.'),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  decoration: BoxDecoration(
                    gradient: isUser
                        ? const LinearGradient(
                            colors: [AppColors.primaryGradientStart, AppColors.primaryGradientEnd],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isUser ? null : Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isUser ? 20 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 20),
                    ),
                    border: isUser
                        ? null
                        : Border.all(color: Colors.white, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: isUser
                            ? AppColors.primaryGradientStart.withOpacity(0.15)
                            : AppColors.glassShadow,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: isUser ? Colors.white : AppColors.textPrimary,
                      fontSize: 14.5,
                      fontWeight: isUser ? FontWeight.w600 : FontWeight.w500,
                      height: 1.4,
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

  /// Builds a special left-aligned bubble housing the custom pulsing typing indicator.
  Widget _buildTypingIndicatorBubble() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(right: 8, bottom: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.6),
              border: Border.all(color: Colors.white, width: 1),
            ),
            child: ClipOval(
              child: CustomPaint(
                painter: _AITutorLogoPainter(),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(20),
              ),
              border: Border.all(color: Colors.white, width: 1),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.glassShadow,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: const _TypingIndicator(),
          ),
        ],
      ),
    );
  }

  /// Builds a bottom glassmorphic interaction tray housing the multiline TextField and gradient send button.
  Widget _buildInputArea(AIChatProvider provider, bool isTablet) {
    return Container(
      padding: EdgeInsets.only(
        left: isTablet ? 24.0 : 16.0,
        right: isTablet ? 24.0 : 16.0,
        top: 12.0,
        bottom: 12.0 + widget.bottomPadding,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.35),
        border: const Border(
          top: BorderSide(
            color: AppColors.glassBorder,
            width: 1.5,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Expandable textfield container
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.glassShadow,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _messageController,
                minLines: 1,
                maxLines: 5,
                keyboardType: TextInputType.multiline,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'Tanya apa saja kepada StudyMate AI...',
                  hintStyle: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 14.0,
                    fontWeight: FontWeight.w500,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18.0,
                    vertical: 12.0,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Send message action button
          GestureDetector(
            onTap: provider.isLoading ? null : _handleSendMessage,
            child: Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: provider.isLoading
                    ? null
                    : const LinearGradient(
                        colors: [AppColors.primaryGradientStart, AppColors.primaryGradientEnd],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                color: provider.isLoading ? Colors.white.withOpacity(0.4) : null,
                boxShadow: provider.isLoading
                    ? null
                    : [
                        BoxShadow(
                          color: AppColors.primaryGradientStart.withOpacity(0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Icon(
                Icons.send_rounded,
                color: provider.isLoading ? AppColors.textLight : Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }}

/// A premium, custom-pulsing typing indicator representing real-time thoughts.
class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final double delay = index * 0.22;
            final double value = math.sin((_controller.value * 2 * math.pi) - (delay * 2 * math.pi));
            final double translation = (value + 1.0) / 2.0 * -6.0; // Bouncing height

            return Transform.translate(
              offset: Offset(0, translation),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                width: 6.5,
                height: 6.5,
                decoration: const BoxDecoration(
                  color: AppColors.textSecondary,
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

/// A custom-painted modern AI logo shape optimized for avatar representations
class _AITutorLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [AppColors.primaryGradientStart, AppColors.primaryGradientEnd],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final double w = size.width;
    final double h = size.height;

    // 1. Center Floating Droplet / Diamond
    final centerPath = Path();
    centerPath.moveTo(w * 0.5, h * 0.28);
    centerPath.cubicTo(w * 0.56, h * 0.35, w * 0.56, h * 0.40, w * 0.5, h * 0.46);
    centerPath.cubicTo(w * 0.44, h * 0.40, w * 0.44, h * 0.35, w * 0.5, h * 0.28);
    centerPath.close();
    canvas.drawPath(centerPath, paint);

    // 2. Left Sleek Petal Shape
    final leftPath = Path();
    leftPath.moveTo(w * 0.45, h * 0.48);
    leftPath.cubicTo(w * 0.28, h * 0.45, w * 0.20, h * 0.28, w * 0.22, h * 0.18);
    leftPath.cubicTo(w * 0.30, h * 0.16, w * 0.40, h * 0.30, w * 0.45, h * 0.45);
    leftPath.close();
    canvas.drawPath(leftPath, paint);

    // 3. Right Sleek Petal Shape
    final rightPath = Path();
    rightPath.moveTo(w * 0.55, h * 0.48);
    rightPath.cubicTo(w * 0.72, h * 0.45, w * 0.80, h * 0.28, w * 0.78, h * 0.18);
    rightPath.cubicTo(w * 0.70, h * 0.16, w * 0.60, h * 0.30, w * 0.55, h * 0.45);
    rightPath.close();
    canvas.drawPath(rightPath, paint);

    // 4. Bottom Support Crescent / Digital Wings
    final bottomPath = Path();
    bottomPath.moveTo(w * 0.24, h * 0.58);
    bottomPath.quadraticBezierTo(w * 0.5, h * 0.80, w * 0.76, h * 0.58);
    bottomPath.quadraticBezierTo(w * 0.5, h * 0.68, w * 0.24, h * 0.58);
    bottomPath.close();
    canvas.drawPath(bottomPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
