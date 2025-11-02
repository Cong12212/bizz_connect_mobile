// This file can be deleted - functionality moved to settings_page.dart
// Keeping for reference only

// lib/features/settings/widgets/_business_card_section.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../data/settings_repository.dart';
import '../data/settings_models.dart'; // Assuming models were moved here
import 'error_box.dart'; // Import the new error box file

class BusinessCardSection extends StatefulWidget {
  const BusinessCardSection({required this.repo, super.key});

  final dynamic repo;

  @override
  State<BusinessCardSection> createState() => _BusinessCardSectionState();
}

class _BusinessCardSectionState extends State<BusinessCardSection> {
  bool loading = true;
  bool saving = false;
  String? err;

  // fields
  final fullName = TextEditingController();
  final email = TextEditingController();
  final jobTitle = TextEditingController();
  final phone = TextEditingController();
  final mobile = TextEditingController();
  final website = TextEditingController();
  final linkedin = TextEditingController();
  final notes = TextEditingController();
  final address1 = TextEditingController();
  final address2 = TextEditingController();
  final city = TextEditingController();
  final stateCtrl = TextEditingController();
  final country = TextEditingController();
  bool isPublic = true;
  File? avatarFile;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    fullName.dispose();
    email.dispose();
    jobTitle.dispose();
    phone.dispose();
    mobile.dispose();
    website.dispose();
    linkedin.dispose();
    notes.dispose();
    address1.dispose();
    address2.dispose();
    city.dispose();
    stateCtrl.dispose();
    country.dispose();
    super.dispose();
  }

  // --- Logic Methods ---

  Future<void> _load() async {
    setState(() {
      loading = true;
      err = null;
    });
    try {
      final c = await widget.repo.getBusinessCard();
      if (c != null) {
        fullName.text = c.fullName;
        email.text = c.email;
        jobTitle.text = c.jobTitle ?? '';
        phone.text = c.phone ?? '';
        mobile.text = c.mobile ?? '';
        website.text = c.website ?? '';
        linkedin.text = c.linkedin ?? '';
        notes.text = c.notes ?? '';
        address1.text = c.addressLine1 ?? '';
        address2.text = c.addressLine2 ?? '';
        city.text = c.city ?? '';
        stateCtrl.text = c.state ?? '';
        country.text = c.country ?? '';
        isPublic = c.isPublic;
        // avatarFile is for new upload/change only, not for current display
      }
    } on DioException catch (e) {
      err = _prettyError(e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _pickAvatar() async {
    final img = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (img != null) setState(() => avatarFile = File(img.path));
  }

  Future<void> _save() async {
    setState(() {
      saving = true;
      err = null;
    });
    try {
      final form = BusinessCardForm()
        ..fullName = fullName.text.trim()
        ..email = email.text.trim()
        ..jobTitle = _nn(jobTitle.text)
        ..phone = _nn(phone.text)
        ..mobile = _nn(mobile.text)
        ..website = _nn(website.text)
        ..linkedin = _nn(linkedin.text)
        ..notes = _nn(notes.text)
        ..addressLine1 = _nn(address1.text)
        ..addressLine2 = _nn(address2.text)
        ..city = _nn(city.text)
        ..state = _nn(stateCtrl.text)
        ..country = _nn(country.text)
        ..isPublic = isPublic
        ..avatarFile = avatarFile;

      await widget.repo.saveBusinessCard(form);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Business card saved!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on DioException catch (e) {
      setState(() => err = _prettyError(e));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete business card?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await widget.repo.deleteBusinessCard();
      fullName.clear();
      email.clear();
      jobTitle.clear();
      phone.clear();
      mobile.clear();
      website.clear();
      linkedin.clear();
      notes.clear();
      address1.clear();
      address2.clear();
      city.clear();
      stateCtrl.clear();
      country.clear();
      setState(() {
        avatarFile = null;
        isPublic = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Business card deleted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_prettyError(e)), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- Helper Methods ---

  BoxDecoration _box() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: Colors.grey.shade200),
  );

  Widget _tf(
    TextEditingController c,
    String label,
    IconData? icon, {
    TextInputType? keyboard,
  }) => TextField(
    controller: c,
    keyboardType: keyboard,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon) : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );

  Widget _ta(TextEditingController c, String label) => TextField(
    controller: c,
    maxLines: 3,
    decoration: InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );

  String _prettyError(DioException e) {
    final code = e.response?.statusCode;
    final msg = e.response?.data is Map
        ? (e.response?.data['message']?.toString() ?? e.message ?? '')
        : e.message ?? 'Unknown error';
    return 'Error $code: $msg';
  }

  String? _nn(String v) => v.trim().isEmpty ? null : v.trim();

  // --- Build Method ---

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _box(),
      padding: const EdgeInsets.all(16),
      child: loading
          ? const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Business Card',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (fullName.text.isNotEmpty || email.text.isNotEmpty)
                      TextButton(
                        onPressed: _delete,
                        child: const Text('Delete'),
                      ),
                  ],
                ),
                if (err != null) ...[
                  const SizedBox(height: 8),
                  ErrorBox(message: err!),
                ],
                const SizedBox(height: 8),
                _tf(fullName, 'Full name *', Icons.badge_outlined),
                const SizedBox(height: 12),
                _tf(
                  email,
                  'Email *',
                  Icons.email_outlined,
                  keyboard: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                _tf(jobTitle, 'Job title', Icons.work_outline),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _tf(phone, 'Phone', Icons.phone_outlined)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _tf(mobile, 'Mobile', Icons.smartphone_outlined),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _tf(website, 'Website', Icons.public),
                const SizedBox(height: 12),
                _tf(linkedin, 'LinkedIn', Icons.link_outlined),
                const SizedBox(height: 12),
                _ta(notes, 'Notes'),
                const SizedBox(height: 12),
                const Text(
                  'Address',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                _tf(address1, 'Address line 1', Icons.home_outlined),
                const SizedBox(height: 12),
                _tf(address2, 'Address line 2', Icons.home),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _tf(
                        country,
                        'Country (code e.g. VN/US)',
                        Icons.flag_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _tf(
                        stateCtrl,
                        'State/Province',
                        Icons.map_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _tf(
                        city,
                        'City/District',
                        Icons.location_city_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: isPublic,
                  onChanged: (v) => setState(() => isPublic = v),
                  title: const Text('Make card public'),
                  subtitle: const Text(
                    'Allow others to view and connect with you',
                  ),
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _pickAvatar,
                      icon: const Icon(Icons.image_outlined),
                      label: Text(
                        avatarFile == null ? 'Pick avatar' : 'Change avatar',
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (avatarFile != null)
                      Text(
                        avatarFile!.path.split('/').last,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: saving ? null : _save,
                  child: Text(saving ? 'Saving...' : 'Save Business Card'),
                ),
              ],
            ),
    );
  }
}
