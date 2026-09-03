import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_config_provider.dart';
import '../vtu/airtime_topup_screen.dart';
import '../vtu/data_bundles_screen.dart';
import '../bills/electricity_bills_screen.dart';
import '../bills/cable_tv_screen.dart';
import '../bills/exam_pins_screen.dart';
import '../specialized/betting_topup_screen.dart';
import '../specialized/airtime_to_cash_screen.dart';
import '../specialized/voucher_printing_screen.dart';

class ServicesGridView extends StatelessWidget {
  const ServicesGridView({super.key});

  @override
  Widget build(BuildContext context) {
    final configProvider = Provider.of<AppConfigProvider>(context);
    final services = configProvider.config?.services;

    final allServices = <Map<String, dynamic>>[
      {
        'key': 'airtime',
        'title': 'Airtime Topup',
        'desc': 'Instant airtime for MTN, Airtel, Glo & 9mobile',
        'icon': Icons.phone_android_rounded,
        'color': const Color(0xFF3B82F6),
        'enabled': services?.airtime ?? true,
      },
      {
        'key': 'data',
        'title': 'Data Bundles',
        'desc': 'Buy SME, Gifting & Corporate data plans',
        'icon': Icons.wifi_rounded,
        'color': const Color(0xFF10B981),
        'enabled': services?.data ?? true,
      },
      {
        'key': 'electricity',
        'title': 'Electricity Bills',
        'desc': 'Pay Prepaid/Postpaid Disco meter tokens',
        'icon': Icons.lightbulb_rounded,
        'color': const Color(0xFFA855F7),
        'enabled': services?.electricity ?? true,
      },
      {
        'key': 'cable',
        'title': 'Cable TV Subscription',
        'desc': 'Renew DSTV, GOtv, StarTimes & Showmax',
        'icon': Icons.tv_rounded,
        'color': const Color(0xFFF59E0B),
        'enabled': services?.cable ?? true,
      },
      {
        'key': 'epin',
        'title': 'Exam PIN Scratch Cards',
        'desc': 'Purchase WAEC, NECO & NABTEB result pins',
        'icon': Icons.school_rounded,
        'color': const Color(0xFFEC4899),
        'enabled': services?.epin ?? true,
      },
      {
        'key': 'betting',
        'title': 'Betting Wallet Topup',
        'desc': 'Fund SportyBet, 1xBet, Bet9ja & BangBet',
        'icon': Icons.sports_soccer_rounded,
        'color': const Color(0xFF06B6D4),
        'enabled': services?.betting ?? true,
      },
      {
        'key': 'airtime_to_cash',
        'title': 'Airtime to Cash',
        'desc': 'Convert excess phone airtime to bank money',
        'icon': Icons.currency_exchange_rounded,
        'color': const Color(0xFF84CC16),
        'enabled': services?.airtimeToCash ?? true,
      },
      {
        'key': 'recharge_card_printing',
        'title': 'Print Recharge Cards',
        'desc': 'Generate physical paper pins & serials',
        'icon': Icons.print_rounded,
        'color': const Color(0xFF6366F1),
        'enabled': services?.rechargeCardPrinting ?? false,
      },
    ];

    final activeServices = allServices.where((s) => s['enabled'] == true).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Services'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Available VTU Services',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Select a service below to perform instant automated transactions',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              ),
              const SizedBox(height: 24),

              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: activeServices.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final service = activeServices[index];
                  final serviceColor = service['color'] as Color;

                  return GestureDetector(
                    onTap: () {
                      final key = service['key'] as String;
                      if (key == 'airtime') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AirtimeTopupScreen()),
                        );
                      } else if (key == 'data') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const DataBundlesScreen()),
                        );
                      } else if (key == 'electricity') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ElectricityBillsScreen()),
                        );
                      } else if (key == 'cable') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CableTvScreen()),
                        );
                      } else if (key == 'epin') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ExamPinsScreen()),
                        );
                      } else if (key == 'betting') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const BettingTopupScreen()),
                        );
                      } else if (key == 'airtime_to_cash') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AirtimeToCashScreen()),
                        );
                      } else if (key == 'recharge_card_printing') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const VoucherPrintingScreen()),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A2234),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFF232D42)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: serviceColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(service['icon'] as IconData, color: serviceColor, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  service['title'] as String,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  service['desc'] as String,
                                  style: const TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: Color(0xFF64748B)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
