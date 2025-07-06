import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? user;
  final Map<String, dynamic>? wallet;
  final String? token;

  const ProfileScreen({
    Key? key,
    this.user,
    this.wallet,
    this.token,
  }) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final wallet = widget.wallet;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF0FDF4),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(user),
                _buildStatsCards(wallet),
                _buildMenuItems(),
                _buildQuickActions(),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic>? user) {
    final name = user?['name'] ?? 'User';
    final profileImageUrl = user?['profile_image_url'];
    final imageUrl = profileImageUrl != null
        ? "http://10.0.2.2:3000/uploads/$profileImageUrl"
        : null;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFF059669),
            Color(0xFF047857),
          ],
        ),
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Profile',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    // Handle edit profile
                  },
                  icon: Icon(Icons.edit, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          SizedBox(height: 30),

          Column(
            children: [
              Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.white, Color(0xFFDCFCE7)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.all(4),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFBBF7D0), Color(0xFF86EFAC)],
                        ),
                      ),
                      child: ClipOval(
                        child: imageUrl != null
                            ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Color(0xFF86EFAC),
                            child: Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                        )
                            : Container(
                          color: Color(0xFF86EFAC),
                          child: Icon(
                            Icons.person,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          // Handle camera action
                        },
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          Icons.camera_alt,
                          color: Color(0xFF059669),
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Text(
                name,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Premium Member',
                style: TextStyle(
                  color: Color(0xFFBBF7D0),
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ...List.generate(
                    5,
                        (index) => Icon(
                      Icons.star,
                      color: Color(0xFFFDE047),
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    '5.0 Rating',
                    style: TextStyle(
                      color: Color(0xFFBBF7D0),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(Map<String, dynamic>? wallet) {
    final balance = wallet?['balance']?.toString() ?? "0";
    final walletId = wallet?['wallet_id'] ?? "N/A";

    final stats = [
      {'label': 'Wallet Balance', 'value': 'XAF $balance', 'icon': Icons.account_balance_wallet},
      {'label': 'Wallet ID', 'value': walletId, 'icon': Icons.credit_card},
      {'label': 'Active Loans', 'value': '1', 'icon': Icons.credit_card},
    ];

    return Transform.translate(
      offset: Offset(0, -30),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        padding: EdgeInsets.all(24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: stats.map((stat) => _buildStatItem(stat)).toList(),
        ),
      ),
    );
  }

  Widget _buildStatItem(Map<String, dynamic> stat) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            stat['icon'],
            color: Color(0xFF059669),
            size: 24,
          ),
        ),
        SizedBox(height: 8),
        Text(
          stat['value'],
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        SizedBox(height: 4),
        Text(
          stat['label'],
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7280),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMenuItems() {
    final menuItems = [
      {'icon': Icons.credit_card, 'label': 'My Loans', 'subtitle': 'View active and past loans'},
      {'icon': Icons.description, 'label': 'Documents', 'subtitle': 'Upload and manage documents'},
      {'icon': Icons.security, 'label': 'Security', 'subtitle': 'Privacy and security settings'},
      {'icon': Icons.notifications, 'label': 'Notifications', 'subtitle': 'Manage your preferences'},
      {'icon': Icons.card_giftcard, 'label': 'Rewards', 'subtitle': 'Loyalty points and benefits'},
      {'icon': Icons.settings, 'label': 'Settings', 'subtitle': 'Account and app preferences'},
    ];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: menuItems.map((item) => _buildMenuItem(item)).toList(),
      ),
    );
  }

  Widget _buildMenuItem(Map<String, dynamic> item) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.lightImpact();
            // Handle menu item tap
          },
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    item['icon'],
                    color: Color(0xFF059669),
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['label'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        item['subtitle'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Color(0xFF9CA3AF),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      margin: EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  'Apply for Loan',
                  Icons.credit_card,
                  isPrimary: true,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionButton(
                  'View Statements',
                  Icons.description,
                  isPrimary: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(String label, IconData icon, {required bool isPrimary}) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        gradient: isPrimary
            ? LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF059669), Color(0xFF047857)],
        )
            : null,
        color: isPrimary ? null : Colors.white,
        border: isPrimary
            ? null
            : Border.all(color: Color(0xFFBBF7D0), width: 2),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isPrimary
                ? Color(0xFF059669).withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: isPrimary ? 15 : 10,
            offset: Offset(0, isPrimary ? 8 : 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.mediumImpact();
            // Handle quick action
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: isPrimary ? Colors.white : Color(0xFF047857),
              ),
              SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isPrimary ? Colors.white : Color(0xFF047857),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
