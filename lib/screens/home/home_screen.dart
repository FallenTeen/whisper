import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../chat/chat_list_screen.dart';
import '../chat/contacts_screen.dart';
import '../../providers/auth_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _fabScaleAnimation;
  static const _primaryColor = Color(0xFF6366F1);
  static const _primaryLight = Color(0xFF818CF8);
  static const _surfaceColor = Color(0xFFF8FAFC);
  static const _surfaceSecondary = Color(0xFFF1F5F9);
  static const _textPrimary = Color(0xFF0F172A);
  static const _textSecondary = Color(0xFF64748B);

  static const _errorColor = Color(0xFFEF4444);

  static const _headingLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );
  static const _headingMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
  );
  static const _bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  static const double _space4 = 4.0;
  static const double _space8 = 8.0;
  static const double _space12 = 12.0;
  static const double _space16 = 16.0;
  static const double _space20 = 20.0;
  static const double _space24 = 24.0;
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: -50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
      ),
    );

    _fabScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fabAnimationController,
        curve: Curves.elasticOut,
      ),
    );
    _animationController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _fabAnimationController.forward();
      }
    });
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _fabAnimationController.reverse().then((_) {
          if (mounted) {
            _fabAnimationController.forward();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => _buildLogoutDialog(),
    );

    if (shouldLogout == true) {
      try {
        await Provider.of<AuthProvider>(context, listen: false).logout();
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      } catch (e) {
        if (mounted) {
          _showErrorSnackBar('Logout gagal: $e');
        }
      }
    }
  }

  Widget _buildLogoutDialog() {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_radiusXLarge),
      ),
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(_space24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_radiusXLarge),
          boxShadow: _shadowMedium,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _errorColor.withOpacity(0.1),
                    _errorColor.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.logout_rounded, color: _errorColor, size: 28),
            ),
            const SizedBox(height: _space20),
            Text('Logout', style: _headingMedium.copyWith(color: _textPrimary)),
            const SizedBox(height: _space8),
            Text(
              'Anda yakin ingin logout dari akun Anda?',
              style: _bodyMedium.copyWith(color: _textSecondary, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: _space24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      foregroundColor: _textSecondary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: _space20,
                        vertical: _space12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(_radiusMedium),
                      ),
                    ),
                    child: Text(
                      'Batal',
                      style: _bodyMedium.copyWith(fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                const SizedBox(width: _space12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _errorColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: _space20,
                        vertical: _space12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(_radiusMedium),
                      ),
                    ),
                    child: Text(
                      'Logout',
                      style: _bodyMedium.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: _space12),
            Expanded(
              child: Text(
                message,
                style: _bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: _errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusMedium),
        ),
        margin: const EdgeInsets.all(_space16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Widget _buildAppBar() {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Container(
            padding: const EdgeInsets.fromLTRB(
              _space16,
              _space8,
              _space16,
              _space8,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: _shadowSmall,
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_primaryColor, _primaryLight],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(_radiusMedium),
                      boxShadow: [
                        BoxShadow(
                          color: _primaryColor.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 22,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: _space12),
                  Expanded(
                    child: Text(
                      'Whisper Chat',
                      style: _headingLarge.copyWith(color: _textPrimary),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: _surfaceSecondary,
                      borderRadius: BorderRadius.circular(_radiusMedium),
                    ),
                    child: PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert_rounded,
                        color: _textSecondary,
                        size: 20,
                      ),
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(_radiusLarge),
                      ),
                      color: Colors.white,
                      shadowColor: Colors.black.withOpacity(0.1),
                      onSelected: (value) {
                        if (value == 'logout') {
                          _logout();
                        }
                      },
                      itemBuilder: (BuildContext context) => [
                        PopupMenuItem<String>(
                          value: 'logout',
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: _space4,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(_space8),
                                  decoration: BoxDecoration(
                                    color: _errorColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(
                                      _radiusMedium,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.logout_rounded,
                                    size: 16,
                                    color: _errorColor,
                                  ),
                                ),
                                const SizedBox(width: _space12),
                                Text(
                                  'Logout',
                                  style: _bodyMedium.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: _errorColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.all(_space16),
      decoration: BoxDecoration(
        color: _surfaceSecondary,
        borderRadius: BorderRadius.circular(_radiusXLarge),
        boxShadow: _shadowSmall,
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: LinearGradient(
            colors: [_primaryColor, _primaryLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(_radiusLarge),
          boxShadow: [
            BoxShadow(
              color: _primaryColor.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(_space4),
        labelColor: Colors.white,
        unselectedLabelColor: _textSecondary,
        labelStyle: _bodyMedium.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: _bodyMedium.copyWith(fontWeight: FontWeight.w500),
        splashFactory: NoSplash.splashFactory,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        tabs: [
          Tab(
            height: 44,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_outlined, size: 18),
                const SizedBox(width: _space8),
                const Text('Chats'),
              ],
            ),
          ),
          Tab(
            height: 44,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.contacts_outlined, size: 18),
                const SizedBox(width: _space8),
                const Text('Kontak'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return AnimatedBuilder(
      animation: _fabScaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _fabScaleAnimation.value,
          child: FloatingActionButton.extended(
            onPressed: () {
              _tabController.animateTo(1);
            },
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_radiusXLarge),
            ),
            icon: Icon(Icons.add_comment_outlined, size: 20),
            label: Text(
              'Chat Baru',
              style: _bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Scaffold(
        backgroundColor: _surfaceColor,
        body: Column(
          children: [
            _buildAppBar(),
            _buildTabBar(),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: _space8),
                child: TabBarView(
                  controller: _tabController,
                  children: const [ChatListScreen(), ContactsScreen()],
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: _buildFloatingActionButton(),
      ),
    );
  }
}
