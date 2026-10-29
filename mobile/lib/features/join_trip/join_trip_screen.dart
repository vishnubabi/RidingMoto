import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme.dart';
import '../../core/api_service.dart';
import '../../core/storage_service.dart';
import '../../core/routes.dart';
import '../../shared/models/trip_member.dart';
import '../../shared/widgets/color_picker_row.dart';
import '../../shared/widgets/loading_overlay.dart';

class JoinTripScreen extends StatefulWidget {
  final String? initialCode;
  const JoinTripScreen({super.key, this.initialCode});

  @override
  State<JoinTripScreen> createState() => _JoinTripScreenState();
}

class _JoinTripScreenState extends State<JoinTripScreen> {
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _selectedColor = '#00C07F';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _codeController.text = widget.initialCode ?? '';
    _nameController.text = StorageService.getDisplayName() ?? '';
    _selectedColor = StorageService.getColor() ?? '#00C07F';
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _joinTrip() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final savedMemberId = StorageService.getMemberId();
      final code = _codeController.text.trim().toUpperCase();

      final result = await ApiService.joinTrip(
        code: code,
        displayName: _nameController.text.trim(),
        avatar: 'person',
        color: _selectedColor,
        memberId: savedMemberId,
      );

      final member = TripMember.fromJson(result['member'] as Map<String, dynamic>);

      await StorageService.setMemberId(member.memberId);
      await StorageService.setDisplayName(_nameController.text.trim());
      await StorageService.setColor(_selectedColor);
      await StorageService.setLastTripCode(code);

      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.liveMap,
          arguments: LiveMapArgs(tripCode: code, member: member),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text('Join Trip'),
          leading: const BackButton(),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // Trip code
                  const Text(
                    'Trip code',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _codeController,
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 6,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: AppTheme.accent,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 6,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'ABC123',
                      counterText: '',
                      prefixIcon: Icon(Icons.tag, color: AppTheme.textSecondary),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().length != 6) return 'Enter the 6-character trip code';
                      return null;
                    },
                  ).animate().fadeIn(duration: 400.ms),
                  const SizedBox(height: 24),

                  // Name
                  const Text(
                    'Your name',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'e.g. Sara',
                      prefixIcon: Icon(Icons.person_outline, color: AppTheme.textSecondary),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Please enter your name';
                      return null;
                    },
                  ).animate(delay: 100.ms).fadeIn(),
                  const SizedBox(height: 24),

                  // Color
                  const Text(
                    'Pick your color on the map',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ColorPickerRow(
                    selected: _selectedColor,
                    onChanged: (v) => setState(() => _selectedColor = v),
                  ).animate(delay: 200.ms).fadeIn(),
                  const SizedBox(height: 40),

                  ElevatedButton(
                    onPressed: _joinTrip,
                    child: const Text('Join Trip'),
                  ).animate(delay: 300.ms).fadeIn(),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
