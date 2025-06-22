import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/chat_service.dart';
import 'chat_screen.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({Key? key}) : super(key: key);

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen>
    with TickerProviderStateMixin {
  List<User> users = [];
  List<User> filteredUsers = [];
  bool loading = true;
  String? error;
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  static const _primaryColor = Color(0xFF6366F1);
  static const _primaryLight = Color(0xFF818CF8);

  static const _surfaceColor = Color(0xFFF8FAFC);

  static const _textPrimary = Color(0xFF0F172A);
  static const _textSecondary = Color(0xFF64748B);
  static const _textTertiary = Color(0xFF94A3B8);

  static const _errorColor = Color(0xFFEF4444);

  static const _headingSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );
  static const _bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );
  static const _bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );
  static const _bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  static const double _space4 = 4.0;
  static const double _space8 = 8.0;
  static const double _space12 = 12.0;
  static const double _space16 = 16.0;
  static const double _space20 = 20.0;
  static const double _space24 = 24.0;
  static const double _space32 = 32.0;

  static const double _radiusMedium = 8.0;
  static const double _radiusLarge = 12.0;

  static final List<BoxShadow> _shadowSmall = [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadUsers();
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final allUsers = await ChatService.searchUsers('');
      setState(() {
        users = allUsers;
        filteredUsers = allUsers;
        loading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredUsers = users;
      } else {
        filteredUsers = users.where((user) {
          return user.name.toLowerCase().contains(query) ||
              (user.username?.toLowerCase().contains(query) ?? false) ||
              (user.email?.toLowerCase().contains(query) ?? false);
        }).toList();
      }
    });
  }

  Future<void> _startChat(User user) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radiusLarge),
          ),
          child: Padding(
            padding: const EdgeInsets.all(_space24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 1000),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: 0.8 + (0.2 * value),
                      child: CircularProgressIndicator(
                        color: _primaryColor,
                        strokeWidth: 3,
                      ),
                    );
                  },
                ),
                const SizedBox(height: _space16),
                Text(
                  'Memulai chat...',
                  style: _bodyMedium.copyWith(color: _textSecondary),
                ),
              ],
            ),
          ),
        ),
      );

      final chatRoom = await ChatService.createPrivateChat(user.id);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ChatScreen(roomId: chatRoom.id, partnerName: user.name),
        ),
      );
    } catch (e) {
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: _space8),
              Expanded(
                child: Text(
                  'Gagal memulai chat: ${e.toString()}',
                  style: _bodyMedium.copyWith(color: Colors.white),
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
        ),
      );
    }
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(_space16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_radiusLarge),
        boxShadow: _shadowSmall,
      ),
      child: TextField(
        controller: _searchController,
        style: _bodyLarge.copyWith(color: _textPrimary),
        decoration: InputDecoration(
          hintText: 'Cari pengguna...',
          hintStyle: _bodyLarge.copyWith(color: _textTertiary),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: _textTertiary,
            size: 20,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear_rounded,
                    color: _textTertiary,
                    size: 20,
                  ),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: _space16,
            vertical: _space16,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 1000),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.8 + (0.2 * value),
                child: CircularProgressIndicator(
                  color: _primaryColor,
                  strokeWidth: 3,
                ),
              );
            },
          ),
          const SizedBox(height: _space20),
          Text(
            'Memuat pengguna...',
            style: _bodyMedium.copyWith(
              color: _textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(_space24),
        padding: const EdgeInsets.all(_space24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_radiusLarge),
          boxShadow: _shadowSmall,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(_space16),
              decoration: BoxDecoration(
                color: _errorColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 32,
                color: _errorColor,
              ),
            ),
            const SizedBox(height: _space16),
            Text(
              'Gagal memuat pengguna',
              style: _headingSmall.copyWith(color: _textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: _space8),
            Text(
              error!,
              style: _bodyMedium.copyWith(color: _textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: _space20),
            ElevatedButton.icon(
              onPressed: _loadUsers,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: _space20,
                  vertical: _space12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_radiusMedium),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(_space24),
        padding: const EdgeInsets.all(_space32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(_space20),
              decoration: BoxDecoration(
                color: _searchController.text.isNotEmpty
                    ? _textTertiary.withOpacity(0.1)
                    : _primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _searchController.text.isNotEmpty
                    ? Icons.search_off_rounded
                    : Icons.contacts_rounded,
                size: 40,
                color: _searchController.text.isNotEmpty
                    ? _textTertiary
                    : _primaryColor,
              ),
            ),
            const SizedBox(height: _space20),
            Text(
              _searchController.text.isNotEmpty
                  ? 'Pengguna tidak ditemukan'
                  : 'Belum ada pengguna',
              style: _headingSmall.copyWith(color: _textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: _space8),
            Text(
              _searchController.text.isNotEmpty
                  ? 'Coba gunakan kata kunci lain'
                  : 'Pengguna akan muncul di sini',
              style: _bodyMedium.copyWith(color: _textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserItem(User user, int index) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - _fadeAnimation.value) * 20),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              margin: const EdgeInsets.symmetric(
                horizontal: _space16,
                vertical: _space4,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(_radiusLarge),
                boxShadow: _shadowSmall,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(_radiusLarge),
                  onTap: () => _startChat(user),
                  child: Padding(
                    padding: const EdgeInsets.all(_space16),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: user.avatar == null
                                ? LinearGradient(
                                    colors: [_primaryColor, _primaryLight],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: user.avatar != null
                                ? Image.network(
                                    user.avatar!,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              _primaryColor,
                                              _primaryLight,
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            user.name.isNotEmpty
                                                ? user.name[0].toUpperCase()
                                                : '?',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 18,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                : Center(
                                    child: Text(
                                      user.name.isNotEmpty
                                          ? user.name[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 18,
                                      ),
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
                                user.name,
                                style: _bodyLarge.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: _textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (user.username != null) ...[
                                const SizedBox(height: _space4),
                                Text(
                                  '@${user.username}',
                                  style: _bodyMedium.copyWith(
                                    color: _textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              if (user.email != null) ...[
                                const SizedBox(height: _space4),
                                Text(
                                  user.email!,
                                  style: _bodySmall.copyWith(
                                    color: _textTertiary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: _primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.chat_rounded,
                              color: _primaryColor,
                              size: 20,
                            ),
                            onPressed: () => _startChat(user),
                            tooltip: 'Mulai chat',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _surfaceColor,
      child: Column(
        children: [
          _buildSearchBar(),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (loading) {
      return _buildLoadingState();
    }

    if (error != null) {
      return _buildErrorState();
    }

    if (filteredUsers.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      color: _primaryColor,
      backgroundColor: Colors.white,
      child: ListView.builder(
        itemCount: filteredUsers.length,
        padding: const EdgeInsets.only(bottom: _space16),
        itemBuilder: (context, index) {
          return _buildUserItem(filteredUsers[index], index);
        },
      ),
    );
  }
}
