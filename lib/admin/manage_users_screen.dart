import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_role.dart';

class ManageUsersScreen extends StatefulWidget {
  final String username;
  final UserRole role;

  const ManageUsersScreen({
    super.key,
    required this.username,
    required this.role,
  });

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<String> _departments = [
    'Nursing',
    'Medical-Surgical',
    'Pediatrics',
    'Obstetrics',
    'Psychiatric',
    'Community Health',
    'Administration',
    'Security',
    'General'
  ];
  String _searchQuery = '';
  String _filterRole = 'all';
  String _filterDepartment = 'all';

  void _updateRole(String uid, String newRole, String? department) {
    _firestore.collection('users').doc(uid).update({
      'role': newRole,
      'department': department,
      'updatedBy': widget.username,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  void _showEditDialog(BuildContext context, DocumentSnapshot user) {
    final data = user.data() as Map<String, dynamic>;
    String selectedRole = data['role'] ?? 'student';
    String selectedDepartment = data['department'] ?? 'General';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Edit User Role & Department'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  items: const [
                    DropdownMenuItem(value: 'student', child: Text('Student Nurse')),
                    DropdownMenuItem(value: 'faculty', child: Text('Faculty')),
                    DropdownMenuItem(value: 'hod', child: Text('HOD')),
                    DropdownMenuItem(value: 'security', child: Text('Security')),
                    DropdownMenuItem(value: 'admin', child: Text('Department Admin')),
                  ],
                  onChanged: (value) => setState(() => selectedRole = value!),
                  decoration: const InputDecoration(labelText: 'Role'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedDepartment,
                  items: _departments.map((dept) {
                    return DropdownMenuItem(value: dept, child: Text(dept));
                  }).toList(),
                  onChanged: (value) => setState(() => selectedDepartment = value!),
                  decoration: const InputDecoration(labelText: 'Department'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  _updateRole(user.id, selectedRole, selectedDepartment);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User updated successfully')),
                  );
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddUserDialog(BuildContext context) {
    String selectedRole = 'student';
    String selectedDepartment = 'General';
    final nameController = TextEditingController();
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add New User'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    items: const [
                      DropdownMenuItem(value: 'student', child: Text('Student Nurse')),
                      DropdownMenuItem(value: 'faculty', child: Text('Faculty')),
                      DropdownMenuItem(value: 'hod', child: Text('HOD')),
                      DropdownMenuItem(value: 'security', child: Text('Security')),
                      DropdownMenuItem(value: 'admin', child: Text('Department Admin')),
                    ],
                    onChanged: (value) => setState(() => selectedRole = value!),
                    decoration: const InputDecoration(
                      labelText: 'Role',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedDepartment,
                    items: _departments.map((dept) {
                      return DropdownMenuItem(value: dept, child: Text(dept));
                    }).toList(),
                    onChanged: (value) => setState(() => selectedDepartment = value!),
                    decoration: const InputDecoration(
                      labelText: 'Department',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  _addNewUser(
                    nameController.text,
                    emailController.text,
                    selectedRole,
                    selectedDepartment,
                  );
                  Navigator.pop(context);
                },
                child: const Text('Add User'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _addNewUser(String name, String email, String role, String department) {
    // In a real app, you would create a Firebase Auth user and then add to Firestore
    _firestore.collection('users').add({
      'name': name,
      'email': email,
      'role': role,
      'department': department,
      'createdBy': widget.username,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'active',
    }).then((value) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User added successfully')),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding user: $error')),
      );
    });
  }

  Widget _buildUserStats() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        }

        final users = snapshot.data!.docs;
        final students = users.where((user) => user['role'] == 'student').length;
        final faculty = users.where((user) => user['role'] == 'faculty').length;
        final security = users.where((user) => user['role'] == 'security').length;
        final admins = users.where((user) => user['role'] == 'admin').length;

        return Card(
          elevation: 4,
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Total', users.length, Icons.people),
                _buildStatItem('Students', students, Icons.school),
                _buildStatItem('Faculty', faculty, Icons.person),
                _buildStatItem('Security', security, Icons.security),
                _buildStatItem('Admins', admins, Icons.admin_panel_settings),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, int count, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 30, color: Colors.blue),
        const SizedBox(height: 8),
        Text(
          count.toString(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users - Nursing College'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => _showAddUserDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildUserStats(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search users...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _filterRole,
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All Roles')),
                          DropdownMenuItem(value: 'student', child: Text('Students')),
                          DropdownMenuItem(value: 'faculty', child: Text('Faculty')),
                          DropdownMenuItem(value: 'security', child: Text('Security')),
                          DropdownMenuItem(value: 'admin', child: Text('Admins')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _filterRole = value!;
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'Filter by Role',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _filterDepartment,
                        items: [
                          const DropdownMenuItem(value: 'all', child: Text('All Departments')),
                          ..._departments.map((dept) {
                            return DropdownMenuItem(value: dept, child: Text(dept));
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _filterDepartment = value!;
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'Filter by Department',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var users = snapshot.data!.docs;

                // Apply filters
                if (_searchQuery.isNotEmpty) {
                  users = users.where((user) {
                    final data = user.data() as Map<String, dynamic>;
                    final name = data['name']?.toString().toLowerCase() ?? '';
                    final email = data['email']?.toString().toLowerCase() ?? '';
                    return name.contains(_searchQuery) || email.contains(_searchQuery);
                  }).toList();
                }

                if (_filterRole != 'all') {
                  users = users.where((user) => user['role'] == _filterRole).toList();
                }

                if (_filterDepartment != 'all') {
                  users = users.where((user) => user['department'] == _filterDepartment).toList();
                }

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final data = user.data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getRoleColor(data['role']),
                          child: Text(
                            data['name']?[0].toUpperCase() ?? 'U',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(data['name'] ?? 'No Name'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['email'] ?? 'No Email'),
                            Text('Role: ${_formatRole(data['role'])}'),
                            Text('Department: ${data['department'] ?? 'Not Assigned'}'),
                            if (data['status'] != null)
                              Text('Status: ${data['status']}'),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (action) {
                            if (action == 'edit') {
                              _showEditDialog(context, user);
                            } else if (action == 'view') {
                              _showUserDetails(context, data);
                            } else if (action == 'deactivate') {
                              _toggleUserStatus(user.id, data['status'] == 'active' ? 'inactive' : 'active');
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'edit', child: Text('Edit Role/Dept')),
                            const PopupMenuItem(value: 'view', child: Text('View Details')),
                            PopupMenuItem(
                              value: 'deactivate',
                              child: Text(data['status'] == 'active' ? 'Deactivate' : 'Activate'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String? role) {
    switch (role) {
      case 'admin':
        return Colors.red;
      case 'faculty':
        return Colors.blue;
      case 'security':
        return Colors.orange;
      case 'hod':
        return Colors.purple;
      case 'student':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatRole(String? role) {
    switch (role) {
      case 'student':
        return 'Student Nurse';
      case 'faculty':
        return 'Faculty';
      case 'hod':
        return 'HOD';
      case 'security':
        return 'Security';
      case 'admin':
        return 'Department Admin';
      default:
        return role?.toUpperCase() ?? 'N/A';
    }
  }

  void _toggleUserStatus(String userId, String newStatus) {
    _firestore.collection('users').doc(userId).update({
      'status': newStatus,
      'updatedBy': widget.username,
      'updatedAt': FieldValue.serverTimestamp(),
    }).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User ${newStatus == 'active' ? 'activated' : 'deactivated'}')),
      );
    });
  }

  void _showUserDetails(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('User Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Name:', data['name'] ?? 'N/A'),
              _buildDetailRow('Email:', data['email'] ?? 'N/A'),
              _buildDetailRow('Role:', _formatRole(data['role'])),
              _buildDetailRow('Department:', data['department'] ?? 'Not Assigned'),
              _buildDetailRow('Status:', data['status'] ?? 'active'),
              _buildDetailRow('User ID:', data['uid'] ?? 'N/A'),
              if (data['createdAt'] != null)
                _buildDetailRow('Joined:', _formatDate((data['createdAt'] as Timestamp).toDate())),
              if (data['updatedAt'] != null)
                _buildDetailRow('Last Updated:', _formatDate((data['updatedAt'] as Timestamp).toDate())),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}