import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/app_config_provider.dart';
import '../../providers/specialized_provider.dart';
import '../widgets/clay_container.dart';
import '../widgets/clay_button.dart';

class VoucherHistoryScreen extends StatefulWidget {
  const VoucherHistoryScreen({super.key});

  @override
  State<VoucherHistoryScreen> createState() => _VoucherHistoryScreenState();
}

class _VoucherHistoryScreenState extends State<VoucherHistoryScreen> {
  String _selectedNetwork = 'all';
  final Set<int> _selectedVoucherIds = {};
  final Set<int> _revealedPinIds = {};
  bool _isDownloadingPdf = false;

  final List<Map<String, dynamic>> _networkFilters = [
    {'key': 'all', 'name': 'All', 'color': const Color(0xFF6366F1)},
    {'key': 'mtn', 'name': 'MTN', 'color': const Color(0xFFEAB308)},
    {'key': 'airtel', 'name': 'Airtel', 'color': const Color(0xFFEF4444)},
    {'key': 'glo', 'name': 'Glo', 'color': const Color(0xFF10B981)},
    {'key': 'etisalat', 'name': '9mobile', 'color': const Color(0xFF84CC16)},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadVouchers();
    });
  }

  Future<void> _loadVouchers() async {
    final spec = Provider.of<SpecializedProvider>(context, listen: false);
    await spec.fetchVoucherHistory(
      network: _selectedNetwork == 'all' ? null : _selectedNetwork,
      perPage: 100,
    );
  }

  void _onNetworkChanged(String net) {
    if (_selectedNetwork == net) return;
    setState(() {
      _selectedNetwork = net;
      _selectedVoucherIds.clear();
      _revealedPinIds.clear();
    });
    _loadVouchers();
  }

  void _toggleSelectAll(List<Map<String, dynamic>> vouchers) {
    setState(() {
      if (_selectedVoucherIds.length == vouchers.length) {
        _selectedVoucherIds.clear();
      } else {
        _selectedVoucherIds.clear();
        for (final v in vouchers) {
          final id = int.tryParse(v['id']?.toString() ?? '');
          if (id != null) _selectedVoucherIds.add(id);
        }
      }
    });
  }

  void _toggleSelectVoucher(int id) {
    setState(() {
      if (_selectedVoucherIds.contains(id)) {
        _selectedVoucherIds.remove(id);
      } else {
        _selectedVoucherIds.add(id);
      }
    });
  }

  void _toggleRevealPin(int id) {
    setState(() {
      if (_revealedPinIds.contains(id)) {
        _revealedPinIds.remove(id);
      } else {
        _revealedPinIds.add(id);
      }
    });
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _copyAllSelectedPins(List<Map<String, dynamic>> vouchers) {
    final selectedVouchers = vouchers.where((v) {
      final id = int.tryParse(v['id']?.toString() ?? '');
      return id != null && _selectedVoucherIds.contains(id);
    }).toList();

    final targetList = selectedVouchers.isNotEmpty ? selectedVouchers : vouchers;
    if (targetList.isEmpty) return;

    final buffer = StringBuffer();
    for (final v in targetList) {
      final net = (v['network'] ?? '').toString().toUpperCase();
      final val = v['value'] ?? '';
      final pin = v['pin'] ?? '';
      final sn = v['serial_number'] ?? '';
      buffer.writeln('$net ₦$val PIN: $pin (S/N: $sn)');
    }

    _copyToClipboard(buffer.toString().trim(), '${targetList.length} Voucher PIN(s)');
  }

  Future<void> _downloadPdf() async {
    setState(() => _isDownloadingPdf = true);
    try {
      final spec = Provider.of<SpecializedProvider>(context, listen: false);
      final List<int>? ids = _selectedVoucherIds.isNotEmpty ? _selectedVoucherIds.toList() : null;
      final url = await spec.getVoucherPdfUrl(ids: ids);

      final uri = Uri.parse(url);
      final canLaunch = await canLaunchUrl(uri);
      if (canLaunch) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open PDF download: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloadingPdf = false);
      }
    }
  }

  Color _getNetworkColor(String? network) {
    switch (network?.toLowerCase()) {
      case 'mtn':
        return const Color(0xFFEAB308);
      case 'airtel':
        return const Color(0xFFEF4444);
      case 'glo':
        return const Color(0xFF10B981);
      case 'etisalat':
      case '9mobile':
        return const Color(0xFF84CC16);
      default:
        return const Color(0xFF6366F1);
    }
  }

  String _formatPin(String pin) {
    final clean = pin.replaceAll(' ', '');
    final chunks = <String>[];
    for (int i = 0; i < clean.length; i += 4) {
      final end = (i + 4 < clean.length) ? i + 4 : clean.length;
      chunks.add(clean.substring(i, end));
    }
    return chunks.join(' ');
  }

  String _maskPin(String pin) {
    final clean = pin.replaceAll(' ', '');
    if (clean.length <= 4) return '••••';
    final maskedPrefix = '•' * (clean.length - 4);
    final lastFour = clean.substring(clean.length - 4);
    final combined = maskedPrefix + lastFour;
    return _formatPin(combined);
  }

  String _formatDate(dynamic dateVal) {
    if (dateVal == null) return '';
    try {
      final dt = DateTime.parse(dateVal.toString()).toLocal();
      return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
    } catch (_) {
      return dateVal.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final spec = Provider.of<SpecializedProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final vouchers = spec.vouchers;
    final isLoading = spec.isLoadingVouchers;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchased Vouchers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: isLoading ? null : _loadVouchers,
          ),
          if (vouchers.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (value) {
                if (value == 'copy_all') {
                  _copyAllSelectedPins(vouchers);
                } else if (value == 'select_all') {
                  _toggleSelectAll(vouchers);
                }
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: 'select_all',
                  child: Row(
                    children: [
                      Icon(
                        _selectedVoucherIds.length == vouchers.length
                            ? Icons.deselect_rounded
                            : Icons.select_all_rounded,
                        size: 20,
                        color: primaryColor,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _selectedVoucherIds.length == vouchers.length
                            ? 'Deselect All'
                            : 'Select All',
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'copy_all',
                  child: const Row(
                    children: [
                      Icon(Icons.copy_all_rounded, size: 20, color: Color(0xFF10B981)),
                      SizedBox(width: 10),
                      Text('Copy Selected PINs'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Network Filter Tabs
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _networkFilters.map((net) {
                    final isSelected = _selectedNetwork == net['key'];
                    final color = net['color'] as Color;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => _onNetworkChanged(net['key'] as String),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color.withValues(alpha: 0.18)
                                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? color : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            net['name'] as String,
                            style: TextStyle(
                              color: isSelected
                                  ? color
                                  : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // Selection & Info Banner
            if (vouchers.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Text(
                      '${vouchers.length} voucher${vouchers.length == 1 ? '' : 's'} available',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                    const Spacer(),
                    if (_selectedVoucherIds.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_selectedVoucherIds.length} selected',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    TextButton(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      onPressed: () => _toggleSelectAll(vouchers),
                      child: Text(
                        _selectedVoucherIds.length == vouchers.length ? 'Clear' : 'Select All',
                        style: TextStyle(fontSize: 12, color: primaryColor),
                      ),
                    ),
                  ],
                ),
              ),

            // Main List / States
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : vouchers.isEmpty
                      ? _buildEmptyState(isDark)
                      : RefreshIndicator(
                          onRefresh: _loadVouchers,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                            itemCount: vouchers.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (ctx, index) {
                              final voucher = vouchers[index];
                              return _buildVoucherCard(voucher, isDark, primaryColor);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
      bottomSheet: vouchers.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: ClayButton(
                  height: 52,
                  depth: 10,
                  color: primaryColor,
                  isLoading: _isDownloadingPdf,
                  onTap: _downloadPdf,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        _selectedVoucherIds.isNotEmpty
                            ? 'Download Selected as PDF (${_selectedVoucherIds.length})'
                            : 'Download All as PDF (A4 - 5 Cols)',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.confirmation_number_outlined,
                size: 64,
                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Vouchers Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedNetwork == 'all'
                  ? 'You have not purchased any recharge card vouchers yet.'
                  : 'No vouchers found for ${_selectedNetwork.toUpperCase()}.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
              label: const Text('Generate Recharge Pins'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoucherCard(Map<String, dynamic> v, bool isDark, Color primaryColor) {
    final id = int.tryParse(v['id']?.toString() ?? '') ?? 0;
    final isSelected = _selectedVoucherIds.contains(id);
    final isPinRevealed = _revealedPinIds.contains(id);

    final network = (v['network'] ?? 'MTN').toString().toUpperCase();
    final netColor = _getNetworkColor(network);
    final value = v['value']?.toString() ?? '0';
    final pin = (v['pin'] ?? '').toString();
    final serialNumber = (v['serial_number'] ?? 'N/A').toString();
    final dateStr = _formatDate(v['created_at']);
    final status = (v['status'] ?? 'active').toString().toUpperCase();

    // Default Nigerian USSD dial code: *311*PIN#
    final dialInstruction = 'Dial: *311*PIN#';

    return GestureDetector(
      onTap: () {
        if (id != 0) _toggleSelectVoucher(id);
      },
      child: ClayContainer(
        depth: isSelected ? 10 : 4,
        cornerRadius: 18,
        color: isSelected
            ? netColor.withValues(alpha: 0.08)
            : (isDark ? const Color(0xFF1E293B) : Colors.white),
        borderColor: isSelected ? netColor : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        borderWidth: isSelected ? 1.5 : 1.0,
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Network badge, Value, and Checkbox
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: netColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(radius: 4, backgroundColor: netColor),
                        const SizedBox(width: 6),
                        Text(
                          network,
                          style: TextStyle(
                            color: netColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '₦$value',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: status == 'ACTIVE'
                          ? const Color(0xFF10B981).withValues(alpha: 0.15)
                          : const Color(0xFF64748B).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: status == 'ACTIVE' ? const Color(0xFF10B981) : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () {
                      if (id != 0) _toggleSelectVoucher(id);
                    },
                    child: Icon(
                      isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                      color: isSelected ? netColor : const Color(0xFF94A3B8),
                      size: 22,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // PIN Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.password_rounded, size: 18, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isPinRevealed ? _formatPin(pin) : _maskPin(pin),
                        style: TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 15,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        isPinRevealed ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        size: 20,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                      tooltip: isPinRevealed ? 'Hide PIN' : 'Show PIN',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _toggleRevealPin(id),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 20, color: Color(0xFF6366F1)),
                      tooltip: 'Copy PIN',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _copyToClipboard(pin, 'Recharge PIN'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Details: Serial Number, Dial code, Date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () => _copyToClipboard(serialNumber, 'Serial Number'),
                    child: Row(
                      children: [
                        Text(
                          'S/N: $serialNumber',
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'Courier',
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.copy_rounded,
                          size: 12,
                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    dialInstruction,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: netColor,
                    ),
                  ),
                ],
              ),
              if (dateStr.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
