import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/app_config_provider.dart';
import '../../providers/bills_provider.dart';
import '../widgets/clay_container.dart';
import '../widgets/clay_button.dart';

class ExamPinsHistoryScreen extends StatefulWidget {
  const ExamPinsHistoryScreen({super.key});

  @override
  State<ExamPinsHistoryScreen> createState() => _ExamPinsHistoryScreenState();
}

class _ExamPinsHistoryScreenState extends State<ExamPinsHistoryScreen> {
  String _selectedExamType = 'all';
  final Set<int> _selectedTxIds = {};
  final Set<String> _revealedPins = {};
  bool _isDownloadingPdf = false;

  final List<Map<String, dynamic>> _examFilters = [
    {'key': 'all', 'name': 'All', 'color': const Color(0xFF6366F1)},
    {'key': 'waec', 'name': 'WAEC', 'color': const Color(0xFF2563EB)},
    {'key': 'neco', 'name': 'NECO', 'color': const Color(0xFF10B981)},
    {'key': 'nabteb', 'name': 'NABTEB', 'color': const Color(0xFFF59E0B)},
    {'key': 'jamb', 'name': 'JAMB', 'color': const Color(0xFF8B5CF6)},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHistory();
    });
  }

  Future<void> _loadHistory() async {
    final bills = Provider.of<BillsProvider>(context, listen: false);
    await bills.fetchExamPinHistory(
      examType: _selectedExamType == 'all' ? null : _selectedExamType,
      perPage: 50,
    );
  }

  void _onFilterChanged(String key) {
    if (_selectedExamType == key) return;
    setState(() {
      _selectedExamType = key;
      _selectedTxIds.clear();
      _revealedPins.clear();
    });
    _loadHistory();
  }

  void _toggleSelectAll(List<Map<String, dynamic>> items) {
    setState(() {
      if (_selectedTxIds.length == items.length) {
        _selectedTxIds.clear();
      } else {
        _selectedTxIds.clear();
        for (final item in items) {
          final id = int.tryParse(item['id']?.toString() ?? '');
          if (id != null) _selectedTxIds.add(id);
        }
      }
    });
  }

  void _toggleSelectTx(int id) {
    setState(() {
      if (_selectedTxIds.contains(id)) {
        _selectedTxIds.remove(id);
      } else {
        _selectedTxIds.add(id);
      }
    });
  }

  void _toggleRevealPin(String pinKey) {
    setState(() {
      if (_revealedPins.contains(pinKey)) {
        _revealedPins.remove(pinKey);
      } else {
        _revealedPins.add(pinKey);
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

  void _copyAllSelectedPins(List<Map<String, dynamic>> items) {
    final selectedItems = items.where((tx) {
      final id = int.tryParse(tx['id']?.toString() ?? '');
      return id != null && _selectedTxIds.contains(id);
    }).toList();

    final targetList = selectedItems.isNotEmpty ? selectedItems : items;
    if (targetList.isEmpty) return;

    final buffer = StringBuffer();
    int count = 0;

    for (final tx in targetList) {
      final examName = tx['exam_name'] ?? 'Exam PIN';
      final pins = (tx['pins'] as List<dynamic>?) ?? [];

      for (final p in pins) {
        final pinMap = p is Map ? Map<String, dynamic>.from(p) : {'pin': p.toString()};
        final pin = pinMap['pin'] ?? '';
        final serial = pinMap['serial'];
        count++;

        if (serial != null && serial.toString().isNotEmpty) {
          buffer.writeln('$examName - PIN: $pin (S/N: $serial)');
        } else {
          buffer.writeln('$examName - PIN: $pin');
        }
      }
    }

    if (count > 0) {
      _copyToClipboard(buffer.toString().trim(), '$count Exam PIN(s)');
    }
  }

  Future<void> _downloadPdf() async {
    setState(() => _isDownloadingPdf = true);
    try {
      final bills = Provider.of<BillsProvider>(context, listen: false);
      final List<int>? ids = _selectedTxIds.isNotEmpty ? _selectedTxIds.toList() : null;
      final url = await bills.getExamPinPdfUrl(ids: ids);

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

  Color _getExamColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'waec':
        return const Color(0xFF2563EB);
      case 'neco':
        return const Color(0xFF10B981);
      case 'nabteb':
        return const Color(0xFFF59E0B);
      case 'jamb':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF6366F1);
    }
  }

  String _formatPin(String pin) {
    final clean = pin.replaceAll(' ', '');
    if (clean.length < 10) return clean;
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
    return _formatPin(maskedPrefix + lastFour);
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

  String _getPortalInfo(String? type) {
    switch (type?.toLowerCase()) {
      case 'waec':
        return 'waecdirect.org';
      case 'neco':
        return 'results.neco.gov.ng';
      case 'nabteb':
        return 'eworld.nabtebnigeria.org';
      case 'jamb':
        return 'efacility.jamb.gov.ng';
      default:
        return 'Official Exam Portal';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bills = Provider.of<BillsProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final items = bills.examPinTransactions;
    final isLoading = bills.isLoadingExamHistory;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchased Exam PINs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: isLoading ? null : _loadHistory,
          ),
          if (items.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (value) {
                if (value == 'copy_all') {
                  _copyAllSelectedPins(items);
                } else if (value == 'select_all') {
                  _toggleSelectAll(items);
                }
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: 'select_all',
                  child: Row(
                    children: [
                      Icon(
                        _selectedTxIds.length == items.length
                            ? Icons.deselect_rounded
                            : Icons.select_all_rounded,
                        size: 20,
                        color: primaryColor,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _selectedTxIds.length == items.length ? 'Deselect All' : 'Select All',
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
            // Filter chips
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _examFilters.map((flt) {
                    final isSelected = _selectedExamType == flt['key'];
                    final color = flt['color'] as Color;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => _onFilterChanged(flt['key'] as String),
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
                            flt['name'] as String,
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

            // Selection bar
            if (items.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Text(
                      '${items.length} transaction${items.length == 1 ? '' : 's'}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                    const Spacer(),
                    if (_selectedTxIds.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_selectedTxIds.length} selected',
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
                      onPressed: () => _toggleSelectAll(items),
                      child: Text(
                        _selectedTxIds.length == items.length ? 'Clear' : 'Select All',
                        style: TextStyle(fontSize: 12, color: primaryColor),
                      ),
                    ),
                  ],
                ),
              ),

            // Main List
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : items.isEmpty
                      ? _buildEmptyState(isDark)
                      : RefreshIndicator(
                          onRefresh: _loadHistory,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                            itemCount: items.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 14),
                            itemBuilder: (ctx, index) {
                              final tx = items[index];
                              return _buildTransactionCard(tx, isDark, primaryColor);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
      bottomSheet: items.isNotEmpty
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
                        _selectedTxIds.isNotEmpty
                            ? 'Download Selected as PDF (${_selectedTxIds.length})'
                            : 'Download All Exam PINs as PDF (A4)',
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
                Icons.school_outlined,
                size: 64,
                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Exam PINs Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedExamType == 'all'
                  ? 'You have not purchased any exam checker PINs yet.'
                  : 'No exam PINs found for ${_selectedExamType.toUpperCase()}.',
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
              label: const Text('Purchase Exam PINs'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> tx, bool isDark, Color primaryColor) {
    final id = int.tryParse(tx['id']?.toString() ?? '') ?? 0;
    final isSelected = _selectedTxIds.contains(id);

    final examType = (tx['exam_type'] ?? 'waec').toString().toLowerCase();
    final examName = (tx['exam_name'] ?? 'Exam PIN').toString();
    final examColor = _getExamColor(examType);
    final amount = double.tryParse(tx['amount']?.toString() ?? '') ?? 0.0;
    final quantity = int.tryParse(tx['quantity']?.toString() ?? '') ?? 1;
    final status = (tx['status'] ?? 'success').toString().toUpperCase();
    final dateStr = _formatDate(tx['created_at']);
    final reference = tx['reference']?.toString() ?? '';
    final portalUrl = _getPortalInfo(examType);

    final rawPins = (tx['pins'] as List<dynamic>?) ?? [];
    final List<Map<String, dynamic>> pins = rawPins.map((p) {
      if (p is Map) return Map<String, dynamic>.from(p);
      return {'pin': p.toString(), 'serial': null};
    }).toList();

    final configProvider = Provider.of<AppConfigProvider>(context, listen: false);
    final currency = configProvider.currencySymbol;

    return GestureDetector(
      onTap: () {
        if (id != 0) _toggleSelectTx(id);
      },
      child: ClayContainer(
        depth: isSelected ? 10 : 4,
        cornerRadius: 18,
        color: isSelected
            ? examColor.withValues(alpha: 0.08)
            : (isDark ? const Color(0xFF1E293B) : Colors.white),
        borderColor: isSelected ? examColor : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        borderWidth: isSelected ? 1.5 : 1.0,
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Exam badge, Title, and Checkbox
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: examColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      examType.toUpperCase(),
                      style: TextStyle(
                        color: examColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      examName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      if (id != 0) _toggleSelectTx(id);
                    },
                    child: Icon(
                      isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                      color: isSelected ? examColor : const Color(0xFF94A3B8),
                      size: 22,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Info line: Quantity, Total Amount, Date, Status
              Row(
                children: [
                  Text(
                    '$quantity card${quantity > 1 ? 's' : ''} • $currency${amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: status == 'SUCCESS'
                          ? const Color(0xFF10B981).withValues(alpha: 0.15)
                          : const Color(0xFFEF4444).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: status == 'SUCCESS' ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Generated PINs List
              if (pins.isNotEmpty) ...[
                ...pins.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final p = entry.value;
                  final pinStr = (p['pin'] ?? '').toString();
                  final serialStr = p['serial']?.toString();
                  final pinKey = '${id}_$idx';
                  final isRevealed = _revealedPins.contains(pinKey);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'PIN ${idx + 1}:',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: examColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isRevealed ? _formatPin(pinStr) : _maskPin(pinStr),
                                style: TextStyle(
                                  fontFamily: 'Courier',
                                  fontSize: 14,
                                  letterSpacing: 1.1,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                isRevealed ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                size: 18,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                              visualDensity: VisualDensity.compact,
                              tooltip: isRevealed ? 'Hide' : 'Reveal',
                              onPressed: () => _toggleRevealPin(pinKey),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy_rounded, size: 18, color: Color(0xFF6366F1)),
                              visualDensity: VisualDensity.compact,
                              tooltip: 'Copy PIN',
                              onPressed: () => _copyToClipboard(pinStr, 'Exam PIN'),
                            ),
                          ],
                        ),
                        if (serialStr != null && serialStr.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          InkWell(
                            onTap: () => _copyToClipboard(serialStr, 'Serial Number'),
                            child: Row(
                              children: [
                                Text(
                                  'S/N: $serialStr',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontFamily: 'Courier',
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.copy_rounded,
                                  size: 11,
                                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              ],

              // Footer: Portal instruction & Ref & Date
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'Portal: $portalUrl',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: examColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
