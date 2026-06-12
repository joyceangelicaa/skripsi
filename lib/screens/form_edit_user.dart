import 'package:flutter/material.dart';
import '../../global_widget/confirmation_dialog.dart';
import '../../service/user_service.dart';

class FormEditUser extends StatefulWidget {
  final int idUser;
  final String namaAwal;
  final String emailAwal;
  final String passwordAwal;
  final String roleAwal;

  const FormEditUser({
    super.key,
    required this.idUser,
    required this.namaAwal,
    required this.emailAwal,
    required this.passwordAwal,
    required this.roleAwal,
  });

  @override
  State<FormEditUser> createState() => _FormEditUserState();
}

class _FormEditUserState extends State<FormEditUser> {
  late TextEditingController namaController;
  late TextEditingController emailController;
  late TextEditingController passwordController;
  bool isLoading = false;

  // Variabel untuk Dropdown Role
  String? selectedRole;
  final List<String> roleOptions = ['admin', 'karyawan'];

  @override
  void initState() {
    super.initState();
    namaController = TextEditingController(text: widget.namaAwal);
    emailController = TextEditingController(text: widget.emailAwal);
    passwordController = TextEditingController();
    
    // Set nilai awal untuk dropdown sesuai data yang mau diedit
    selectedRole = widget.roleAwal;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Row(
        children: [
          Icon(Icons.edit_note_outlined, color: Color(0xFF1E293B)),
          SizedBox(width: 10),
          Text(
            'Edit Informasi User',
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildField(label: 'Nama User', controller: namaController),
              _buildField(label: 'Email', controller: emailController),
              
              // Disusun ke bawah (Row dihapus)
              _buildField(label: 'Password', controller: passwordController),
              _buildDropdownField(label: 'Role'),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.pop(context),
          child: const Text('Batal', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: isLoading
              ? null
              : () async {
                  // Validasi menggunakan selectedRole
                  if (namaController.text.isEmpty ||
                      emailController.text.isEmpty ||
                      selectedRole == null) {
                    showDialog(
                      context: context,
                      builder: (context) => const ConfirmationDialog(
                        isSuccess: false,
                        title: 'Lengkapi Data',
                        message: 'Nama, email, dan role harus diisi.',
                      ),
                    );
                    return;
                  }

                  setState(() => isLoading = true);

                  try {
                    final body = {
                      "id_user": widget.idUser,
                      "nama_user": namaController.text,
                      "email": emailController.text,
                      "role": selectedRole, // Menggunakan selectedRole
                    };

                    if (passwordController.text.isNotEmpty) {
                      body["password"] = passwordController.text;
                    }

                    await UserService.editUser(body);

                    Navigator.pop(context);

                    showDialog(
                      context: context,
                      builder: (context) => const ConfirmationDialog(
                        isSuccess: true,
                        title: 'Berhasil',
                        message: 'User berhasil diupdate',
                      ),
                    );
                  } catch (e) {
                    setState(() => isLoading = false);
                    showDialog(
                      context: context,
                      builder: (context) => ConfirmationDialog(
                        isSuccess: false,
                        title: 'Gagal',
                        message: e.toString().replaceAll('Exception: ', ''),
                      ),
                    );
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E293B),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Simpan Perubahan'),
        ),
      ],
    );
  }

  Widget _buildField({required String label, required TextEditingController controller}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF1E293B)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget baru untuk DropdownMenu Role
  Widget _buildDropdownField({required String label}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              return DropdownMenu<String>(
                initialSelection: selectedRole, // Menampilkan data role lama
                width: constraints.maxWidth,
                hintText: 'Pilih Role',
                requestFocusOnTap: false,
                enableFilter: false,
                inputDecorationTheme: InputDecorationTheme(
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF1E293B)),
                  ),
                ),
                dropdownMenuEntries: roleOptions.map((String role) {
                  return DropdownMenuEntry<String>(
                    value: role,
                    label: role,
                  );
                }).toList(),
                onSelected: (String? newValue) {
                  setState(() {
                    selectedRole = newValue;
                  });
                },
              );
            }
          ),
        ],
      ),
    );
  }
}