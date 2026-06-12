import 'package:flutter/material.dart';
import '../../service/user_service.dart';

class FormDetailUser extends StatefulWidget {
  final int idUser;

  const FormDetailUser({super.key, required this.idUser});

  @override
  State<FormDetailUser> createState() => _FormDetailUserState();
}

class _FormDetailUserState extends State<FormDetailUser> {
  Map<String, dynamic>? user;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDetail();
  }

  void fetchDetail() async {
    try {
      final data = await UserService.getDetailUser(widget.idUser);
      setState(() {
        user = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const AlertDialog(
        content: SizedBox(
          width: 500,
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final u = user;
    if (u == null) {
      return AlertDialog(
        content: const Text('Gagal memuat detail user'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup', style: TextStyle(color: Colors.grey)),
          ),
        ],
      );
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Row(
        children: [
          Icon(Icons.visibility_outlined, color: Color(0xFF1E293B)),
          SizedBox(width: 10),
          Text(
            'Detail Informasi User',
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildReadOnlyField(label: 'ID User', value: u['id_user']?.toString() ?? '-'),
            _buildReadOnlyField(label: 'Nama User', value: u['nama_user'] ?? '-'),
            _buildReadOnlyField(label: 'Email', value: u['email'] ?? '-'),
            _buildReadOnlyField(label: 'Password', value: '********'),
            _buildReadOnlyField(label: 'Role', value: u['role'] ?? '-'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup', style: TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }

  Widget _buildReadOnlyField({required String label, required String value}) {
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
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(value, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
