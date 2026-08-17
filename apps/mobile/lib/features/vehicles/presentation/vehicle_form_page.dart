import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/fletego_components.dart';
import '../../company/application/company_dashboard_controller.dart';
import '../application/driver_fleet_controller.dart';
import '../domain/vehicle_models.dart';

class VehicleFormPage extends ConsumerStatefulWidget {
  const VehicleFormPage({super.key, this.companyId});

  /// When set, registers the vehicle on the company fleet (not personal).
  final String? companyId;

  @override
  ConsumerState<VehicleFormPage> createState() => _VehicleFormPageState();
}

class _VehicleFormPageState extends ConsumerState<VehicleFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _plate = TextEditingController();
  final _brand = TextEditingController();
  final _model = TextEditingController();
  final _year = TextEditingController();
  final _capacity = TextEditingController();
  String? _typeId;
  bool _hasRefrigeration = false;
  bool _hasTarp = false;
  bool _acceptsDg = false;
  bool _loading = false;
  List<VehicleType> _types = const [];

  bool get _isCompanyFleet =>
      widget.companyId != null && widget.companyId!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadTypes);
  }

  Future<void> _loadTypes() async {
    if (!_isCompanyFleet) return;
    final repo = ref.read(vehicleRepositoryProvider);
    if (repo == null) return;
    try {
      final types = await repo.listVehicleTypes();
      if (!mounted) return;
      setState(() => _types = types);
    } catch (_) {}
  }

  @override
  void dispose() {
    _plate.dispose();
    _brand.dispose();
    _model.dispose();
    _year.dispose();
    _capacity.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_typeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona el tipo de vehículo.')),
      );
      return;
    }

    setState(() => _loading = true);

    Vehicle? vehicle;
    String? error;

    if (_isCompanyFleet) {
      vehicle = await ref
          .read(companyDashboardControllerProvider.notifier)
          .addCompanyVehicle(
            companyId: widget.companyId!,
            vehicleTypeId: _typeId!,
            plate: _plate.text,
            brand: _brand.text,
            model: _model.text,
            year: int.tryParse(_year.text),
            capacityKg: double.tryParse(_capacity.text.replaceAll(',', '.')),
            maxCargoKg: double.tryParse(_capacity.text.replaceAll(',', '.')),
            hasRefrigeration: _hasRefrigeration,
            hasTarp: _hasTarp,
            acceptsDangerousGoods: _acceptsDg,
          );
      error = ref.read(companyDashboardControllerProvider).error;
    } else {
      vehicle = await ref
          .read(driverFleetControllerProvider.notifier)
          .addVehicle(
            vehicleTypeId: _typeId!,
            plate: _plate.text,
            brand: _brand.text,
            model: _model.text,
            year: int.tryParse(_year.text),
            capacityKg: double.tryParse(_capacity.text.replaceAll(',', '.')),
            maxCargoKg: double.tryParse(_capacity.text.replaceAll(',', '.')),
            hasRefrigeration: _hasRefrigeration,
            hasTarp: _hasTarp,
            acceptsDangerousGoods: _acceptsDg,
          );
      error = ref.read(driverFleetControllerProvider).error;
    }

    if (!mounted) return;
    setState(() => _loading = false);

    if (vehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'No pudimos registrar el vehículo.')),
      );
      return;
    }

    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final personalTypes = ref.watch(driverFleetControllerProvider).types;
    final types = _isCompanyFleet ? _types : personalTypes;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isCompanyFleet ? 'Vehículo de empresa' : 'Registrar vehículo',
        ),
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
                  'Datos del camión',
                  style: FletegoTypography.textTheme.titleLarge,
                ),
                const SizedBox(height: FletegoSpacing.lg),
                DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: _typeId,
                  decoration: const InputDecoration(labelText: 'Tipo *'),
                  items: types
                      .map(
                        (VehicleType t) => DropdownMenuItem(
                          value: t.id,
                          child: Text(t.nameEs),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _typeId = v),
                ),
                const SizedBox(height: FletegoSpacing.md),
                TextFormField(
                  controller: _plate,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(labelText: 'Placa *'),
                  validator: (v) {
                    if (v == null || v.trim().length < 4) {
                      return 'Ingresa la placa';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: FletegoSpacing.md),
                TextFormField(
                  controller: _brand,
                  decoration: const InputDecoration(labelText: 'Marca'),
                ),
                const SizedBox(height: FletegoSpacing.md),
                TextFormField(
                  controller: _model,
                  decoration: const InputDecoration(labelText: 'Modelo'),
                ),
                const SizedBox(height: FletegoSpacing.md),
                TextFormField(
                  controller: _year,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Año'),
                ),
                const SizedBox(height: FletegoSpacing.md),
                TextFormField(
                  controller: _capacity,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Capacidad de carga (kg)',
                  ),
                ),
                const SizedBox(height: FletegoSpacing.md),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Refrigerado'),
                  value: _hasRefrigeration,
                  onChanged: (v) => setState(() => _hasRefrigeration = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Carpa / lona'),
                  value: _hasTarp,
                  onChanged: (v) => setState(() => _hasTarp = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Acepta carga peligrosa'),
                  value: _acceptsDg,
                  onChanged: (v) => setState(() => _acceptsDg = v),
                ),
                const SizedBox(height: FletegoSpacing.xl),
                FletegoButton(
                  label: 'Guardar vehículo',
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
