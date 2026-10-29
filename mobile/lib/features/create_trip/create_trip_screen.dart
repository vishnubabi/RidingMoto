import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme.dart';
import '../../core/api_service.dart';
import '../../core/storage_service.dart';
import '../../core/routes.dart';
import '../../shared/models/trip_member.dart';
import '../../shared/widgets/color_picker_row.dart';
import '../../shared/widgets/loading_overlay.dart';

class CreateTripScreen extends StatefulWidget {
  const CreateTripScreen({super.key});

  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _selectedColor = '#4F6FFF';
  bool _isLoading = false;
  String? _createdCode;
  TripMember? _member;

  @override
  void initState() {
    super.initState();
    _nameController.text = StorageService.getDisplayName() ?? '';
    _selectedColor = StorageService.getColor() ?? '#4F6FFF';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createTrip() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final result = await ApiService.createTrip(
        displayName: _nameController.text.trim(),
        avatar: 'person',
        color: _selectedColor,
      );

      final code = result['trip_code'] as String;
      final member = TripMember.fromJson(result['member'] as Map<String, dynamic>);

      await StorageService.setMemberId(member.memberId);
      await StorageService.setDisplayName(_nameController.text.trim());
      await StorageService.setColor(_selectedColor);
      await StorageService.setLastTripCode(code);

      setState(() {
        _createdCode = code;
        _member = member;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  void _startRiding() {
    if (_createdCode == null || _member == null) return;
    Navigator.pushReplacementNamed(
      context,
      AppRoutes.liveMap,
      arguments: LiveMapArgs(tripCode: _createdCode!, member: _member!),
    );
  }

  void _shareCode() {
    if (_createdCode == null) return;
    Share.share('Join my RidingMoto trip! Code: $_createdCode\nEnter this code in the app to track each other.');
  }

  void _copyCode() {
    if (_createdCode == null) return;
    Clipboard.setData(ClipboardData(text: _createdCode!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Code copied!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text('New Trip'),
          leading: const BackButton(),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _createdCode == null ? _buildForm() : _buildSuccessCard(),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
              hintText: 'e.g. Alex',
              prefixIcon: Icon(Icons.person_outline, color: AppTheme.textSecondary),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Please enter your name';
              if (v.trim().length > 50) return 'Max 50 characters';
              return null;
            },
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 24),

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
            onPressed: _createTrip,
            child: const Text('Create Trip'),
          ).animate(delay: 300.ms).fadeIn(),
        ],
      ),
    );
  }

  Widget _buildSuccessCard() {
    return Column(
      children: [
        const SizedBox(height: 16),

        // Tick icon
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppTheme.success.withAlpha(25),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle_outline, color: AppTheme.success, size: 40),
        ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),

        const SizedBox(height: 16),
        const Text(
          'Trip created!',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ).animate().fadeIn(),

        const SizedBox(height: 6),
        const Text(
          'Share this code with your crew',
          style: TextStyle(color: AppTheme.textSecondary),
        ).animate(delay: 100.ms).fadeIn(),

        const SizedBox(height: 32),

        // Code card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            children: [
              Text(
                _createdCode!,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 44,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.accent,
                  letterSpacing: 6,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _copyCode,
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('Copy'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _shareCode,
                      icon: const Icon(Icons.share, size: 18),
                      label: const Text('Share'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ).animate(delay: 200.ms).fadeIn().scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1)),

        const SizedBox(height: 32),

        ElevatedButton(
          onPressed: _startRiding,
          child: const Text('Start Trip →'),
        ).animate(delay: 300.ms).fadeIn(),
      ],
    );
  }
}
