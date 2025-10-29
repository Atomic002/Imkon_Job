import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:version1/config/constants.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      setState(() => isLoading = true);

      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        Get.snackbar(
          'Xato',
          'Iltimos, tizimga kiring',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        setState(() => isLoading = false);
        return;
      }

      final response = await supabase
          .from('notifications')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(100);

      setState(() {
        notifications = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });

      print('📬 Loaded ${notifications.length} notifications');
    } catch (e) {
      print('❌ Load notifications error: $e');
      setState(() => isLoading = false);

      Get.snackbar(
        'Xato',
        'Bildirishnomalarni yuklashda xato',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);

      setState(() {
        final index = notifications.indexWhere(
          (n) => n['id'] == notificationId,
        );
        if (index != -1) {
          notifications[index]['is_read'] = true;
        }
      });
    } catch (e) {
      print('❌ Mark as read error: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      await supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);

      await _loadNotifications();

      Get.snackbar(
        'Muvaffaqiyatli',
        'Barcha bildirishnomalar o\'qilgan deb belgilandi',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );
    } catch (e) {
      print('❌ Mark all as read error: $e');
      Get.snackbar(
        'Xato',
        'Xatolik yuz berdi',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      await supabase.from('notifications').delete().eq('id', notificationId);

      setState(() {
        notifications.removeWhere((n) => n['id'] == notificationId);
      });

      Get.snackbar(
        'O\'chirildi',
        'Bildirishnoma o\'chirildi',
        backgroundColor: Colors.grey[700],
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      print('❌ Delete notification error: $e');
    }
  }

  Future<void> _clearAllNotifications() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Barcha bildirishnomalarni o\'chirish'),
        content: const Text(
          'Haqiqatan ham barcha bildirishnomalarni o\'chirmoqchimisiz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Bekor qilish'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('O\'chirish'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      await supabase.from('notifications').delete().eq('user_id', userId);

      setState(() {
        notifications.clear();
      });

      Get.snackbar(
        'Muvaffaqiyatli',
        'Barcha bildirishnomalar o\'chirildi',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      print('❌ Clear all notifications error: $e');
      Get.snackbar(
        'Xato',
        'Xatolik yuz berdi',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case 'like':
        return Icons.favorite;
      case 'comment':
        return Icons.comment;
      case 'message':
        return Icons.message;
      case 'application':
        return Icons.work;
      case 'system':
        return Icons.info;
      case 'post_approved':
        return Icons.check_circle_rounded;
      case 'post_rejected':
        return Icons.cancel_rounded;
      case 'post_pending':
        return Icons.schedule_rounded;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String? type) {
    switch (type) {
      case 'like':
        return Colors.red;
      case 'comment':
        return Colors.blue;
      case 'message':
        return Colors.green;
      case 'application':
        return Colors.orange;
      case 'system':
        return Colors.purple;
      case 'post_approved':
        return Colors.green;
      case 'post_rejected':
        return Colors.red;
      case 'post_pending':
        return Colors.orange;
      default:
        return AppConstants.primaryColor;
    }
  }

  String _getTimeAgo(String? createdAt) {
    if (createdAt == null) return 'Noma\'lum';

    try {
      final dateTime = DateTime.parse(createdAt);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Hozir';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m oldin';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h oldin';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d oldin';
      } else {
        return DateFormat('dd.MM.yyyy').format(dateTime);
      }
    } catch (e) {
      return 'Noma\'lum';
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = notifications
        .where((n) => n['is_read'] == false)
        .length;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppConstants.textPrimary,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bildirishnomalar',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
            ),
            if (unreadCount > 0)
              Text(
                '$unreadCount ta o\'qilmagan',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        actions: [
          if (notifications.isNotEmpty) ...[
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'mark_all') {
                  _markAllAsRead();
                } else if (value == 'clear_all') {
                  _clearAllNotifications();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'mark_all',
                  child: Row(
                    children: [
                      Icon(Icons.done_all, size: 20),
                      SizedBox(width: 12),
                      Text('Hammasini o\'qilgan'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'clear_all',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep, size: 20, color: Colors.red),
                      SizedBox(width: 12),
                      Text(
                        'Hammasini o\'chirish',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadNotifications,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return _buildNotificationCard(notification);
                },
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Bildirishnomalar yo\'q',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Yangi bildirishnomalar bu yerda ko\'rinadi',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final isRead = notification['is_read'] ?? false;
    final type = notification['type'];
    final title = notification['title'] ?? 'Bildirishnoma';
    final body = notification['body'] ?? '';
    final createdAt = notification['created_at'];

    // Debug uchun - qanday ma'lumot kelayotganini ko'rish
    print('🔔 Notification DEBUG:');
    print('   ID: ${notification['id']}');
    print('   Type: $type');
    print('   Title: $title');
    print('   Body: $body');
    print('   Body length: ${body.length}');
    print('   Body is empty: ${body.isEmpty}');
    print('   Full notification: $notification');

    return Dismissible(
      key: Key(notification['id']),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        _deleteNotification(notification['id']);
      },
      child: GestureDetector(
        onTap: () {
          if (!isRead) {
            _markAsRead(notification['id']);
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isRead
                ? Colors.white
                : AppConstants.primaryColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isRead
                  ? Colors.grey[200]!
                  : AppConstants.primaryColor.withOpacity(0.2),
              width: isRead ? 1 : 2,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _getNotificationColor(type).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getNotificationIcon(type),
                color: _getNotificationColor(type),
                size: 24,
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!isRead)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppConstants.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // BODY (sabab) ni har doim ko'rsatish
                if (body.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  // Agar post_rejected bo'lsa, maxsus dizaynda
                  if (type == 'post_rejected')
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.red.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 18,
                            color: Colors.red[700],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Rad etilish sababi:',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.red[900],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  body,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.red[800],
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  // Boshqa bildirishnomalar uchun oddiy ko'rinish
                  else
                    Text(
                      body,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
                const SizedBox(height: 8),
                Text(
                  _getTimeAgo(createdAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
