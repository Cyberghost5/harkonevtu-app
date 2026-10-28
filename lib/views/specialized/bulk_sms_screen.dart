import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/specialized_provider.dart';
import '../../providers/app_config_provider.dart';
import '../../providers/auth_provider.dart';
import '../widgets/transaction_pin_modal.dart';
import '../widgets/clay_container.dart';
import '../widgets/clay_button.dart';
import '../widgets/clay_text_field.dart';
import '../transaction_status_screen.dart';

class BulkSmsScreen extends StatefulWidget {
  const BulkSmsScreen({super.key});

  @override
  State<BulkSmsScreen> createState() => _BulkSmsScreenState();
}

class _BulkSmsScreenState extends State<BulkSmsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final TextEditingController _senderController = TextEditingController();
  final TextEditingController _recipientsController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  List<String> _validRecipients = [];
  int _duplicatesCount = 0;
  int _invalidCount = 0;

  int _charCount = 0;
  int _pageCount = 1;
  bool _isUnicode = false;

  bool _isLoadingHistory = false;
  List<Map<String, dynamic>> _historyCampaigns = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPricing();
      _loadHistory();
    });

    _recipientsController.addListener(_onRecipientsChanged);
    _messageController.addListener(_onMessageChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _senderController.dispose();
    _recipientsController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _loadPricing() async {
    final spec = Provider.of<SpecializedProvider>(context, listen: false);
    await spec.fetchBulkSmsPricing();
    if (_senderController.text.isEmpty && spec.defaultSenderId.isNotEmpty) {
      setState(() {
        _senderController.text = spec.defaultSenderId;
      });
    }
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoadingHistory = true);
    final spec = Provider.of<SpecializedProvider>(context, listen: false);
    final res = await spec.fetchBulkSmsHistory();

    if (mounted) {
      if (res.status && res.data != null && res.data is Map<String, dynamic>) {
        final campaigns = (res.data['campaigns'] as List<dynamic>?) ?? [];
        setState(() {
          _historyCampaigns = campaigns.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          _isLoadingHistory = false;
        });
      } else {
        setState(() => _isLoadingHistory = false);
      }
    }
  }

  void _onRecipientsChanged() {
    final text = _recipientsController.text;
    final rawTokens = text.split(RegExp(r'[\s,;|]+'));

    final Set<String> validSet = {};
    int dups = 0;
    int invalid = 0;

    for (var raw in rawTokens) {
      var cleaned = raw.replaceAll(RegExp(r'[^0-9+]'), '').trim();
      if (cleaned.isEmpty) continue;

      if (cleaned.startsWith('+234')) {
        cleaned = cleaned.substring(1);
      } else if (cleaned.startsWith('0') && cleaned.length == 11) {
        cleaned = '234${cleaned.substring(1)}';
      } else if (cleaned.length == 10 && RegExp(r'^[789]').hasMatch(cleaned)) {
        cleaned = '234$cleaned';
      }

      // 234 + 10 digits (13 digits) or valid international (10-15 digits)
      if (RegExp(r'^234[789][01]\d{8}$').hasMatch(cleaned) || RegExp(r'^\d{10,15}$').hasMatch(cleaned)) {
        if (validSet.contains(cleaned)) {
          dups++;
        } else {
          validSet.add(cleaned);
        }
      } else {
        invalid++;
      }
    }

    setState(() {
      _validRecipients = validSet.toList();
      _duplicatesCount = dups;
      _invalidCount = invalid;
    });
  }

  void _onMessageChanged() {
    final text = _messageController.text;
    final len = text.characters.length;

    // Check for Unicode (emojis or non-ASCII characters)
    final isUnicode = RegExp(r'[^\x20-\x7E\r\n\t]').hasMatch(text);
    final singleLimit = isUnicode ? 70 : 160;
    final concatLimit = isUnicode ? 67 : 153;

    int pages = 1;

    if (len > 0) {
      if (len <= singleLimit) {
        pages = 1;
      } else {
        pages = (len / concatLimit).ceil();
      }
    }

    setState(() {
      _charCount = len;
      _isUnicode = isUnicode;
      _pageCount = pages < 1 ? 1 : pages;
    });
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      final current = _recipientsController.text.trim();
      if (current.isEmpty) {
        _recipientsController.text = data.text!;
      } else {
        _recipientsController.text = '$current, ${data.text!}';
      }
    }
  }

  void _confirmAndSend() {
    final sender = _senderController.text.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').trim();
    final message = _messageController.text.trim();

    if (sender.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an alphanumeric Sender ID (max 11 characters).')),
      );
      return;
    }

    if (_validRecipients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide at least one valid recipient phone number.')),
      );
      return;
    }

    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your message body.')),
      );
      return;
    }

    final specProvider = Provider.of<SpecializedProvider>(context, listen: false);
    final configProvider = Provider.of<AppConfigProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final totalCost = _validRecipients.length * _pageCount * specProvider.bulkSmsRate;
    final walletBal = authProvider.user?.balance ?? 0.0;

    if (walletBal < totalCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Insufficient balance. Total cost is ${configProvider.currencySymbol}${totalCost.toStringAsFixed(2)}, but your wallet balance is ${configProvider.currencySymbol}${walletBal.toStringAsFixed(2)}.'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TransactionPinModal(
        title: 'Bulk SMS: ${_validRecipients.length} Recipient(s) ($_pageCount pg)',
        amountText: '${configProvider.currencySymbol}${totalCost.toStringAsFixed(2)}',
        onPinConfirmed: (pin) => _executeBroadcast(sender, message, totalCost, pin),
      ),
    );
  }

  void _executeBroadcast(String sender, String message, double totalCost, String pin) {
    final specProvider = Provider.of<SpecializedProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final recipientsStr = _validRecipients.join(',');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TransactionStatusScreen(
          title: 'Bulk SMS Campaign',
          serviceType: 'Bulk SMS',
          planName: '${_validRecipients.length} Recipients ($_pageCount page${_pageCount > 1 ? 's' : ''})',
          recipient: sender,
          amount: totalCost,
          action: () async {
            final res = await specProvider.sendBulkSms(
              senderId: sender,
              message: message,
              recipients: recipientsStr,
              pin: pin,
            );
            // Refresh history and wallet on success
            if (res.status) {
              _loadHistory();
              authProvider.fetchProfile();
            }
            return res;
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final configProvider = Provider.of<AppConfigProvider>(context);
    final specProvider = Provider.of<SpecializedProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    final currency = configProvider.currencySymbol;
    final unitRate = specProvider.bulkSmsRate;
    final totalCost = _validRecipients.length * _pageCount * unitRate;
    final walletBalance = authProvider.user?.balance ?? 0.0;
    final hasEnoughBalance = walletBalance >= totalCost;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Bulk SMS Portal',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: primaryColor,
          labelColor: primaryColor,
          unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.send_rounded, size: 20), text: 'Send Campaign'),
            Tab(icon: Icon(Icons.history_rounded, size: 20), text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ─── TAB 1: COMPOSE & SEND ─────────────────────────────────────────
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info & Rate Header Banner
                ClayContainer(
                  borderRadius: 16,
                  padding: const EdgeInsets.all(16),
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.sms_rounded, color: primaryColor, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SMS Rate: $currency${unitRate.toStringAsFixed(2)} / unit',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Wallet: $currency${walletBalance.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: hasEnoughBalance ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Sender ID
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'SENDER ID',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    Text(
                      '${_senderController.text.length}/11 chars',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClayTextField(
                  controller: _senderController,
                  hintText: 'e.g. MyStore',
                  maxLength: 11,
                  onChanged: (val) {
                    final clean = val.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
                    if (clean != val) {
                      _senderController.value = TextEditingValue(
                        text: clean,
                        selection: TextSelection.collapsed(offset: clean.length),
                      );
                    }
                    setState(() {});
                  },
                ),
                const SizedBox(height: 16),

                // Recipients
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'RECIPIENT NUMBERS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    InkWell(
                      onTap: _pasteFromClipboard,
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        child: Row(
                          children: [
                            Icon(Icons.content_paste_rounded, size: 14, color: primaryColor),
                            const SizedBox(width: 4),
                            Text(
                              'Paste Numbers',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClayTextField(
                  controller: _recipientsController,
                  hintText: 'Enter phone numbers separated by comma, space, or new line\ne.g. 08031234567, 08123456789',
                  maxLines: 4,
                  keyboardType: TextInputType.multiline,
                ),
                const SizedBox(height: 8),

                // Recipients Counter Badges
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        'Valid Numbers: ${_validRecipients.length}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ),
                    if (_duplicatesCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          'Filtered Dups: $_duplicatesCount',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                      ),
                    if (_invalidCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          'Invalid: $_invalidCount',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Message Body
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'MESSAGE BODY',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    Text(
                      '$_charCount chars ($_pageCount pg) • ${_isUnicode ? 'Unicode' : 'GSM'}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _isUnicode ? Colors.amber : Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClayTextField(
                  controller: _messageController,
                  hintText: 'Type your message text here...',
                  maxLines: 5,
                  maxLength: 1000,
                  keyboardType: TextInputType.multiline,
                ),
                const SizedBox(height: 16),

                // Cost Summary Card
                ClayContainer(
                  borderRadius: 16,
                  padding: const EdgeInsets.all(16),
                  color: isDark ? const Color(0xFF0F172A) : Colors.white,
                  child: Column(
                    children: [
                      _buildSummaryRow('Recipients Count', '${_validRecipients.length} numbers', isDark),
                      const SizedBox(height: 8),
                      _buildSummaryRow('Message Pages', '$_pageCount page${_pageCount > 1 ? 's' : ''}', isDark),
                      const SizedBox(height: 8),
                      _buildSummaryRow('Unit Selling Rate', '$currency${unitRate.toStringAsFixed(2)} / unit', isDark),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Estimated Total Cost',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          Text(
                            '$currency${totalCost.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                      if (!hasEnoughBalance && _validRecipients.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 16),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Insufficient wallet balance. Please top up your wallet.',
                                  style: TextStyle(fontSize: 11, color: Color(0xFFEF4444), fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Submit Button
                ClayButton(
                  onPressed: (_validRecipients.isNotEmpty &&
                          _messageController.text.trim().isNotEmpty &&
                          _senderController.text.trim().isNotEmpty &&
                          hasEnoughBalance)
                      ? _confirmAndSend
                      : null,
                  text: 'Broadcast Campaign',
                  icon: Icons.send_rounded,
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),

          // ─── TAB 2: CAMPAIGN HISTORY ───────────────────────────────────────
          _isLoadingHistory
              ? const Center(child: CircularProgressIndicator())
              : _historyCampaigns.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.mark_email_read_outlined, size: 64, color: Colors.grey.withValues(alpha: 0.5)),
                          const SizedBox(height: 12),
                          const Text(
                            'No Bulk SMS campaigns sent yet.',
                            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadHistory,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _historyCampaigns.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final c = _historyCampaigns[index];
                          final isSent = (c['status'] ?? '').toString().toLowerCase() == 'sent';
                          final dateStr = c['created_at'] != null
                              ? DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(c['created_at']))
                              : 'Recent';

                          return ClayContainer(
                            borderRadius: 14,
                            padding: const EdgeInsets.all(14),
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: primaryColor.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            c['sender_id'] ?? 'VTU',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: primaryColor,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${c['recipient_count'] ?? 0} Recipient(s)',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? Colors.white70 : Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isSent
                                            ? const Color(0xFF10B981).withValues(alpha: 0.12)
                                            : const Color(0xFFEF4444).withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        isSent ? 'SENT' : 'FAILED',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: isSent ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  c['message_preview'] ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.white60 : Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      dateStr,
                                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
                                    Text(
                                      '$currency${(c['total_amount'] as num?)?.toDouble().toStringAsFixed(2) ?? '0.00'}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white60 : Colors.black54,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }
}
