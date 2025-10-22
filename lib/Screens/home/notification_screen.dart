import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

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
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        setState(() => isLoading = false);
        return;
      }

      // Notifications jadvalidan user-ning notifications-larini olish
      final response = await supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      if (response != null) {
        setState(() {
          notifications = List<Map<String, dynamic>>.from(response);
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading notifications: $e');
      setState(() => isLoading = false);
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
      print('Error marking notification as read: $e');
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      await supabase.from('notifications').delete().eq('id', notificationId);

      setState(() {
        notifications.removeWhere((n) => n['id'] == notificationId);
      });

      Get.snackbar('Muvaffaqiyatli', 'Bildirishnoma o\'chirildi');
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirishnomalar'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Get.back(),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Bildirishnomalar yo\'q',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () => _loadNotifications(),
              child: ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  final isRead = notification['is_read'] as bool? ?? false;
                  final type = notification['type'] as String? ?? '';
                  final title = notification['title'] as String? ?? '';
                  final body = notification['body'] as String? ?? '';
                  final createdAt = notification['created_at'] as String? ?? '';

                  return _buildNotificationItem(
                    title: title,
                    body: body,
                    type: type,
                    isRead: isRead,
                    createdAt: createdAt,
                    onTap: () {
                      _markAsRead(notification['id'] as String);
                    },
                    onDelete: () {
                      _deleteNotification(notification['id'] as String);
                    },
                  );
                },
              ),
            ),
    );
  }

  Widget _buildNotificationItem({
    required String title,
    required String body,
    required String type,
    required bool isRead,
    required String createdAt,
    required VoidCallback onTap,
    required VoidCallback onDelete,
  }) {
    IconData icon = Icons.notifications_rounded;
    Color iconColor = Colors.blue;

    // Type-ga qarab icon va rang
    if (type == 'post_approved') {
      icon = Icons.check_circle_rounded;
      iconColor = Colors.green;
    } else if (type == 'post_rejected') {
      icon = Icons.cancel_rounded;
      iconColor = Colors.red;
    } else if (type == 'post_pending') {
      icon = Icons.schedule_rounded;
      iconColor = Colors.orange;
    }

    final time = _formatTime(createdAt);

    return Material(
      color: isRead ? Colors.white : Colors.blue.withOpacity(0.05),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(child: Icon(icon, color: iconColor, size: 24)),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isRead
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      body,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      time,
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),

              // Delete button
              PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: const Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('O\'chirish'),
                      ],
                    ),
                    onTap: onDelete,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(String dateString) {
    try {
      final dateTime = DateTime.parse(dateString);
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
      return '';
    }
  }
}
