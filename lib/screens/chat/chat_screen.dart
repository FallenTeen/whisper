import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/chat/message_bubble.dart';
import '../../widgets/chat/chat_input.dart';
import '../../providers/chat_provider.dart';
import '../../services/auth_service.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

int? currentUserId;

class ChatScreen extends StatefulWidget {
  final int roomId;
  final String partnerName;

  const ChatScreen({Key? key, required this.roomId, required this.partnerName})
    : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  static const _primaryColor = Color(0xFF6366F1);
  static const _primaryLight = Color(0xFF818CF8);
  static const _surfaceColor = Color(0xFFF8FAFC);
  static const _surfaceSecondary = Color(0xFFF1F5F9);

  static const _textPrimary = Color(0xFF0F172A);
  static const _textSecondary = Color(0xFF64748B);
  static const _textTertiary = Color(0xFF94A3B8);

  static const _encryptedColor = Color(0xFF7C3AED);
  static const _encryptedLight = Color(0xFFA855F7);
  static const _successColor = Color(0xFF10B981);
  static const _warningColor = Color(0xFFF59E0B);
  static const _errorColor = Color(0xFFEF4444);

  static const _bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );
  static const _bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );
  static const _captionLarge = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
  );
  static const _headingSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  static const double _space4 = 4.0;
  static const double _space8 = 8.0;
  static const double _space12 = 12.0;
  static const double _space16 = 16.0;
  static const double _space20 = 20.0;
  static const double _space24 = 24.0;
  static const double _space32 = 32.0;

  static const double _radiusSmall = 4.0;
  static const double _radiusMedium = 8.0;
  static const double _radiusLarge = 12.0;
  static const double _radiusXLarge = 16.0;

  static final List<BoxShadow> _shadowSmall = [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  static final List<BoxShadow> _shadowMedium = [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  bool modeWhisper = false;
  bool isWhisperTerautentikasi = false;
  bool _isValidasiKataSandi = false;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _passwordController = TextEditingController();
  late AnimationController _whisperAnimationController;
  late Animation<double> _whisperScaleAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _whisperAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _whisperScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _whisperAnimationController,
        curve: Curves.elasticOut,
      ),
    );
    _loadCurrentUserId();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMessages();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    _passwordController.dispose();
    _whisperAnimationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadMessages();
    }
  }

  Future<void> _loadCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user_data');
    if (userJson != null) {
      final userMap = json.decode(userJson);
      setState(() {
        currentUserId = userMap['id'];
      });
    }
  }

  Future<void> _loadMessages() async {
    await Provider.of<ChatProvider>(
      context,
      listen: false,
    ).fetchMessages(widget.roomId);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _sendMessage(String text, bool encrypt) async {
    try {
      await Provider.of<ChatProvider>(
        context,
        listen: false,
      ).sendMessage(widget.roomId, text, encrypt: encrypt);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          'Gagal mengirim pesan whispered: ${e.toString()}',
          _errorColor,
          Icons.error_outline,
        );
      }
    }
  }

  void _showSnackBar(String message, Color backgroundColor, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: _space16),
            const SizedBox(width: _space8),
            Expanded(
              child: Text(
                message,
                style: _bodyMedium.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(_space16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusLarge),
        ),
        elevation: 4,
      ),
    );
  }

  Future<void> _showPasswordDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AnimatedBuilder(
              animation: _whisperAnimationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _whisperScaleAnimation.value,
                  child: AlertDialog(
                    backgroundColor: _surfaceColor,
                    surfaceTintColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(_radiusXLarge),
                    ),
                    elevation: 8,
                    title: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(_space8),
                          decoration: BoxDecoration(
                            color: _encryptedColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(_radiusMedium),
                          ),
                          child: const Icon(
                            Icons.lock_outline,
                            color: _encryptedColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: _space12),
                        Expanded(
                          child: Text(
                            'Masukkan Kata Sandi Whisper',
                            style: _headingSmall.copyWith(color: _textPrimary),
                          ),
                        ),
                      ],
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Masukkan kata sandi login Anda untuk mengaktifkan mode whisper dan mendekripsi pesan tersembunyi.',
                          style: _bodyMedium.copyWith(color: _textSecondary),
                        ),
                        const SizedBox(height: _space20),
                        Container(
                          decoration: BoxDecoration(boxShadow: _shadowSmall),
                          child: TextField(
                            controller: _passwordController,
                            obscureText: true,
                            autofocus: true,
                            enabled: !_isValidasiKataSandi,
                            style: _bodyMedium.copyWith(color: _textPrimary),
                            decoration: InputDecoration(
                              hintText: 'Kata sandi whisper',
                              hintStyle: _bodyMedium.copyWith(
                                color: _textTertiary,
                              ),
                              prefixIcon: Container(
                                margin: const EdgeInsets.all(_space12),
                                padding: const EdgeInsets.all(_space4),
                                decoration: BoxDecoration(
                                  color: _encryptedColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(
                                    _radiusSmall,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.key,
                                  color: _encryptedColor,
                                  size: 16,
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  _radiusLarge,
                                ),
                                borderSide: BorderSide(
                                  color: _textTertiary.withOpacity(0.3),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  _radiusLarge,
                                ),
                                borderSide: BorderSide(
                                  color: _textTertiary.withOpacity(0.3),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  _radiusLarge,
                                ),
                                borderSide: const BorderSide(
                                  color: _encryptedColor,
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: _surfaceSecondary,
                            ),
                            onSubmitted: (_) =>
                                _authenticateWhisper(setDialogState),
                          ),
                        ),
                        if (_isValidasiKataSandi) ...[
                          const SizedBox(height: _space16),
                          Container(
                            padding: const EdgeInsets.all(_space12),
                            decoration: BoxDecoration(
                              color: _encryptedColor.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(
                                _radiusMedium,
                              ),
                              border: Border.all(
                                color: _encryptedColor.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          _encryptedColor,
                                        ),
                                  ),
                                ),
                                const SizedBox(width: _space12),
                                Text(
                                  'Memvalidasi kata sandi whisper...',
                                  style: _captionLarge.copyWith(
                                    color: _encryptedColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: _isValidasiKataSandi
                            ? null
                            : () {
                                _passwordController.clear();
                                Navigator.of(context).pop();
                              },
                        style: TextButton.styleFrom(
                          foregroundColor: _textSecondary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: _space20,
                            vertical: _space12,
                          ),
                        ),
                        child: Text('Batal', style: _bodyMedium),
                      ),
                      const SizedBox(width: _space8),
                      Container(
                        decoration: BoxDecoration(boxShadow: _shadowSmall),
                        child: ElevatedButton(
                          onPressed: _isValidasiKataSandi
                              ? null
                              : () => _authenticateWhisper(setDialogState),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _encryptedColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: _space24,
                              vertical: _space12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(_radiusLarge),
                            ),
                            elevation: 0,
                          ),
                          child: _isValidasiKataSandi
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  'WHISPER!',
                                  style: _bodyMedium.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _authenticateWhisper(StateSetter setDialogState) async {
    if (_passwordController.text.isEmpty) {
      _showSnackBar(
        'Silakan masukkan kata sandi whisper Anda',
        _errorColor,
        Icons.error_outline,
      );
      return;
    }

    setDialogState(() {
      _isValidasiKataSandi = true;
    });

    try {
      final isValid = await AuthService.validatePassword(
        _passwordController.text,
      );

      setDialogState(() {
        _isValidasiKataSandi = false;
      });

      if (isValid) {
        setState(() {
          isWhisperTerautentikasi = true;
          modeWhisper = true;
        });
        _passwordController.clear();
        Navigator.of(context).pop();
        _whisperAnimationController.forward();

        _showSnackBar(
          'Mode whisper berhasil diaktifkan',
          _successColor,
          Icons.check_circle_outline,
        );
      } else {
        _showSnackBar(
          'Kata sandi whisper tidak benar',
          _errorColor,
          Icons.error_outline,
        );
      }
    } catch (e) {
      setDialogState(() {
        _isValidasiKataSandi = false;
      });

      _showSnackBar(
        'Gagal memvalidasi kata sandi whisper: ${e.toString()}',
        _errorColor,
        Icons.error_outline,
      );
    }
  }

  void _toggleWhisperMode(bool value) {
    if (value && !isWhisperTerautentikasi) {
      _whisperAnimationController.forward();
      _showPasswordDialog();
      return;
    }

    setState(() {
      modeWhisper = value;
      if (!value) {
        isWhisperTerautentikasi = false;
        _whisperAnimationController.reverse();
      } else {
        _whisperAnimationController.forward();
      }
    });

    _showSnackBar(
      modeWhisper
          ? 'Mode whisper AKTIF - Pesan akan didekripsi'
          : 'Mode whisper NONAKTIF - Menampilkan pesan terenkripsi',
      modeWhisper ? _successColor : _warningColor,
      modeWhisper ? Icons.lock_open_outlined : Icons.lock_outlined,
    );
  }

  @override
  Widget build(BuildContext context) {
    _whisperAnimationController.reset();

    return Scaffold(
      backgroundColor: _surfaceColor,
      appBar: AppBar(
        backgroundColor: _surfaceColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_rounded, color: _textPrimary),
          style: IconButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: _textPrimary,
          ),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _primaryColor.withOpacity(0.1),
                    _primaryLight.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: _shadowSmall,
              ),
              child: Center(
                child: Text(
                  widget.partnerName.isNotEmpty
                      ? widget.partnerName[0].toUpperCase()
                      : 'U',
                  style: _bodyMedium.copyWith(
                    color: _primaryColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: _space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.partnerName,
                    style: _bodyLarge.copyWith(
                      color: _textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Online',
                    style: _captionLarge.copyWith(color: _successColor),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          AnimatedBuilder(
            animation: _whisperAnimationController,
            builder: (context, child) {
              return Transform.scale(
                scale: 0.8 + (0.2 * _whisperScaleAnimation.value),
                child: Container(
                  margin: const EdgeInsets.only(right: _space8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: _space12,
                    vertical: _space8,
                  ),
                  decoration: BoxDecoration(
                    gradient: modeWhisper
                        ? LinearGradient(
                            colors: [
                              _encryptedColor.withOpacity(0.1),
                              _encryptedLight.withOpacity(0.1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: modeWhisper ? null : _surfaceSecondary,
                    borderRadius: BorderRadius.circular(_radiusXLarge),
                    border: Border.all(
                      color: modeWhisper
                          ? _encryptedColor.withOpacity(0.3)
                          : _textTertiary.withOpacity(0.2),
                    ),
                    boxShadow: modeWhisper ? _shadowSmall : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        modeWhisper
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 16,
                        color: modeWhisper ? _encryptedColor : _textSecondary,
                      ),
                      const SizedBox(width: _space4),
                      Text(
                        'Whisper',
                        style: _captionLarge.copyWith(
                          color: modeWhisper ? _encryptedColor : _textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: _space4),
                      SizedBox(
                        height: 20,
                        child: Switch(
                          value: modeWhisper,
                          onChanged: _toggleWhisperMode,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          activeColor: _encryptedColor,
                          inactiveThumbColor: _textTertiary,
                          inactiveTrackColor: _textTertiary.withOpacity(0.3),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: _textSecondary),
            onPressed: _loadMessages,
            tooltip: 'Refresh Pesan Whispered',
            style: IconButton.styleFrom(
              backgroundColor: _surfaceSecondary,
              foregroundColor: _textSecondary,
            ),
          ),
          const SizedBox(width: _space8),
        ],
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chat, _) {
          if (chat.loading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(_space20),
                    decoration: BoxDecoration(
                      color: _surfaceSecondary,
                      borderRadius: BorderRadius.circular(_radiusXLarge),
                    ),
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        _primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: _space16),
                  Text(
                    'Memuat pesan whispered...',
                    style: _bodyMedium.copyWith(color: _textSecondary),
                  ),
                ],
              ),
            );
          }

          if (chat.error != null) {
            return Center(
              child: Container(
                margin: const EdgeInsets.all(_space24),
                padding: const EdgeInsets.all(_space24),
                decoration: BoxDecoration(
                  color: _surfaceSecondary,
                  borderRadius: BorderRadius.circular(_radiusXLarge),
                  boxShadow: _shadowMedium,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(_space16),
                      decoration: BoxDecoration(
                        color: _errorColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(_radiusLarge),
                      ),
                      child: Icon(
                        Icons.error_outline_rounded,
                        size: 48,
                        color: _errorColor,
                      ),
                    ),
                    const SizedBox(height: _space16),
                    Text(
                      'Gagal memuat pesan whispered',
                      style: _headingSmall.copyWith(color: _textPrimary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: _space8),
                    Text(
                      chat.error!,
                      style: _bodyMedium.copyWith(color: _errorColor),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: _space20),
                    Container(
                      decoration: BoxDecoration(boxShadow: _shadowSmall),
                      child: ElevatedButton.icon(
                        onPressed: _loadMessages,
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text(
                          'Coba Lagi',
                          style: _bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: _space24,
                            vertical: _space12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(_radiusLarge),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              if (modeWhisper)
                AnimatedBuilder(
                  animation: _whisperAnimationController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(
                        0,
                        -20 * (1 - _whisperScaleAnimation.value),
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: _space16,
                          vertical: _space12,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _encryptedColor.withOpacity(0.05),
                              _encryptedLight.withOpacity(0.05),
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          border: Border(
                            bottom: BorderSide(
                              color: _encryptedColor.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(_space4),
                              decoration: BoxDecoration(
                                color: _encryptedColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(
                                  _radiusSmall,
                                ),
                              ),
                              child: Icon(
                                Icons.lock_open_rounded,
                                size: 14,
                                color: _encryptedColor,
                              ),
                            ),
                            const SizedBox(width: _space8),
                            Text(
                              'Mode whisper aktif - Pesan terenkripsi sedang didekripsi',
                              style: _captionLarge.copyWith(
                                color: _encryptedColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

              Expanded(
                child: chat.messages.isEmpty
                    ? Center(
                        child: Container(
                          margin: const EdgeInsets.all(_space24),
                          padding: const EdgeInsets.all(_space32),
                          decoration: BoxDecoration(
                            color: _surfaceSecondary,
                            borderRadius: BorderRadius.circular(_radiusXLarge),
                            boxShadow: _shadowSmall,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(_space20),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      _primaryColor.withOpacity(0.1),
                                      _primaryLight.withOpacity(0.1),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    _radiusXLarge,
                                  ),
                                ),
                                child: Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 48,
                                  color: _primaryColor,
                                ),
                              ),
                              const SizedBox(height: _space20),
                              Text(
                                'Belum ada pesan whispered',
                                style: _headingSmall.copyWith(
                                  color: _textPrimary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: _space8),
                              Text(
                                'Mulai percakapan whisper dengan ${widget.partnerName}!',
                                style: _bodyMedium.copyWith(
                                  color: _textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadMessages,
                        color: _primaryColor,
                        backgroundColor: _surfaceColor,
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                            vertical: _space16,
                            horizontal: _space8,
                          ),
                          itemCount: chat.messages.length,
                          itemBuilder: (context, index) {
                            final msg = chat.messages[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: _space8),
                              child: MessageBubble(
                                message: msg,
                                isMe:
                                    currentUserId != null &&
                                    msg.senderId == currentUserId,
                                roomId: widget.roomId,
                                whisperMode: modeWhisper,
                              ),
                            );
                          },
                        ),
                      ),
              ),

              Container(
                decoration: BoxDecoration(
                  color: _surfaceColor,
                  border: Border(
                    top: BorderSide(
                      color: _textTertiary.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  boxShadow: _shadowSmall,
                ),
                child: SafeArea(
                  child: ChatInput(
                    onSendMessage: _sendMessage,
                    whisperMode: modeWhisper,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
