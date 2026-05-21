import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../models/notification_model.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  String _selectedFilter = 'all';

  final List<Map<String, String>> _filters = [
    {'key': 'all', 'label': 'Semua'},
    {'key': NotificationModel.typeQuizCompleted, 'label': 'Kuis'},
    {'key': NotificationModel.typeStreak, 'label': 'Streak'},
    {'key': NotificationModel.typeLearningTarget, 'label': 'Target'},
    {'key': NotificationModel.typeAiFeedback, 'label': 'Feedback AI'},
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final user = authProvider.currentUser;
    final uid = user.uid;

    // Filter notifications based on selected filter
    final filteredNotifications = notificationProvider.notifications.where((n) {
      if (_selectedFilter == 'all') return true;
      return n.type == _selectedFilter;
    }).toList();

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
              // 1. Custom Sleek Header
              _buildHeader(context, uid, notificationProvider),

              // 2. Interactive Filter Pills
              _buildFilterPills(),

              // 3. Main content
              Expanded(
                child: notificationProvider.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primaryGradientStart,
                          ),
                        ),
                      )
                    : filteredNotifications.isEmpty
                        ? _buildEmptyState()
                        : _buildNotificationList(uid, filteredNotifications, notificationProvider),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Beautiful Header with quick actions
  Widget _buildHeader(BuildContext context, String uid, NotificationProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Row(
        children: [
          // Back Button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(204),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withAlpha(150), width: 1.5),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.textPrimary,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Notifikasi',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                if (provider.unreadCount > 0)
                  Text(
                    '${provider.unreadCount} belum dibaca',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryGradientStart,
                    ),
                  ),
              ],
            ),
          ),
          // Actions Popup Menu
          PopupMenuButton<String>(
            icon: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(204),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withAlpha(150), width: 1.5),
              ),
              child: const Icon(
                Icons.more_vert_rounded,
                color: AppColors.textPrimary,
                size: 20,
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 8,
            onSelected: (value) {
              if (value == 'read_all') {
                provider.markAllAsRead(uid);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Semua notifikasi ditandai telah dibaca'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } else if (value == 'clear_all') {
                _showClearConfirmationDialog(context, uid, provider);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'read_all',
                enabled: provider.unreadCount > 0,
                child: Row(
                  children: const [
                    Icon(Icons.done_all_rounded, color: AppColors.textPrimary, size: 18),
                    SizedBox(width: 12),
                    Text('Tandai semua dibaca'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'clear_all',
                enabled: provider.notifications.isNotEmpty,
                child: Row(
                  children: const [
                    Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 18),
                    SizedBox(width: 12),
                    Text('Hapus semua', style: TextStyle(color: Colors.redAccent)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Interactive Filter Pills (Horizontal list of categories)
  Widget _buildFilterPills() {
    return Container(
      height: 42,
      margin: const EdgeInsets.only(bottom: 16.0),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final bool isSelected = _selectedFilter == filter['key'];

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilter = filter['key']!;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [
                          AppColors.primaryGradientStart,
                          AppColors.primaryGradientEnd,
                        ],
                      )
                    : null,
                color: isSelected ? null : Colors.white.withAlpha(180),
                border: Border.all(
                  color: isSelected ? Colors.transparent : Colors.white.withAlpha(200),
                  width: 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primaryGradientStart.withAlpha(50),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  filter['label']!,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Custom visual components for different notification types
  IconData _getIcon(String type) {
    switch (type) {
      case NotificationModel.typeQuizCompleted:
        return Icons.quiz_rounded;
      case NotificationModel.typeStreak:
        return Icons.local_fire_department_rounded;
      case NotificationModel.typeLearningTarget:
        return Icons.track_changes_rounded;
      case NotificationModel.typeAiFeedback:
        return Icons.auto_awesome_rounded;
      case NotificationModel.typeSystem:
      default:
        return Icons.notifications_active_rounded;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case NotificationModel.typeQuizCompleted:
        return const Color(0xFF2E7D32); // Deep Green
      case NotificationModel.typeStreak:
        return Colors.orangeAccent;
      case NotificationModel.typeLearningTarget:
        return Colors.blueAccent;
      case NotificationModel.typeAiFeedback:
        return const Color(0xFF6B3BC7); // Purple
      case NotificationModel.typeSystem:
      default:
        return Colors.blueGrey;
    }
  }

  // Elegant list builder
  Widget _buildNotificationList(
    String uid,
    List<NotificationModel> list,
    NotificationProvider provider,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 24.0),
      physics: const BouncingScrollPhysics(),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final notification = list[index];
        final icon = _getIcon(notification.type);
        final color = _getColor(notification.type);
        final relativeTime = _getRelativeTime(notification.createdAt);

        return Dismissible(
          key: Key(notification.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20.0),
            margin: const EdgeInsets.only(bottom: 12.0),
            decoration: BoxDecoration(
              color: Colors.redAccent.withAlpha(200),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
          ),
          onDismissed: (_) {
            provider.deleteNotification(uid, notification.id);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Notifikasi berhasil dihapus'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          confirmDismiss: (_) async {
            return true;
          },
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: GestureDetector(
              onTap: () {
                if (!notification.isRead) {
                  provider.markAsRead(uid, notification.id);
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(notification.isRead ? 178 : 255),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: notification.isRead ? Colors.white.withAlpha(150) : Colors.white,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(notification.isRead ? 3 : 8),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Dot (Unread indicator)
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(top: 16, right: 10),
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                        )
                      else
                        const SizedBox(width: 18),

                      // Colored Icon Background
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color.withAlpha(20),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: color, size: 20),
                      ),
                      const SizedBox(width: 14),

                      // Text Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notification.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: notification.isRead ? FontWeight.w700 : FontWeight.w900,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              notification.message,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: notification.isRead ? AppColors.textLight : AppColors.textSecondary,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              relativeTime,
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
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Elegant Empty State
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 320),
          padding: const EdgeInsets.all(28.0),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(127), // Semi-transparent white
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withAlpha(150), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Large Bell Icon with elegant gradient bg
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryGradientStart.withAlpha(40),
                      AppColors.primaryGradientEnd.withAlpha(40),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_none_outlined,
                  color: AppColors.primaryGradientStart,
                  size: 36,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Tidak Ada Notifikasi',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Belum ada notifikasi baru untukmu. Semangat belajar terus!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Confirmation dialog for clearing all notifications
  void _showClearConfirmationDialog(
    BuildContext context,
    String uid,
    NotificationProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            backgroundColor: Colors.white,
            title: const Text(
              'Hapus Semua Notifikasi?',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            content: const Text(
              'Tindakan ini akan menghapus semua riwayat notifikasi kamu secara permanen.',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Batal',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textLight,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  provider.clearNotifications(uid);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Semua notifikasi berhasil dihapus'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child: const Text(
                  'Hapus',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper method for Relative Time Formatting in Indonesian
  String _getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Baru saja';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inDays == 1) {
      return 'Kemarin';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari lalu';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
