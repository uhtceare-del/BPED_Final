import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../widgets/dashboard_module.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String? selectedYear;
  String? selectedSection;
  bool _isSaving = false;

  final Map<String, List<String>> yearToSections = {
    '1': ['PE-11', 'PE-12', 'PE-13', 'PE-14'],
    '2': ['PE-21', 'PE-22', 'PE-23', 'PE-24'],
    '3': ['PE-31', 'PE-32', 'PE-33', 'PE-34'],
    '4': ['PE-41', 'PE-42', 'PE-43', 'PE-44'],
  };

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: DashboardModulePage(
              title: 'Profile Setup',
              subtitle:
                  'Complete your student profile before entering the BPED portal.',
              child: ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  DashboardSectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Column(
                            children: [
                              Image.asset(
                                'assets/lnu.png',
                                height: 80,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(
                                      Icons.school,
                                      size: 80,
                                      color: kNavy,
                                    ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Welcome to LNU PE Portal',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: kNavy,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Complete your profile to get started.',
                                style: TextStyle(
                                  color: kNavy.withValues(alpha: 0.62),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        TextFormField(
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Enter your full name'
                              : null,
                        ),
                        const SizedBox(height: 24),
                        DropdownButtonFormField<String>(
                          initialValue: selectedYear,
                          decoration: const InputDecoration(
                            labelText: 'Year Level',
                            prefixIcon: Icon(Icons.trending_up),
                          ),
                          items: yearToSections.keys
                              .map(
                                (year) => DropdownMenuItem(
                                  value: year,
                                  child: Text('Year $year'),
                                ),
                              )
                              .toList(),
                          onChanged: _isSaving
                              ? null
                              : (val) {
                                  setState(() {
                                    selectedYear = val;
                                    selectedSection = null;
                                  });
                                },
                          validator: (val) =>
                              val == null ? 'Select year level' : null,
                        ),
                        const SizedBox(height: 24),
                        DropdownButtonFormField<String>(
                          initialValue: selectedSection,
                          disabledHint: const Text('Select Year Level first'),
                          decoration: const InputDecoration(
                            labelText: 'Section',
                            prefixIcon: Icon(Icons.class_outlined),
                          ),
                          items: selectedYear == null
                              ? []
                              : yearToSections[selectedYear]!
                                    .map(
                                      (sec) => DropdownMenuItem(
                                        value: sec,
                                        child: Text(sec),
                                      ),
                                    )
                                    .toList(),
                          onChanged: _isSaving
                              ? null
                              : (val) => setState(() => selectedSection = val),
                          validator: (val) =>
                              val == null ? 'Select section' : null,
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.blue.withValues(alpha: 0.2),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline, size: 18, color: kNavy),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'After setting up your profile, go to the Classes tab and enter the code your instructor gave you to join a class.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: kNavy,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      backgroundColor: kNavy,
                    ),
                    onPressed: _isSaving ? null : _saveProfile,
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'COMPLETE SETUP',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
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

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final user = ref.read(authControllerProvider).currentUser;
      if (user == null) return;

      await ref
          .read(authRepositoryProvider)
          .completeOnboarding(
            uid: user.uid,
            fullName: _nameController.text.trim(),
            role: 'student',
            yearLevel: selectedYear!,
            section: selectedSection!,
          );

      if (mounted) {
        setState(() => _isSaving = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
