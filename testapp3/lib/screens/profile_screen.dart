import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_profile.dart';
import '../services/user_profile_service.dart';
import '../services/notification_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _photoUrlController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;
  bool _hasProfile = false;
  bool _isGuest = false;
  bool _waterNotificationsEnabled = false;

  UserProfile _currentProfile = UserProfile.empty();

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Guest mode: there is no authenticated user, so profiles are disabled.
      _isGuest = true;
      _isLoading = false;
    } else {
      _loadProfile();
      _loadWaterNotificationStatus();
    }
  }

  Future<void> _loadWaterNotificationStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      final data = doc.data() ?? <String, dynamic>{};
      final enabled = data['waterEnabled'] as bool? ?? false;
      if (mounted) {
        setState(() {
          _waterNotificationsEnabled = enabled;
        });
      }
    } catch (e) {
      debugPrint('Error loading water notification status: $e');
    }
  }

  Future<void> _toggleWaterNotifications(bool newValue) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _waterNotificationsEnabled = newValue;
    });

    try {
      // Update Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'waterEnabled': newValue,
      }, SetOptions(merge: true));

      // Schedule or cancel notifications based on new state
      if (newValue) {
        await scheduleDailyHydrationReminders();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Water reminders enabled'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        await cancelHydrationReminders();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Water reminders disabled'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error toggling water notifications: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
        // Revert the toggle on error
        setState(() {
          _waterNotificationsEnabled = !newValue;
        });
      }
    }
  }

  Future<void> _loadProfile() async {
    final profile = await UserProfileService.instance.loadProfile();
    _nicknameController.text = profile.nickname;
    _heightController.text = profile.heightCm?.toString() ?? '';
    _weightController.text = profile.weightKg?.toString() ?? '';
    _photoUrlController.text = profile.photoUrl ?? '';
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _currentProfile = profile;
      _hasProfile =
          profile.nickname.trim().isNotEmpty ||
          profile.heightCm != null ||
          profile.weightKg != null ||
          (profile.photoUrl ?? '').trim().isNotEmpty;
      _isEditing = !_hasProfile;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final profile = UserProfile(
      nickname: _nicknameController.text.trim(),
      heightCm:
          _heightController.text.trim().isEmpty
              ? null
              : double.tryParse(_heightController.text.trim()),
      weightKg:
          _weightController.text.trim().isEmpty
              ? null
              : double.tryParse(_weightController.text.trim()),
      photoUrl:
          _photoUrlController.text.trim().isEmpty
              ? null
              : _photoUrlController.text.trim(),
    );

    await UserProfileService.instance.saveProfile(profile);

    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _currentProfile = profile;
      _hasProfile = true;
      _isEditing = false;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profile saved')));
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _photoUrlController.dispose();
    super.dispose();
  }

  Widget _buildGuestContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Login required', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        Text(
          'You are using the app in guest mode. Log in or create an account to set up your profile.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/login');
            },
            child: const Text('Login'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/register');
            },
            child: const Text('Create account'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B0E11), Color(0xFF111827)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _isGuest
                    ? _buildGuestContent(context)
                    : SingleChildScrollView(
                      child:
                          _isEditing || !_hasProfile
                              ? Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _hasProfile
                                          ? 'Edit your details'
                                          : 'Add your details',
                                      style:
                                          Theme.of(
                                            context,
                                          ).textTheme.titleLarge,
                                    ),
                                    const SizedBox(height: 24),
                                    TextFormField(
                                      controller: _nicknameController,
                                      decoration: const InputDecoration(
                                        labelText: 'Nickname',
                                      ),
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'Please enter a nickname';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: _heightController,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      decoration: const InputDecoration(
                                        labelText: 'Height (cm)',
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: _weightController,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      decoration: const InputDecoration(
                                        labelText: 'Weight (kg)',
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: _photoUrlController,
                                      decoration: const InputDecoration(
                                        labelText: 'Photo URL (optional)',
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed:
                                            _isSaving ? null : _saveProfile,
                                        child:
                                            _isSaving
                                                ? const SizedBox(
                                                  height: 20,
                                                  width: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                )
                                                : const Text('Save'),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Your details',
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 24),
                                  if (_currentProfile.nickname.isNotEmpty)
                                    Text(
                                      'Nickname: ${_currentProfile.nickname}',
                                      style:
                                          Theme.of(context).textTheme.bodyLarge,
                                    ),
                                  if (_currentProfile.heightCm != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        'Height: ${_currentProfile.heightCm!.toStringAsFixed(1)} cm',
                                        style:
                                            Theme.of(
                                              context,
                                            ).textTheme.bodyLarge,
                                      ),
                                    ),
                                  if (_currentProfile.weightKg != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        'Weight: ${_currentProfile.weightKg!.toStringAsFixed(1)} kg',
                                        style:
                                            Theme.of(
                                              context,
                                            ).textTheme.bodyLarge,
                                      ),
                                    ),
                                  if ((_currentProfile.photoUrl ?? '')
                                      .trim()
                                      .isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        'Photo URL: ${_currentProfile.photoUrl}',
                                        style:
                                            Theme.of(
                                              context,
                                            ).textTheme.bodyMedium,
                                      ),
                                    ),
                                  const SizedBox(height: 24),
                                  // Water Notifications Toggle
                                  Card(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Water Reminders',
                                                  style:
                                                      Theme.of(
                                                        context,
                                                      ).textTheme.bodyLarge,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  _waterNotificationsEnabled
                                                      ? 'You will receive water reminders daily'
                                                      : 'Reminders are disabled',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color: Colors.white70,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Switch(
                                            value: _waterNotificationsEnabled,
                                            onChanged:
                                                _toggleWaterNotifications,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        setState(() {
                                          _isEditing = true;
                                        });
                                      },
                                      child: const Text('Edit details'),
                                    ),
                                  ),
                                ],
                              ),
                    ),
          ),
        ),
      ),
    );
  }
}
