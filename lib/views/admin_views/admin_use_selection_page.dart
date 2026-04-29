import 'package:delivery_app/reusable_widgets/rw_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:delivery_app/firestore/enums/e_packages_status.dart';
import 'package:delivery_app/firestore/models/m_user.dart';
import 'package:delivery_app/firestore/user_db.dart';
import 'package:delivery_app/tools/default_colors.dart';

class AdminUserSelectionPage extends StatefulWidget {
  final EPackageStatus status;
  final Function(UserModel) onUserSelected;

  const AdminUserSelectionPage({
    super.key,
    required this.status,
    required this.onUserSelected,
  });

  @override
  State<AdminUserSelectionPage> createState() => _AdminUserSelectionPageState();
}

class _AdminUserSelectionPageState extends State<AdminUserSelectionPage> {
  final UserDB _userRepo = UserDB();
  UserModel? _selectedUser;
  List<UserModel> _allUsers = []; // Cache the full objects
  late Future<List<UserModel>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _usersFuture = _userRepo.getAllUsers();
  }

  @override
  Widget build(BuildContext context) {
    String title = widget.status == EPackageStatus.payed
        ? "Imprimer Colis Payés"
        : "Imprimer Retours Permanents";

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 500),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text("Veuillez sélectionner un expéditeur pour générer le rapport."),
                      const SizedBox(height: 30),

                      FutureBuilder<List<UserModel>>(
                        future: _usersFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Text("Aucun utilisateur trouvé.");
                          }

                          // Cache the list so we can find the object later
                          _allUsers = snapshot.data!;

                          // Extract only the usernames for the RwDropdown
                          List<String> usernames = _allUsers.map((u) => u.username).toList();

                          return RwDropdown(
                            label: "Expéditeur",
                            hint: "Choisir un utilisateur",
                            prefixIcon: Icons.person,
                            iconColor: DefaultColors.accent,
                            value: _selectedUser?.username,
                            items: usernames,
                            onChanged: (String? selectedUsername) {
                              setState(() {
                                // Find the original UserModel based on the selected string
                                _selectedUser = _allUsers.firstWhere(
                                      (u) => u.username == selectedUsername,
                                );
                              });
                            },
                          );
                        },
                      ),

                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: DefaultColors.accent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: _selectedUser == null
                              ? null
                              : () => widget.onUserSelected(_selectedUser!),
                          child: const Text(
                            "CONTINUER",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}