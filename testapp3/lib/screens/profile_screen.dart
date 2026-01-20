import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_profile.dart';
import '../services/user_profile_service.dart';
import '../services/notification_service.dart';

class ProfileScreen extends StatefulWidget {
  final bool showAppBar;
  const ProfileScreen({super.key, this.showAppBar = true});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _heightController = TextEditingController();
  String _heightUnit = 'cm'; // 'cm', 'm', 'in'
  final _weightController = TextEditingController();
  final _ageController = TextEditingController(); // New
  final _photoUrlController = TextEditingController();
  String? _selectedSex; // New

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

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Logout'),
              ),
            ],
          ),
    );

    if (shouldLogout == true && mounted) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        // Use pushReplacement or pushNamedAndRemoveUntil to clear stack
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  Future<void> _loadProfile() async {
    final profile = await UserProfileService.instance.loadProfile();
    _nicknameController.text = profile.nickname;

    // Set default unit and converted value
    if (profile.heightCm != null) {
      // Keep 'cm' as default load unit, but user can switch.
      // Or calculate distinct logic. For now default to 'cm'
      _heightController.text = profile.heightCm!.toStringAsFixed(1);
    } else {
      _heightController.text = '';
    }

    _weightController.text = profile.weightKg?.toString() ?? '';
    _ageController.text = profile.age?.toString() ?? '';
    _selectedSex = profile.sex;
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

    try {
      double? heightCm;
      if (_heightController.text.trim().isNotEmpty) {
        final val = double.tryParse(_heightController.text.trim());
        if (val != null) {
          heightCm = _convertHeightToCm(val, _heightUnit);
        }
      }

      final profile = UserProfile(
        nickname: _nicknameController.text.trim(),
        heightCm: heightCm,
        weightKg:
            _weightController.text.trim().isEmpty
                ? null
                : double.tryParse(_weightController.text.trim()),
        age:
            _ageController.text.trim().isEmpty
                ? null
                : int.tryParse(_ageController.text.trim()), // New
        sex: _selectedSex, // New
        photoUrl:
            _photoUrlController.text.trim().isEmpty
                ? null
                : _photoUrlController.text.trim(),
      );

      await UserProfileService.instance
          .saveProfile(profile)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw 'Connection timed out. Check your internet.';
            },
          );

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
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving profile: $e')));
      }
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _ageController.dispose(); // New
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
      appBar: widget.showAppBar ? AppBar(title: const Text('Account')) : null,
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
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            controller: _heightController,
                                            keyboardType:
                                                const TextInputType.numberWithOptions(
                                                  decimal: true,
                                                ),
                                            decoration: InputDecoration(
                                              labelText:
                                                  'Height ($_heightUnit)',
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        DropdownButton<String>(
                                          value: _heightUnit,
                                          items:
                                              ['cm', 'm', 'in']
                                                  .map(
                                                    (unit) => DropdownMenuItem(
                                                      value: unit,
                                                      child: Text(unit),
                                                    ),
                                                  )
                                                  .toList(),
                                          onChanged: (newUnit) {
                                            if (newUnit == null ||
                                                newUnit == _heightUnit)
                                              return;
                                            _changeHeightUnit(newUnit);
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: _ageController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: 'Age',
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    DropdownButtonFormField<String>(
                                      value: _selectedSex,
                                      items:
                                          ['Male', 'Female', 'Other']
                                              .map(
                                                (label) => DropdownMenuItem(
                                                  value: label,
                                                  child: Text(label),
                                                ),
                                              )
                                              .toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedSex = value;
                                        });
                                      },
                                      decoration: const InputDecoration(
                                        labelText: 'Sex',
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
                                  if (_currentProfile.age != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        'Age: ${_currentProfile.age}',
                                        style:
                                            Theme.of(
                                              context,
                                            ).textTheme.bodyLarge,
                                      ),
                                    ),
                                  if (_currentProfile.sex != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        'Sex: ${_currentProfile.sex}',
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
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: _handleLogout,
                                      icon: const Icon(
                                        Icons.logout,
                                        color: Colors.redAccent,
                                      ),
                                      label: const Text(
                                        'Logout',
                                        style: TextStyle(
                                          color: Colors.redAccent,
                                        ),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(
                                          color: Colors.redAccent,
                                        ),
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
  }

  void _changeHeightUnit(String newUnit) {
    if (_heightController.text.isEmpty) {
      setState(() => _heightUnit = newUnit);
      return;
    }

    double? currentVal = double.tryParse(_heightController.text);
    if (currentVal == null) {
      setState(() => _heightUnit = newUnit);
      return;
    }

    // Convert current value back to CM first
    double cmVal = _convertHeightToCm(currentVal, _heightUnit);

    // Convert CM to new unit
    double newVal = _convertCmToUnit(cmVal, newUnit);

    setState(() {
      _heightUnit = newUnit;
      _heightController.text = newVal.toStringAsFixed(2);
    });
  }

  double _convertHeightToCm(double val, String unit) {
    switch (unit) {
      case 'm':
        return val * 100;
      case 'in':
        return val * 2.54;
      default:
        return val;
    }
  }

  double _convertCmToUnit(double cm, String unit) {
    switch (unit) {
      case 'm':
        return cm / 100;
      case 'in':
        return cm / 2.54;
      default:
        return cm;
    }
  }
}
