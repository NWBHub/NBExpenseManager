import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../../services/profile_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.user});

  final UserModel user;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController firstNameCtrl;
  late final TextEditingController lastNameCtrl;
  late final TextEditingController phoneCtrl;
  late final TextEditingController photoUrlCtrl;
  late String currency;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    firstNameCtrl = TextEditingController(text: widget.user.firstName ?? '');
    lastNameCtrl = TextEditingController(text: widget.user.lastName ?? '');
    phoneCtrl = TextEditingController(text: widget.user.phone ?? '');
    photoUrlCtrl = TextEditingController(text: widget.user.photoUrl ?? '');
    currency = widget.user.currency;
  }

  @override
  void dispose() {
    firstNameCtrl.dispose();
    lastNameCtrl.dispose();
    phoneCtrl.dispose();
    photoUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> saveProfile() async {
    setState(() => saving = true);
    try {
      final user = await const ProfileService().updateProfile(
        firstName: firstNameCtrl.text.trim(),
        lastName: lastNameCtrl.text.trim(),
        phone: phoneCtrl.text.trim(),
        photoUrl: photoUrlCtrl.text.trim(),
        currency: currency,
      );
      if (!mounted) return;
      Navigator.pop(context, user);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: CircleAvatar(
              radius: 42,
              backgroundColor: const Color(0xFF5B6EF5).withValues(alpha: 0.12),
              backgroundImage: photoUrlCtrl.text.trim().isEmpty
                  ? null
                  : NetworkImage(photoUrlCtrl.text.trim()),
              child: photoUrlCtrl.text.trim().isEmpty
                  ? Text(
                      widget.user.displayName.characters.first.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5B6EF5),
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: firstNameCtrl,
            decoration: const InputDecoration(labelText: 'First Name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: lastNameCtrl,
            decoration: const InputDecoration(labelText: 'Last Name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Mobile Number'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: photoUrlCtrl,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'Profile Photo URL',
              hintText: 'https://example.com/photo.jpg',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'Email',
              hintText: widget.user.email ?? '',
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: currency,
            items: const [
              DropdownMenuItem(value: 'INR', child: Text('INR')),
              DropdownMenuItem(value: 'USD', child: Text('USD')),
              DropdownMenuItem(value: 'AED', child: Text('AED')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => currency = value);
              }
            },
            decoration: const InputDecoration(labelText: 'Currency'),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: saving ? null : saveProfile,
            child: Text(saving ? 'Saving...' : 'Save Profile'),
          ),
        ],
      ),
    );
  }
}
