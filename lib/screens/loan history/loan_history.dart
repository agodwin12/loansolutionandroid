import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class LoanHistoryScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final String token;
  var wallet;

  LoanHistoryScreen({
    required this.user,
    this.wallet,
    required this.token,
  });

  @override
  State<LoanHistoryScreen> createState() => _LoanHistoryScreenState();
}

class _LoanHistoryScreenState extends State<LoanHistoryScreen>
    with TickerProviderStateMixin {
  List<LoanHistory> _loans = [];
  List<LoanHistory> _filteredLoans = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedStatus = 'All';
  String _selectedDateRange = 'All Time';
  bool _showFilters = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final TextEditingController _searchController = TextEditingController();
  final List<String> _statusOptions = ['All', 'Active', 'Paid', 'Pending'];
  final List<String> _dateRangeOptions = ['All Time', 'Last 7 Days', 'Last 30 Days', 'Last 90 Days'];

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
    fetchAllLoans();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchAllLoans() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.parse(
        "http://10.0.2.2:3000/api/loans/user/${widget.user['id']}",
      );

      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.token}",
        },
      );

      print("✅ Loan history status: ${response.statusCode}");
      print("✅ Loan history body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> loansJson = data["loans"];

        setState(() {
          _loans = loansJson
              .map((json) => LoanHistory.fromJson(json))
              .toList();
          _filteredLoans = _loans;
        });

        _animationController.forward();
      } else {
        print("❌ Failed to fetch loans: ${response.body}");
      }
    } catch (e) {
      print("❌ Network error while fetching loans: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterLoans() {
    setState(() {
      _filteredLoans = _loans.where((loan) {
        // Search filter
        bool matchesSearch = _searchQuery.isEmpty ||
            loan.type.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            loan.id.toString().contains(_searchQuery) ||
            loan.status.toLowerCase().contains(_searchQuery.toLowerCase());

        // Status filter
        bool matchesStatus = _selectedStatus == 'All' ||
            loan.status.toLowerCase() == _selectedStatus.toLowerCase();

        // Date range filter
        bool matchesDateRange = _selectedDateRange == 'All Time' ||
            _isWithinDateRange(loan.createdAt);

        return matchesSearch && matchesStatus && matchesDateRange;
      }).toList();
    });
  }

  bool _isWithinDateRange(DateTime loanDate) {
    final now = DateTime.now();
    switch (_selectedDateRange) {
      case 'Last 7 Days':
        return loanDate.isAfter(now.subtract(const Duration(days: 7)));
      case 'Last 30 Days':
        return loanDate.isAfter(now.subtract(const Duration(days: 30)));
      case 'Last 90 Days':
        return loanDate.isAfter(now.subtract(const Duration(days: 90)));
      default:
        return true;
    }
  }

  void _onSearchChanged(String query) {
    _searchQuery = query;
    _filterLoans();
  }

  void _onStatusChanged(String status) {
    setState(() {
      _selectedStatus = status;
    });
    _filterLoans();
  }

  void _onDateRangeChanged(String dateRange) {
    setState(() {
      _selectedDateRange = dateRange;
    });
    _filterLoans();
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _selectedStatus = 'All';
      _selectedDateRange = 'All Time';
      _searchController.clear();
      _filteredLoans = _loans;
    });
  }

  String formatCurrency(double amount) {
    return "${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} XAF";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // Custom App Bar
          SliverAppBar(
            expandedHeight: 180.0,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1A1A1A)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF10B981),
                      Color(0xFF059669),
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
                        const Text(
                          "Loan History",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "${_filteredLoans.length} loans found",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Search and Filter Section
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Search loans by ID, type, or status...',
                        prefixIcon: const Icon(Icons.search, color: Color(0xFF6B7280)),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                          icon: const Icon(Icons.clear, color: Color(0xFF6B7280)),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Filter Toggle and Quick Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _showFilters = !_showFilters;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: _showFilters ? const Color(0xFF10B981) : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.filter_list,
                                color: _showFilters ? Colors.white : const Color(0xFF6B7280),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Filters',
                                style: TextStyle(
                                  color: _showFilters ? Colors.white : const Color(0xFF6B7280),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      _buildQuickStats(),
                    ],
                  ),

                  // Expandable Filters
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: _showFilters ? 120 : 0,
                    child: _showFilters ? _buildFilterOptions() : null,
                  ),
                ],
              ),
            ),
          ),

          // Loans List
          _isLoading
              ? const SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF10B981),
              ),
            ),
          )
              : _filteredLoans.isEmpty
              ? SliverFillRemaining(
            child: _buildEmptyState(),
          )
              : SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.3),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: _animationController,
                      curve: Interval(
                        (index / _filteredLoans.length) * 0.5,
                        ((index + 1) / _filteredLoans.length) * 0.5 + 0.5,
                        curve: Curves.easeOut,
                      ),
                    )),
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: 20,
                        right: 20,
                        bottom: index == _filteredLoans.length - 1 ? 100 : 15,
                      ),
                      child: _buildEnhancedLoanCard(_filteredLoans[index]),
                    ),
                  ),
                );
              },
              childCount: _filteredLoans.length,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    final activeLoans = _filteredLoans.where((loan) => loan.status.toLowerCase() == 'active').length;
    final totalAmount = _filteredLoans.fold<double>(0, (sum, loan) => sum + loan.amount);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$activeLoans Active',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF10B981),
                ),
              ),
              Text(
                formatCurrency(totalAmount),
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterOptions() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        children: [
          // Status Filter
          Row(
            children: [
              const Text(
                'Status:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  children: _statusOptions.map((status) {
                    final isSelected = _selectedStatus == status;
                    return GestureDetector(
                      onTap: () => _onStatusChanged(status),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF10B981) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isSelected ? Colors.white : const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Date Range Filter
          Row(
            children: [
              const Text(
                'Period:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  children: _dateRangeOptions.map((range) {
                    final isSelected = _selectedDateRange == range;
                    return GestureDetector(
                      onTap: () => _onDateRangeChanged(range),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF10B981) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          range,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isSelected ? Colors.white : const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              TextButton(
                onPressed: _clearFilters,
                child: const Text(
                  'Clear',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long,
              size: 48,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "No loans found",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty || _selectedStatus != 'All' || _selectedDateRange != 'All Time'
                ? "Try adjusting your search or filters"
                : "You haven't applied for any loans yet",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (_searchQuery.isNotEmpty || _selectedStatus != 'All' || _selectedDateRange != 'All Time')
            ElevatedButton(
              onPressed: _clearFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Clear Filters'),
            ),
        ],
      ),
    );
  }

  Widget _buildEnhancedLoanCard(LoanHistory loan) {
    Color statusColor;
    Color statusBgColor;
    IconData statusIcon;

    switch (loan.status.toLowerCase()) {
      case 'active':
        statusColor = const Color(0xFF10B981);
        statusBgColor = const Color(0xFF10B981).withOpacity(0.1);
        statusIcon = Icons.trending_up;
        break;
      case 'paid':
        statusColor = const Color(0xFF3B82F6);
        statusBgColor = const Color(0xFF3B82F6).withOpacity(0.1);
        statusIcon = Icons.check_circle;
        break;
      case 'pending':
        statusColor = const Color(0xFFF59E0B);
        statusBgColor = const Color(0xFFF59E0B).withOpacity(0.1);
        statusIcon = Icons.schedule;
        break;
      default:
        statusColor = Colors.grey;
        statusBgColor = Colors.grey.withOpacity(0.1);
        statusIcon = Icons.help_outline;
    }

    return Hero(
      tag: 'loan-${loan.id}',
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              children: [
                // Header with gradient
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        statusColor.withOpacity(0.1),
                        statusColor.withOpacity(0.05),
                      ],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: statusBgColor,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    statusIcon,
                                    color: statusColor,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        loan.type.isNotEmpty ? loan.type : "Personal Loan",
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1A1A1A),
                                        ),
                                      ),
                                      Text(
                                        "ID: ${loan.id}",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusBgColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          loan.status.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Amount (highlighted)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              "Loan Amount",
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formatCurrency(loan.amount),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Date Information
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoItem(
                              icon: Icons.calendar_today,
                              label: "Applied On",
                              value: loan.date,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildInfoItem(
                              icon: Icons.event,
                              label: "Due Date",
                              value: loan.dueDate,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: const Color(0xFF6B7280),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ],
      ),
    );
  }
}

class LoanHistory {
  final int id;
  final double amount;
  final String status;
  final String date;
  final String dueDate;
  final String type;
  final DateTime createdAt;

  LoanHistory({
    required this.id,
    required this.amount,
    required this.status,
    required this.date,
    required this.dueDate,
    required this.type,
    required this.createdAt,
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

    DateTime parseDateTime(String? dateString) {
      if (dateString == null || dateString.isEmpty) return DateTime.now();
      try {
        return DateTime.parse(dateString);
      } catch (e) {
        return DateTime.now();
      }
    }

    return LoanHistory(
      id: json['id'] ?? 0,
      amount: (json['amount'] ?? 0).toDouble(),
      status: json['status'] ?? 'Unknown',
      date: formatDate(createdAtRaw),
      dueDate: formatDate(returnDateRaw),
      type: json['reason'] ?? '',
      createdAt: parseDateTime(createdAtRaw),
    );
  }
}