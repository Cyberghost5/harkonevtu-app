import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_config_provider.dart';
import '../../providers/dashboard_provider.dart';
import 'clay_container.dart';
import 'clay_button.dart';

class NotificationModal extends StatefulWidget {
  const NotificationModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const NotificationModal(),
    );
  }

  @override
  State<NotificationModal> createState() => _NotificationModalState();
}

class _NotificationModalState extends State<NotificationModal> {
  bool _clearAll = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final cardBgColor = isDark ? const Color(0xFF1E283C) : Colors.white;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final appConfigProvider = Provider.of<AppConfigProvider>(context, listen: false);
    final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);

    final List<Map<String, dynamic>> notifications = [];

    if (!_clearAll) {
      // System Maintenance / Announcement item
      if (appConfigProvider.isMaintenance) {
        notifications.add({
          'id': 'maint',
          'title': 'System Maintenance',
          'body': appConfigProvider.maintenanceMessage,
          'time': 'Active Now',
          'icon': Icons.warning_amber_rounded,
          'color': Colors.amber,
          'isUnread': true,
        });
      }

      // Default welcome notification
      notifications.add({
        'id': 'welcome',
        'title': 'Welcome to ${appConfigProvider.appName} 👋',
        'body': 'Enjoy seamless bill payments, instant airtime, data top-ups and wallet transfers!',
        'time': 'Just now',
        'icon': Icons.stars_rounded,
        'color': primaryColor,
        'isUnread': true,
      });

      // Recent transaction notifications
      for (final tx in dashboardProvider.recentTransactions.take(4)) {
        final isCredit = tx.type.toLowerCase() == 'credit';
        notifications.add({
          'id': 'tx_${tx.id}',
          'title': '${tx.type.toUpperCase()}: ${tx.serviceType.toUpperCase()}',
          'body': '${tx.description} - ${appConfigProvider.currencySymbol}${tx.amount}',
          'time': tx.formattedDate,
          'icon': isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
          'color': isCredit ? Colors.green : Colors.orange,
          'isUnread': false,
        });
      }
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bottom sheet handle
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title and Clear All header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.notifications_rounded, color: primaryColor, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Notifications',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  if (notifications.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _clearAll = true;
                        });
                      },
                      child: Text(
                        'Clear all',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Content list
              if (notifications.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ClayContainer(
                          borderRadius: 50,
                          depth: 8,
                          padding: const EdgeInsets.all(20),
                          color: isDark ? const Color(0xFF1E283C) : Colors.white,
                          child: Icon(
                            Icons.notifications_off_outlined,
                            size: 44,
                            color: subtextColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No new notifications',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'You\'re all caught up! Check back later for updates.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: subtextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = notifications[index];
                      final Color itemColor = item['color'] as Color;

                      return ClayContainer(
                        borderRadius: 18,
                        depth: 6,
                        padding: const EdgeInsets.all(14),
                        color: isDark ? const Color(0xFF1E283C) : Colors.white,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: itemColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                item['icon'] as IconData,
                                color: itemColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item['title'] as String,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                            color: textColor,
                                          ),
                                        ),
                                      ),
                                      if (item['isUnread'] == true)
                                        Container(
                                          margin: const EdgeInsets.only(left: 6),
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: primaryColor,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item['body'] as String,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: subtextColor,
                                      height: 1.3,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    item['time'] as String,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: subtextColor.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 16),
              ClayButton(
                text: 'Close',
                depth: 8,
                borderRadius: 16,
                color: isDark ? const Color(0xFF28354E) : const Color(0xFFE2E8F0),
                textColor: textColor,
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
