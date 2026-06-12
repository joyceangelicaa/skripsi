import 'package:flutter/material.dart';
import '../../global_widget/confirmation_dialog.dart';
import '../../service/user_service.dart';

class FormInputUser extends StatefulWidget {
  final int nextId;

  const FormInputUser({super.key, required this.nextId});

  @override
  State<FormInputUser> createState() => _FormInputUserState();
}

class _FormInputUserState extends State<FormInputUser> {
  final namaController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  
  // Mengganti TextEditingController dengan variabel String untuk menyimpan pilihan Dropdown
  String? selectedRole;
  final List<String> roleOptions = ['admin', 'karyawan'];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Row(
        children: [
          Icon(Icons.person_add_alt_1_outlined, color: Color(0xFF1E293B)),
          SizedBox(width: 10),
          Text(
            'Tambah User Baru',
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
              _buildReadOnlyField(label: 'ID User', hint: widget.nextId.toString()),
              _buildField(label: 'Nama User', controller: namaController),
              _buildField(label: 'Email', controller: emailController),
              Row(
                children: [
                  Expanded(child: _buildField(label: 'Password', controller: passwordController)),
                  const SizedBox(width: 20),
                  // Menggunakan custom Dropdown field di sini
                  Expanded(child: _buildDropdownField(label: 'Role')),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () async {
            // Validasi diubah: mengecek apakah selectedRole masih null
            if (namaController.text.isEmpty ||
                emailController.text.isEmpty ||
                passwordController.text.isEmpty ||
                selectedRole == null) {
              showDialog(
                context: context,
                builder: (context) => const ConfirmationDialog(
                  isSuccess: false,
                  title: 'Lengkapi Data',
                  message: 'Semua field harus diisi.',
                ),
              );
              return;
            }

            try {
              await UserService.addUser({
                "nama_user": namaController.text,
                "email": emailController.text,
                "password": passwordController.text,
                "role": selectedRole, // Menggunakan selectedRole di sini
              });

              Navigator.pop(context);

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const ConfirmationDialog(
                  isSuccess: true,
                  title: 'Berhasil Disimpan!',
                  message: 'Data user berhasil ditambahkan.',
                ),
              );
            } catch (e) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => ConfirmationDialog(
                  isSuccess: false,
                  title: 'Gagal Menyimpan',
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
          child: const Text('Simpan User'),
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
                width: constraints.maxWidth,
                hintText: 'Pilih Role',
                
                // Tambahan di sini: 
                // Membuatnya langsung membuka menu saat diklik dan mencegah keyboard muncul
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

  Widget _buildReadOnlyField({required String label, required String hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(hint, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}