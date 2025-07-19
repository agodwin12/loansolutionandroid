import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class UserManagementScreen extends StatefulWidget {
  final Map<String, dynamic> admin;
  final String token;

  const UserManagementScreen({
    Key? key,
    required this.admin,
    required this.token,
  }) : super(key: key);

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> users = [];
  List<dynamic> admins = [];
  bool isLoading = false;
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchAllUsersAndAdmins();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> fetchAllUsersAndAdmins() async {
    setState(() {
      isLoading = true;
    });

    try {
      final userRes = await http.get(
        Uri.parse("http://16.171.240.97:3000/api/admin/users"),
        headers: {
          "Authorization": "Bearer ${widget.token}",
          "Content-Type": "application/json",
        },
      );

      final adminRes = await http.get(
        Uri.parse("http://16.171.240.97:3000/api/admin/admins"),
        headers: {
          "Authorization": "Bearer ${widget.token}",
          "Content-Type": "application/json",
        },
      );

      if (userRes.statusCode == 200 && adminRes.statusCode == 200) {
        setState(() {
          users = jsonDecode(userRes.body)['users'];
          admins = jsonDecode(adminRes.body)['admins'];
        });
      } else {
        showError("Failed to fetch data.");
      }
    } catch (e) {
      showError("Network error: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> deleteUser(int userId) async {
    final confirmed = await _showDeleteConfirmation("user");
    if (!confirmed) return;

    try {
      final res = await http.delete(
        Uri.parse("http://16.171.240.97:3000/api/admin/users/$userId"),
        headers: {
          "Authorization": "Bearer ${widget.token}",
          "Content-Type": "application/json",
        },
      );
      if (res.statusCode == 200) {
        showSuccess("User deleted successfully");
        fetchAllUsersAndAdmins();
      } else {
        showError("Failed to delete user.");
      }
    } catch (e) {
      showError("Network error: $e");
    }
  }

  Future<void> deleteAdmin(int adminId) async {
    final confirmed = await _showDeleteConfirmation("admin");
    if (!confirmed) return;

    try {
      final res = await http.delete(
        Uri.parse("http://16.171.240.97:3000/api/admin/admins/$adminId"),
        headers: {
          "Authorization": "Bearer ${widget.token}",
          "Content-Type": "application/json",
        },
      );
      if (res.statusCode == 200) {
        showSuccess("Admin deleted successfully");
        fetchAllUsersAndAdmins();
      } else {
        showError("Failed to delete admin.");
      }
    } catch (e) {
      showError("Network error: $e");
    }
  }

  Future<bool> _showDeleteConfirmation(String type) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Delete $type"),
        content: Text("Are you sure you want to delete this $type? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text("Cancel", style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Delete"),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          "User Management",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey.shade800,
        elevation: 0,
        bottom: _tabController != null ? TabBar(
          controller: _tabController,
          labelColor: Colors.blue.shade600,
          unselectedLabelColor: Colors.grey.shade500,
          indicatorColor: Colors.blue.shade600,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.admin_panel_settings, size: 20),
                  const SizedBox(width: 8),
                  Text("Admins (${admins.length})"),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.people, size: 20),
                  const SizedBox(width: 8),
                  Text("Users (${users.length})"),
                ],
              ),
            ),
          ],
        ) : null,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tabController != null ? TabBarView(
        controller: _tabController,
        children: [
          RefreshIndicator(
            onRefresh: fetchAllUsersAndAdmins,
            child: _buildAdminsList(),
          ),
          RefreshIndicator(
            onRefresh: fetchAllUsersAndAdmins,
            child: _buildUsersList(),
          ),
        ],
      ) : const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildAdminsList() {
    if (admins.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.admin_panel_settings_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "No admins found",
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: admins.length,
      itemBuilder: (context, index) => _buildAdminCard(admins[index]),
    );
  }

  Widget _buildUsersList() {
    if (users.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "No users found",
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (context, index) => _buildUserCard(users[index]),
    );
  }

  Widget _buildAdminCard(Map admin) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade200, width: 2),
              ),
              child: CircleAvatar(
                backgroundImage: admin['profile_image_url'] != null
                    ? NetworkImage("http://16.171.240.97:3000/uploads/${admin['profile_image_url']}")
                    : null,
                child: admin['profile_image_url'] == null
                    ? Icon(Icons.person, color: Colors.grey.shade600)
                    : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    admin['name'] ?? "No name",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    admin['email'] ?? "No email",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      admin['role'] ?? "Admin",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.red.shade600),
                onPressed: () => deleteAdmin(admin['id']),
                tooltip: "Delete admin",
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(Map user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade200, width: 2),
              ),
              child: CircleAvatar(
                backgroundImage: user['profile_image_url'] != null
                    ? NetworkImage("http://16.171.240.97:3000/uploads/${user['profile_image_url']}")
                    : null,
                child: user['profile_image_url'] == null
                    ? Icon(Icons.person, color: Colors.grey.shade600)
                    : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user['name'] ?? "No name",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user['email'] ?? "No email",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.red.shade600),
                onPressed: () => deleteUser(user['id']),
                tooltip: "Delete user",
              ),
            ),
          ],
        ),
      ),
    );
  }
}