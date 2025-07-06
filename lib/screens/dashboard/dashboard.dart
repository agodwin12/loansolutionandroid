import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../loan history/loan_history.dart';
import '../login/login.dart';
import '../../utils/navbar.dart';
import '../my profile/profile_screen.dart';
import '../request loan/loan_request.dart';

class DashboardScreen extends StatefulWidget {
  final Map<String, dynamic>? user;
  final Map<String, dynamic>? wallet;

  DashboardScreen({
    this.user,
    this.wallet, String? token,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  String? _token;
  Map<String, dynamic>? _user;
  Map<String, dynamic>? _wallet;
  List<LoanHistory> loanHistory = []; // Initialize empty list
  bool _isLoading = false;

  int _currentIndex = 1; // Start with Home tab
  AnimationController? _cardAnimationController;
  AnimationController? _buttonsAnimationController;
  Animation<double>? _cardSlideAnimation;
  Animation<double>? _cardFadeAnimation;
  Animation<double>? _buttonsSlideAnimation;
  bool _animationsInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadPrefsAndFetchData();
  }

  Future<void> _loadPrefsAndFetchData() async {
    await loadPrefs();

    // Fetch loan history after preferences are loaded
    if (_token != null && _user != null) {
      await fetchRecentLoans();
    }
  }

  Future<void> fetchRecentLoans() async {
    if (_token == null || _user == null) {
      print("⚠️ Missing token or user data. Cannot fetch loans.");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.parse(
        "http://10.0.2.2:3000/api/loans/user/${_user!['id']}/recent",
      );

      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $_token",
        },
      );

      print("✅ Loan history status: ${response.statusCode}");
      print("✅ Loan history body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> loansJson = data["loans"] ?? [];

        setState(() {
          loanHistory = loansJson
              .map((json) => LoanHistory.fromJson(json))
              .toList();
          _isLoading = false;
        });
      } else {
        print("❌ Failed to fetch loans: ${response.body}");
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print("❌ Network error while fetching loans: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _initializeAnimations() {
    _cardAnimationController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );

    _buttonsAnimationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _cardSlideAnimation = Tween<double>(begin: -100.0, end: 0.0).animate(
      CurvedAnimation(parent: _cardAnimationController!, curve: Curves.easeOutBack),
    );

    _cardFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cardAnimationController!, curve: Curves.easeIn),
    );

    _buttonsSlideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _buttonsAnimationController!, curve: Curves.easeOut),
    );

    _animationsInitialized = true;

    // Start animations
    _cardAnimationController!.forward();
    Future.delayed(Duration(milliseconds: 300), () {
      if (mounted && _buttonsAnimationController != null) {
        _buttonsAnimationController!.forward();
      }
    });
  }

  @override
  void dispose() {
    _cardAnimationController?.dispose();
    _buttonsAnimationController?.dispose();
    super.dispose();
  }

  Future<void> loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    final savedToken = prefs.getString('auth_token');
    final userJson = prefs.getString('user');
    final walletJson = prefs.getString('wallet');

    print('✅ Loaded token from prefs: $savedToken');
    print('✅ Loaded user JSON from prefs: $userJson');
    print('✅ Loaded wallet JSON from prefs: $walletJson');

    Map<String, dynamic>? userMap;
    if (userJson != null) {
      try {
        userMap = jsonDecode(userJson);
      } catch (e) {
        print('❌ Failed to decode user JSON: $e');
      }
    }

    Map<String, dynamic>? walletMap;
    if (walletJson != null) {
      try {
        walletMap = jsonDecode(walletJson);
      } catch (e) {
        print('❌ Failed to decode wallet JSON: $e');
      }
    }

    setState(() {
      _token = savedToken;
      _user = userMap ?? widget.user;
      _wallet = walletMap ?? widget.wallet;
    });
  }

  String formatCurrency(double amount) {
    return "${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} XAF";
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
    );
  }

  void _onNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0:
      // Navigate to Loan History Screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LoanHistoryScreen(
              user: (_user ?? widget.user)!,
              wallet: (_wallet ?? widget.wallet)!,
              token: _token!,
            ),
          ),
        );


        break;

      case 1:
      // Navigate to Dashboard (replace current)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DashboardScreen(
              user: _user ?? widget.user,
              wallet: _wallet ?? widget.wallet,
              token: _token,
            ),
          ),
        );
        break;

      case 2:
      // Navigate to Profile Screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProfileScreen(
              user: _user ?? widget.user,
              wallet: _wallet ?? widget.wallet,
              token: _token,
            ),
          ),
        );
        break;
    }
  }


  @override
  Widget build(BuildContext context) {
    final displayUser = _user ?? widget.user;
    final displayWallet = _wallet ?? widget.wallet;

    if (displayUser == null) {
      return Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(displayUser),
              SizedBox(height: 30),

              // Wallet Card
              if (_animationsInitialized && _cardAnimationController != null)
                AnimatedBuilder(
                  animation: _cardAnimationController!,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _cardSlideAnimation?.value ?? 0),
                      child: Opacity(
                        opacity: _cardFadeAnimation?.value ?? 1,
                        child: _buildWalletCard(displayWallet),
                      ),
                    );
                  },
                )
              else
                _buildWalletCard(displayWallet),

              SizedBox(height: 30),

              // Action Buttons
              if (_animationsInitialized && _buttonsAnimationController != null)
                AnimatedBuilder(
                  animation: _buttonsAnimationController!,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _buttonsSlideAnimation?.value ?? 0),
                      child: _buildActionButtons(),
                    );
                  },
                )
              else
                _buildActionButtons(),

              SizedBox(height: 30),

              // Loan History Section
              if (_animationsInitialized && _buttonsAnimationController != null)
                AnimatedBuilder(
                  animation: _buttonsAnimationController!,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _buttonsSlideAnimation?.value ?? 0),
                      child: _buildLoanHistorySection(),
                    );
                  },
                )
              else
                _buildLoanHistorySection(),

              SizedBox(height: 100), // Space for bottom nav
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> user) {
    final profileImageUrl = user['profile_image_url'] as String?;
    final imageUrl = profileImageUrl != null
        ? "http://10.0.2.2:3000/uploads/$profileImageUrl"
        : null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Good Morning',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              user['name'] ?? 'User',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Icon(
                    Icons.notifications_outlined,
                    color: Color(0xFF10B981),
                    size: 24,
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 10),
            GestureDetector(
              onTap: () {
                // Navigate to profile screen or show profile menu
                print('Profile tapped');
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: imageUrl != null
                      ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      decoration: BoxDecoration(
                        color: Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        Icons.person,
                        color: Color(0xFF10B981),
                        size: 24,
                      ),
                    ),
                  )
                      : Container(
                    decoration: BoxDecoration(
                      color: Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      Icons.person,
                      color: Color(0xFF10B981),
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWalletCard(Map<String, dynamic>? wallet) {
    final balance = wallet != null
        ? double.tryParse(wallet['balance']?.toString() ?? '0') ?? 0.0
        : 0.0;

    final walletId = wallet?['wallet_id']?.toString() ?? 'N/A';

    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF10B981),
            Color(0xFF059669),
            Color(0xFF047857),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF10B981).withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Pattern
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            right: 20,
            bottom: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),

          // Card Content
          Padding(
            padding: EdgeInsets.all(25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Wallet Balance',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          formatCurrency(balance),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.account_balance_wallet,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ],
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Wallet Id',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          walletId,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        'ACTIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            icon: Icons.add_circle_outline,
            label: 'Request\nLoan',
            color: Color(0xFF10B981),
            onTap: () {
              // Navigate to loan request screen with user data
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LoanRequestScreen(
                    user: _user ?? widget.user,
                    wallet: _wallet ?? widget.wallet,
                    token: _token,
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(width: 15),
        Expanded(
          child: _buildActionButton(
            icon: Icons.payment_outlined,
            label: 'Pay\nLoan',
            color: Color(0xFF3B82F6),
            onTap: () {
              // Navigate to loan payment screen
              print('Pay Loan tapped');
            },
          ),
        ),
        SizedBox(width: 15),
        Expanded(
          child: _buildActionButton(
            icon: Icons.account_balance_outlined,
            label: 'Withdraw\nMoney',
            color: Color(0xFFEF4444),
            onTap: () {
              // Navigate to withdrawal screen
              print('Withdraw Money tapped');
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoanHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Loan History',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            TextButton(
              onPressed: () {
                // Navigate to full history
                print('View All tapped');
              },
              child: Text(
                'View All',
                style: TextStyle(
                  color: Color(0xFF10B981),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 15),

        // Loading state
        if (_isLoading)
          Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
              ),
            ),
          )
        // Empty state
        else if (loanHistory.isEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  Icons.history,
                  size: 48,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 16),
                Text(
                  'No loan history yet',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Your loan history will appear here',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          )
        // Loan History List
        else
          ListView.separated(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: loanHistory.length,
            separatorBuilder: (context, index) => SizedBox(height: 15),
            itemBuilder: (context, index) {
              return _buildLoanHistoryCard(loanHistory[index]);
            },
          ),
      ],
    );
  }

  Widget _buildLoanHistoryCard(LoanHistory loan) {
    Color statusColor;
    Color statusBgColor;

    switch (loan.status.toLowerCase()) {
      case 'active':
        statusColor = Color(0xFF10B981);
        statusBgColor = Color(0xFF10B981).withOpacity(0.1);
        break;
      case 'paid':
        statusColor = Color(0xFF3B82F6);
        statusBgColor = Color(0xFF3B82F6).withOpacity(0.1);
        break;
      case 'pending':
        statusColor = Color(0xFFF59E0B);
        statusBgColor = Color(0xFFF59E0B).withOpacity(0.1);
        break;
      default:
        statusColor = Colors.grey;
        statusBgColor = Colors.grey.withOpacity(0.1);
    }

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loan.type.isNotEmpty ? loan.type : 'Loan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    Text(
                      'ID: ${loan.id}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  loan.status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 15),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Amount',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  Text(
                    formatCurrency(loan.amount),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Due Date',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  Text(
                    loan.dueDate,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
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
}

// Loan History Model
class LoanHistory {
  final int id;
  final double amount;
  final String status;
  final String date;
  final String dueDate;
  final String type;

  LoanHistory({
    required this.id,
    required this.amount,
    required this.status,
    required this.date,
    required this.dueDate,
    required this.type,
  });

  factory LoanHistory.fromJson(Map<String, dynamic> json) {
    final createdAtRaw = json['created_at'];
    final returnDateRaw = json['return_date'];

    String formatDate(String? dateString) {
      if (dateString == null || dateString.isEmpty) return 'N/A';
      try {
        final parsedDate = DateTime.parse(dateString);
        return DateFormat('MMM dd, yyyy').format(parsedDate);
      } catch (e) {
        return 'N/A';
      }
    }

    // Safe conversion for id - handle both String and int from backend
    int safeId = 0;
    final idValue = json['id'];
    if (idValue != null) {
      if (idValue is int) {
        safeId = idValue;
      } else if (idValue is String) {
        safeId = int.tryParse(idValue) ?? 0;
      }
    }

    // Safe conversion for amount
    double safeAmount = 0.0;
    final amountValue = json['amount'];
    if (amountValue != null) {
      if (amountValue is double) {
        safeAmount = amountValue;
      } else if (amountValue is int) {
        safeAmount = amountValue.toDouble();
      } else if (amountValue is String) {
        safeAmount = double.tryParse(amountValue) ?? 0.0;
      }
    }

    return LoanHistory(
      id: safeId,
      amount: safeAmount,
      status: json['status']?.toString() ?? 'Unknown',
      date: formatDate(createdAtRaw),
      dueDate: formatDate(returnDateRaw),
      type: json['reason']?.toString() ?? '',
    );
  }
}