import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Import your screens
import '../../login/login.dart';
import '../admin loan management/admin_loan.dart';
import '../admin profile/admin_profile.dart';
import '../admin user management/admin_user.dart';

class AdminDashboardScreen extends StatefulWidget {
  final Map<String, dynamic> admin;
  final String token;

  const AdminDashboardScreen({
    Key? key,
    required this.admin,
    required this.token,
  }) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with TickerProviderStateMixin {
  int totalUsers = 0;
  int pendingLoans = 0;
  int approvedToday = 0;
  int activeLoans = 0;
  bool loadingStats = false;

  AnimationController? _animationController;
  Animation<double>? _slideAnimation;
  Animation<double>? _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController!,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
    ));
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController!,
      curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
    ));

    fetchDashboardStats();
    _animationController?.forward();
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  Future<void> fetchDashboardStats() async {
    setState(() {
      loadingStats = true;
    });

    try {
      final response = await http.get(
        Uri.parse("http://10.0.2.2:3000/api/admin/dashboard-stats"),
        headers: {
          "Authorization": "Bearer ${widget.token}",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          totalUsers = data['totalUsers'] ?? 0;
          pendingLoans = data['pendingLoans'] ?? 0;
          approvedToday = data['approvedToday'] ?? 0;
          activeLoans = data['activeLoans'] ?? 0;
        });
      } else {
        print("❌ Failed to fetch stats: ${response.body}");
        _showErrorSnackbar("Failed to load dashboard data.");
      }
    } catch (e) {
      print("❌ Network error: $e");
      _showErrorSnackbar("Network error occurred.");
    } finally {
      setState(() {
        loadingStats = false;
      });
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: Color(0xFF2E7D32),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                "Logout",
                style: TextStyle(
                  color: Color(0xFF1B5E20),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: const Text(
            "Are you sure you want to logout from your admin account?",
            style: TextStyle(color: Color(0xFF424242)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF616161),
              ),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _logout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text("Logout"),
            ),
          ],
        );
      },
    );
  }

  void _logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) =>  LoginScreen()),
          (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.admin['name'] ?? 'Admin';
    final email = widget.admin['email'] ?? '';
    final role = widget.admin['role'] ?? 'Administrator';

    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      body: CustomScrollView(
        slivers: [
          // Modern App Bar
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF1B5E20),
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1B5E20),
                      Color(0xFF2E7D32),
                      Color(0xFF388E3C),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: const Icon(
                                Icons.admin_panel_settings_rounded,
                                size: 32,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Welcome back,",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.8),
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    role,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.9),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_rounded, color: Colors.white),
                onPressed: () {},
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (value) {
                  switch (value) {
                    case 'profile':
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AdminProfileScreen(
                            admin: widget.admin,
                            token: widget.token,
                          ),
                        ),
                      );
                      break;
                    case 'settings':
                      break;
                    case 'logout':
                      _showLogoutDialog();
                      break;
                  }
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        Icon(Icons.person_rounded, color: Color(0xFF2E7D32)),
                        SizedBox(width: 8),
                        Text('Profile'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'settings',
                    child: Row(
                      children: [
                        Icon(Icons.settings_rounded, color: Color(0xFF2E7D32)),
                        SizedBox(width: 8),
                        Text('Settings'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout_rounded, color: Color(0xFF2E7D32)),
                        SizedBox(width: 8),
                        Text('Logout'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: RefreshIndicator(
              onRefresh: fetchDashboardStats,
              color: const Color(0xFF2E7D32),
              child: _slideAnimation != null && _scaleAnimation != null
                  ? AnimatedBuilder(
                animation: _animationController!,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _slideAnimation!.value),
                    child: Transform.scale(
                      scale: _scaleAnimation!.value,
                      child: Opacity(
                        opacity: _animationController!.value,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildStatsGrid(),
                              const SizedBox(height: 32),
                              _buildManagementSection(),
                              const SizedBox(height: 32),
                              _buildActivitySection(),
                              const SizedBox(height: 32),
                              _buildLogoutSection(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              )
                  : Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatsGrid(),
                    const SizedBox(height: 32),
                    _buildManagementSection(),
                    const SizedBox(height: 32),
                    _buildActivitySection(),
                    const SizedBox(height: 32),
                    _buildLogoutSection(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Dashboard Overview",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B5E20),
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.0,
          children: [
            _buildModernStatCard(
              title: "Total Users",
              value: loadingStats ? "..." : totalUsers.toString(),
              icon: _buildUserIcon(),
              color: const Color(0xFF1976D2),
              lightColor: const Color(0xFFE3F2FD),
            ),
            _buildModernStatCard(
              title: "Pending Loans",
              value: loadingStats ? "..." : pendingLoans.toString(),
              icon: _buildPendingIcon(),
              color: const Color(0xFFFF8F00),
              lightColor: const Color(0xFFFFF3E0),
            ),
            _buildModernStatCard(
              title: "Approved Today",
              value: loadingStats ? "..." : approvedToday.toString(),
              icon: _buildApprovedIcon(),
              color: const Color(0xFF2E7D32),
              lightColor: const Color(0xFFE8F5E8),
            ),
            _buildModernStatCard(
              title: "Active Loans",
              value: loadingStats ? "..." : activeLoans.toString(),
              icon: _buildActiveLoansIcon(),
              color: const Color(0xFF7B1FA2),
              lightColor: const Color(0xFFF3E5F5),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModernStatCard({
    required String title,
    required String value,
    required Widget icon,
    required Color color,
    required Color lightColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: lightColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: icon,
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF616161),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManagementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Management Tools",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B5E20),
          ),
        ),
        const SizedBox(height: 16),
        _buildManagementCard(
          title: "User Management",
          subtitle: "Manage user accounts and profiles",
          icon: _buildManageUsersIcon(),
          color: const Color(0xFF1976D2),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserManagementScreen(
                  admin: widget.admin,
                  token: widget.token,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildManagementCard(
          title: "Loan Management",
          subtitle: "Review and approve loan applications",
          icon: _buildLoanManagementIcon(),
          color: const Color(0xFF2E7D32),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LoanManagementScreen(
                  admin: widget.admin,
                  token: widget.token,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildManagementCard(
          title: "Profile Settings",
          subtitle: "Update admin profile and preferences",
          icon: _buildProfileIcon(),
          color: const Color(0xFF7B1FA2),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AdminProfileScreen(
                  admin: widget.admin,
                  token: widget.token,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildManagementCard({
    required String title,
    required String subtitle,
    required Widget icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF000000).withOpacity(0.05),
              spreadRadius: 0,
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: icon,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF616161),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Color(0xFF2E7D32),
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitySection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Recent Activity",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20),
                ),
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF2E7D32),
                ),
                child: const Text("View All"),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildActivityItem(
            "New user registration: John Doe",
            "2 minutes ago",
            _buildActivityUserIcon(),
            const Color(0xFF1976D2),
          ),
          _buildActivityItem(
            "Loan approved: Application #1234",
            "15 minutes ago",
            _buildActivityCheckIcon(),
            const Color(0xFF2E7D32),
          ),
          _buildActivityItem(
            "User account updated: Jane Smith",
            "1 hour ago",
            _buildActivityEditIcon(),
            const Color(0xFF7B1FA2),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String title, String time, Widget icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: icon,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1B5E20),
                  ),
                ),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF616161),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF2E7D32).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: _buildLogoutIcon(),
          ),
          const SizedBox(height: 16),
          const Text(
            "Securely logout from your admin account",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B5E20),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "",
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF616161),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showLogoutDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.logout_rounded),
              label: const Text(
                "Logout",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Large SVG-style Icons
  Widget _buildUserIcon() {
    return const Icon(
      Icons.groups_rounded,
      size: 32,
      color: Color(0xFF1976D2),
    );
  }

  Widget _buildPendingIcon() {
    return const Icon(
      Icons.schedule_rounded,
      size: 32,
      color: Color(0xFFFF8F00),
    );
  }

  Widget _buildApprovedIcon() {
    return const Icon(
      Icons.verified_rounded,
      size: 32,
      color: Color(0xFF2E7D32),
    );
  }

  Widget _buildActiveLoansIcon() {
    return const Icon(
      Icons.account_balance_rounded,
      size: 32,
      color: Color(0xFF7B1FA2),
    );
  }

  Widget _buildManageUsersIcon() {
    return const Icon(
      Icons.manage_accounts_rounded,
      size: 32,
      color: Color(0xFF1976D2),
    );
  }

  Widget _buildLoanManagementIcon() {
    return const Icon(
      Icons.account_balance_wallet_rounded,
      size: 32,
      color: Color(0xFF2E7D32),
    );
  }

  Widget _buildProfileIcon() {
    return const Icon(
      Icons.admin_panel_settings_rounded,
      size: 32,
      color: Color(0xFF7B1FA2),
    );
  }

  Widget _buildActivityUserIcon() {
    return const Icon(
      Icons.person_add_rounded,
      size: 20,
      color: Color(0xFF1976D2),
    );
  }

  Widget _buildActivityCheckIcon() {
    return const Icon(
      Icons.check_circle_rounded,
      size: 20,
      color: Color(0xFF2E7D32),
    );
  }

  Widget _buildActivityEditIcon() {
    return const Icon(
      Icons.edit_rounded,
      size: 20,
      color: Color(0xFF7B1FA2),
    );
  }

  Widget _buildLogoutIcon() {
    return const Icon(
      Icons.power_settings_new_rounded,
      size: 48,
      color: Color(0xFF2E7D32),
    );
  }
}