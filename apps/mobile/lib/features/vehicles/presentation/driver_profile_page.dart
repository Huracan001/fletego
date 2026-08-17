import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/fletego_components.dart';
import '../application/driver_fleet_controller.dart';

class DriverProfilePage extends ConsumerStatefulWidget {
  const DriverProfilePage({super.key});

  @override
  ConsumerState<DriverProfilePage> createState() => _DriverProfilePageState();
}

class _DriverProfilePageState extends ConsumerState<DriverProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _license = TextEditingController();
  final _years = TextEditingController();
  bool _acceptsReturn = true;
  bool _loading = false;
  bool _initialized = false;

  @override
  void dispose() {
    _license.dispose();
    _years.dispose();
    super.dispose();
  }

  void _syncFromState() {
    if (_initialized) return;
    final profile = ref.read(driverFleetControllerProvider).driverProfile;
    if (profile == null) return;
    _license.text = profile.licenseNumber ?? '';
    _years.text = profile.yearsExperience?.toString() ?? '';
    _acceptsReturn = profile.acceptsReturnLoads;
    _initialized = true;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final ok = await ref
        .read(driverFleetControllerProvider.notifier)
        .saveDriverProfile(
          licenseNumber: _license.text.trim(),
          yearsExperience: int.tryParse(_years.text),
          acceptsReturnLoads: _acceptsReturn,
        );
    if (!mounted) return;
    setState(() => _loading = false);
    if (!ok) {
      final error = ref.read(driverFleetControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'No pudimos guardar el perfil.')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Perfil de conductor guardado.')),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(driverFleetControllerProvider);
    _syncFromState();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil de conductor'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(FletegoSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Licencia y experiencia',
                  style: FletegoTypography.textTheme.titleLarge,
                ),
                const SizedBox(height: FletegoSpacing.xs),
                Text(
                  'Estos datos ayudan a verificar tu cuenta. Los archivos se subirán en una fase posterior.',
                  style: FletegoTypography.textTheme.bodyMedium,
                ),
                const SizedBox(height: FletegoSpacing.lg),
                TextFormField(
                  controller: _license,
                  decoration: const InputDecoration(
                    labelText: 'Número de licencia *',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().length < 4) {
                      return 'Ingresa tu licencia';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: FletegoSpacing.md),
                TextFormField(
                  controller: _years,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Años de experiencia',
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Acepto cargas de retorno'),
                  subtitle: const Text(
                    'FLETEGO te mostrará fletes compatibles en el regreso.',
                  ),
                  value: _acceptsReturn,
                  onChanged: (v) => setState(() => _acceptsReturn = v),
                ),
                const SizedBox(height: FletegoSpacing.xl),
                FletegoButton(
                  label: 'Guardar',
                  isLoading: _loading,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
