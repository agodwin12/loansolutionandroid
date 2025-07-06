import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class LoanManagementScreen extends StatefulWidget {
  final Map<String, dynamic> admin;
  final String token;

  const LoanManagementScreen({
    Key? key,
    required this.admin,
    required this.token,
  }) : super(key: key);

  @override
  State<LoanManagementScreen> createState() => _LoanManagementScreenState();
}

class _LoanManagementScreenState extends State<LoanManagementScreen>
    with TickerProviderStateMixin {
  List<dynamic> _allLoans = [];
  List<dynamic> _filteredLoans = [];
  bool _loading = false;
  String _searchQuery = '';
  String _selectedFilter = 'All';
  String _sortBy = 'Amount (High to Low)';

  AnimationController? _animationController;
  AnimationController? _filterAnimationController;
  Animation<double>? _fadeAnimation;
  Animation<Offset>? _slideAnimation;
  Animation<double>? _filterFadeAnimation;

  final TextEditingController _searchController = TextEditingController();
  bool _showFilters = false;

  final List<String> _filterOptions = ['All', 'High Amount', 'Recent', 'Urgent'];
  final List<String> _sortOptions = [
    'Amount (High to Low)',
    'Amount (Low to High)',
    'Date (Newest)',
    'Date (Oldest)'
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    _filterAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );

    // Initialize animations
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeOutCubic,
    ));

    _filterFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _filterAnimationController!,
      curve: Curves.easeInOut,
    ));

    fetchPendingLoans();
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _filterAnimationController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchPendingLoans() async {
    setState(() {
      _loading = true;
    });

    final url = Uri.parse("http://10.0.2.2:3000/api/admin/loans/pending");

    try {
      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer ${widget.token}",
          "Content-Type": "application/json",
        },
      );

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("Parsed data: $data");

        setState(() {
          _allLoans = data['loans'] ?? [];
          _filteredLoans = List.from(_allLoans);
        });

        print("All loans count: ${_allLoans.length}");
        print("Filtered loans count: ${_filteredLoans.length}");

        if (_allLoans.isNotEmpty) {
          _animationController!.forward();
        }
      } else {
        print("Error: ${response.statusCode} - ${response.body}");
        _showErrorSnackBar("Failed to load loans: ${response.statusCode}");
      }
    } catch (e) {
      print("Network error: $e");
      _showErrorSnackBar("Network error occurred: $e");
    }

    setState(() {
      _loading = false;
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[400],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green[400],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _filterLoans() {
    List<dynamic> filtered = List.from(_allLoans);

    // Search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((loan) {
        final userName = (loan['user']?['name'] ?? '').toString().toLowerCase();
        final loanId = loan['id'].toString();
        final reason = (loan['reason'] ?? '').toString().toLowerCase();
        final query = _searchQuery.toLowerCase();

        return userName.contains(query) ||
            loanId.contains(query) ||
            reason.contains(query);
      }).toList();
    }

    // Category filter
    switch (_selectedFilter) {
      case 'High Amount':
        filtered = filtered.where((loan) =>
        (loan['amount'] ?? 0) >= 100000).toList();
        break;
      case 'Recent':
        filtered.sort((a, b) {
          final dateA = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime.now();
          final dateB = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime.now();
          return dateB.compareTo(dateA);
        });
        break;
      case 'Urgent':
        filtered = filtered.where((loan) {
          final returnDate = DateTime.tryParse(loan['return_date'] ?? '');
          if (returnDate == null) return false;
          final daysUntilReturn = returnDate.difference(DateTime.now()).inDays;
          return daysUntilReturn <= 7;
        }).toList();
        break;
    }

    // Sort
    switch (_sortBy) {
      case 'Amount (High to Low)':
        filtered.sort((a, b) =>
            (b['amount'] ?? 0).compareTo(a['amount'] ?? 0));
        break;
      case 'Amount (Low to High)':
        filtered.sort((a, b) =>
            (a['amount'] ?? 0).compareTo(b['amount'] ?? 0));
        break;
      case 'Date (Newest)':
        filtered.sort((a, b) {
          final dateA = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime.now();
          final dateB = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime.now();
          return dateB.compareTo(dateA);
        });
        break;
      case 'Date (Oldest)':
        filtered.sort((a, b) {
          final dateA = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime.now();
          final dateB = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime.now();
          return dateA.compareTo(dateB);
        });
        break;
    }

    setState(() {
      _filteredLoans = filtered;
    });
  }

  String formatCurrency(double amount) {
    final formatter = NumberFormat("#,###", "en_US");
    return "${formatter.format(amount)} XAF";
  }

  String formatDate(String? dateStr) {
    if (dateStr == null) return "N/A";
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return "N/A";
    }
  }

  Future<void> approveLoan(int loanId) async {
    final url = Uri.parse("http://10.0.2.2:3000/api/admin/loans/$loanId/approve");

    try {
      final response = await http.put(
        url,
        headers: {
          "Authorization": "Bearer ${widget.token}",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        _showSuccessSnackBar("Loan approved successfully!");
        fetchPendingLoans();
      } else {
        _showErrorSnackBar("Failed to approve loan: ${response.statusCode}");
      }
    } catch (e) {
      _showErrorSnackBar("Error approving loan: $e");
    }
  }

  Future<void> rejectLoan(int loanId, String reason) async {
    final url = Uri.parse("http://10.0.2.2:3000/api/admin/loans/$loanId/reject");

    try {
      final response = await http.put(
        url,
        headers: {
          "Authorization": "Bearer ${widget.token}",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "rejection_reason": reason,
        }),
      );

      if (response.statusCode == 200) {
        _showSuccessSnackBar("Loan rejected");
        fetchPendingLoans();
      } else {
        _showErrorSnackBar("Failed to reject loan: ${response.statusCode}");
      }
    } catch (e) {
      _showErrorSnackBar("Error rejecting loan: $e");
    }
  }

  Future<void> processingLoan(int loanId) async {
    final url = Uri.parse("http://10.0.2.2:3000/api/admin/loans/$loanId/processing");

    try {
      final response = await http.put(
        url,
        headers: {
          "Authorization": "Bearer ${widget.token}",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        _showSuccessSnackBar("Loan marked as processing");
        fetchPendingLoans();
      } else {
        _showErrorSnackBar("Failed to update loan: ${response.statusCode}");
      }
    } catch (e) {
      _showErrorSnackBar("Error updating loan: $e");
    }
  }

  void _showRejectDialog(int loanId) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text("Reject Loan", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Please provide a reason for rejecting this loan:"),
            SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: "Rejection reason",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.red[400]!, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                rejectLoan(loanId, controller.text.trim());
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text("Reject", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon) {
    final isSelected = _selectedFilter == label;
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      child: FilterChip(
        selected: isSelected,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.green[700]),
            SizedBox(width: 4),
            Text(label, style: TextStyle(
              color: isSelected ? Colors.white : Colors.green[700],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            )),
          ],
        ),
        onSelected: (selected) {
          setState(() {
            _selectedFilter = label;
          });
          _filterLoans();
        },
        backgroundColor: Colors.green[50],
        selectedColor: Colors.green[600],
        elevation: isSelected ? 4 : 1,
        shadowColor: Colors.green[200],
      ),
    );
  }

  Widget _buildLoanCard(dynamic loan, int index) {
    final user = loan["user"];
    final amount = ((loan['amount'] ?? 0) is String)
        ? double.tryParse(loan['amount'].toString()) ?? 0.0
        : (loan['amount'] ?? 0).toDouble();
    final totalPayable = ((loan['total_payable'] ?? 0) is String)
        ? double.tryParse(loan['total_payable'].toString()) ?? 0.0
        : (loan['total_payable'] ?? 0).toDouble();

    return AnimatedBuilder(
      animation: _fadeAnimation!,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation!,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset(0, 0.3),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: _animationController!,
                curve: Interval(
                  (index * 0.1).clamp(0.0, 1.0),
                  ((index * 0.1) + 0.3).clamp(0.0, 1.0),
                  curve: Curves.easeOutCubic,
                ),
              ),
            ),
            child: Container(
              margin: EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 0,
                    blurRadius: 20,
                    offset: Offset(0, 4),
                  ),
                ],
                border: Border.all(color: Colors.grey[100]!),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    // Add tap animation or navigation
                  },
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with loan ID and status
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                "ID: ${loan['id']}",
                                style: TextStyle(
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.orange[50],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                "PENDING",
                                style: TextStyle(
                                  color: Colors.orange[700],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),

                        // User info section
                        Row(
                          children: [
                            Hero(
                              tag: "avatar_${loan['id']}",
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.green.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 28,
                                  backgroundImage: user?["profile_image_url"] != null
                                      ? NetworkImage("http://10.0.2.2:3000/uploads/${user!["profile_image_url"]}")
                                      : null,
                                  child: user?["profile_image_url"] == null
                                      ? Icon(Icons.person, color: Colors.white, size: 28)
                                      : null,
                                  backgroundColor: Colors.green[600],
                                ),
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user?["name"] ?? "Unknown User",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.phone, size: 16, color: Colors.grey[500]),
                                      SizedBox(width: 4),
                                      Text(
                                        user?["phone"] ?? "No phone",
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),

                        // Amount section with gradient background
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.green[400]!, Colors.green[600]!],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Text(
                                "Loan Amount",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                formatCurrency(amount),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Total Payable: ${formatCurrency(totalPayable)}",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16),

                        // Loan details
                        _buildDetailRow(Icons.description, "Reason", loan['reason'] ?? 'N/A'),
                        SizedBox(height: 8),
                        _buildDetailRow(Icons.calendar_today, "Return Date", formatDate(loan['return_date'])),
                        SizedBox(height: 8),
                        _buildDetailRow(Icons.account_balance_wallet, "Wallet ID", "${loan['wallet_id']}"),
                        SizedBox(height: 20),

                        // Action buttons
                        Row(
                          children: [
                            Expanded(
                              child: _buildActionButton(
                                "Processing",
                                Icons.hourglass_empty,
                                Colors.blue[400]!,
                                    () => processingLoan(loan['id']),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: _buildActionButton(
                                "Reject",
                                Icons.close,
                                Colors.red[400]!,
                                    () => _showRejectDialog(loan['id']),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: _buildActionButton(
                                "Approve",
                                Icons.check,
                                Colors.green[500]!,
                                    () => approveLoan(loan['id']),
                                isPrimary: true,
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
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[500]),
        SizedBox(width: 8),
        Text(
          "$label: ",
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 14,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(String text, IconData icon, Color color, VoidCallback onPressed, {bool isPrimary = false}) {
    return Container(
      height: 44,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? color : color.withOpacity(0.1),
          foregroundColor: isPrimary ? Colors.white : color,
          elevation: isPrimary ? 4 : 0,
          shadowColor: isPrimary ? color.withOpacity(0.5) : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16),
            SizedBox(width: 4),
            Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // Modern App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                "Loan Management",
                style: TextStyle(
                  color: Colors.grey[800],
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green[400]!, Colors.green[600]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.refresh, color: Colors.grey[700]),
                onPressed: fetchPendingLoans,
              ),
              IconButton(
                icon: Icon(
                  _showFilters ? Icons.filter_list_off : Icons.filter_list,
                  color: Colors.grey[700],
                ),
                onPressed: () {
                  setState(() {
                    _showFilters = !_showFilters;
                  });
                  if (_showFilters) {
                    _filterAnimationController?.forward();
                  } else {
                    _filterAnimationController?.reverse();
                  }
                },
              ),
            ],
          ),

          // Search and Filters
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              child: Column(
                children: [
                  // Search Bar
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: "Search by name, ID, or reason...",
                          prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                            icon: Icon(Icons.clear, color: Colors.grey[500]),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                              _filterLoans();
                            },
                          )
                              : null,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                          _filterLoans();
                        },
                      ),
                    ),
                  ),

                  // Animated Filters
                  AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    height: _showFilters ? null : 0,
                    child: Opacity(
                      opacity: _showFilters ? 1.0 : 0.0,
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            // Filter Chips
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _buildFilterChip('All', Icons.list),
                                  _buildFilterChip('High Amount', Icons.trending_up),
                                  _buildFilterChip('Recent', Icons.access_time),
                                  _buildFilterChip('Urgent', Icons.priority_high),
                                ],
                              ),
                            ),

                            // Sort Dropdown
                            Padding(
                              padding: EdgeInsets.all(16),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: DropdownButton<String>(
                                  value: _sortBy,
                                  isExpanded: true,
                                  underline: SizedBox(),
                                  icon: Icon(Icons.arrow_drop_down, color: Colors.green[600]),
                                  style: TextStyle(color: Colors.grey[800], fontSize: 14),
                                  items: _sortOptions.map((option) {
                                    return DropdownMenuItem<String>(
                                      value: option,
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 16),
                                        child: Row(
                                          children: [
                                            Icon(Icons.sort, size: 16, color: Colors.grey[600]),
                                            SizedBox(width: 8),
                                            Text(option),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _sortBy = value!;
                                    });
                                    _filterLoans();
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Results count
                  if (!_loading)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Text(
                            "${_filteredLoans.length} loan${_filteredLoans.length != 1 ? 's' : ''} found",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Loan List
          _loading
              ? SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Colors.green[600],
                    strokeWidth: 3,
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Loading loans...",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          )
              : _filteredLoans.isEmpty
              ? SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 16),
                  Text(
                    "No loans found",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Try adjusting your filters or search terms",
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                        _selectedFilter = 'All';
                        _searchController.clear();
                      });
                      _filterLoans();
                    },
                    child: Text("Clear Filters"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          )
              : SliverPadding(
            padding: EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  return _buildLoanCard(_filteredLoans[index], index);
                },
                childCount: _filteredLoans.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}