import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminService _adminService = AdminService();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Map<String, int>? _statistics;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStatistics() async {
    final stats = await _adminService.getUserStatistics();
    setState(() => _statistics = stats);
  }

  void _handleLogout() async {
    await _authService.signOut();
  }

  Future<void> _changeUserRole(UserProfile user, UserRole newRole) async {
    try {
      await _adminService.changeUserRole(user.uid, newRole);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Zmieniono rolę ${user.email} na ${newRole.value}'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
      _loadStatistics(); // Odśwież statystyki
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd: $e'),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
      }
    }
  }

  void _showRoleChangeDialog(UserProfile user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Zmień rolę: ${user.displayName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Aktualnie: ${user.roleDisplayName}'),
            const SizedBox(height: 16),
            const Text('Wybierz nową rolę:'),
            const SizedBox(height: 16),
            ...UserRole.values.map((role) {
              return ListTile(
                title: Text(_getRoleDisplayName(role)),
                leading: Radio<UserRole>(
                  value: role,
                  groupValue: user.role,
                  onChanged: (UserRole? value) {
                    if (value != null && value != user.role) {
                      Navigator.pop(context);
                      _changeUserRole(user, value);
                    }
                  },
                ),
                onTap: () {
                  if (role != user.role) {
                    Navigator.pop(context);
                    _changeUserRole(user, role);
                  }
                },
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anuluj'),
          ),
        ],
      ),
    );
  }

  String _getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.patient:
        return '👤 Pacjent';
      case UserRole.doctor:
        return '⚕️ Lekarz';
      case UserRole.admin:
        return '👑 Administrator';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: AppTheme.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStatistics,
            tooltip: 'Odśwież',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Wyloguj',
          ),
        ],
      ),
      body: Column(
        children: [
          // Statystyki
          if (_statistics != null)
            Container(
              padding: const EdgeInsets.all(16),
              color: AppTheme.primaryBlue.withOpacity(0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatChip(
                    '👥 Wszyscy',
                    _statistics!['total']!,
                    AppTheme.primaryBlue,
                  ),
                  _buildStatChip(
                    '👤 Pacjenci',
                    _statistics!['patients']!,
                    AppTheme.successGreen,
                  ),
                  _buildStatChip(
                    '⚕️ Lekarze',
                    _statistics!['doctors']!,
                    AppTheme.warningOrange,
                  ),
                  _buildStatChip(
                    '👑 Admini',
                    _statistics!['admins']!,
                    AppTheme.dangerRed,
                  ),
                ],
              ),
            ),

          // Wyszukiwarka
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Szukaj po email lub nazwie...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppTheme.lightGray,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),

          // Lista użytkowników
          Expanded(
            child: StreamBuilder<List<UserProfile>>(
              stream: _adminService.getAllUsersStream(
                searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Błąd: ${snapshot.error}'));
                }

                final users = snapshot.data ?? [];

                if (users.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'Brak użytkowników'
                              : 'Nie znaleziono użytkowników',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return _buildUserCard(user);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, int count, Color color) {
    return Chip(
      label: Column(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
      backgroundColor: color.withOpacity(0.1),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
    );
  }

  Widget _buildUserCard(UserProfile user) {
    Color roleColor;
    IconData roleIcon;

    switch (user.role) {
      case UserRole.admin:
        roleColor = AppTheme.dangerRed;
        roleIcon = Icons.admin_panel_settings;
        break;
      case UserRole.doctor:
        roleColor = AppTheme.warningOrange;
        roleIcon = Icons.medical_services;
        break;
      case UserRole.patient:
        roleColor = AppTheme.successGreen;
        roleIcon = Icons.person;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showRoleChangeDialog(user),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: roleColor.withOpacity(0.1),
                child: Icon(roleIcon, color: roleColor, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: roleColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        user.roleDisplayName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: roleColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.edit, color: AppTheme.primaryBlue),
            ],
          ),
        ),
      ),
    );
  }
}
