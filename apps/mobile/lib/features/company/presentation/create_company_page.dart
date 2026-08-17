import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/fletego_brand_mark.dart';
import '../../../core/widgets/fletego_components.dart';
import '../../../shared/enums/company_enums.dart';
import '../application/company_controller.dart';

class CreateCompanyPage extends ConsumerStatefulWidget {
  const CreateCompanyPage({super.key});

  @override
  ConsumerState<CreateCompanyPage> createState() => _CreateCompanyPageState();
}

class _CreateCompanyPageState extends ConsumerState<CreateCompanyPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _legalName = TextEditingController();
  final _nit = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  CompanyType _type = CompanyType.both;
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _legalName.dispose();
    _nit.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final company = await ref
        .read(companyListControllerProvider.notifier)
        .createCompany(
          name: _name.text,
          companyType: _type,
          legalName: _legalName.text,
          nit: _nit.text,
          phone: _phone.text,
          email: _email.text,
        );

    if (!mounted) return;
    setState(() => _loading = false);

    if (company == null) {
      final error = ref.read(companyListControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'No pudimos crear la empresa.')),
      );
      return;
    }

    ref.read(selectedCompanyIdProvider.notifier).select(company.id);
    context.go(AppRoutes.companyDashboard, extra: company.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Crear empresa'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(FletegoSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FletegoBrandMark(compact: true),
                const SizedBox(height: FletegoSpacing.lg),
                Text(
                  'Datos de la empresa',
                  style: FletegoTypography.textTheme.titleLarge,
                ),
                const SizedBox(height: FletegoSpacing.xs),
                Text(
                  'Podrás agregar vehículos, conductores y operadores después.',
                  style: FletegoTypography.textTheme.bodyMedium,
                ),
                const SizedBox(height: FletegoSpacing.lg),
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nombre comercial *',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().length < 2) {
                      return 'Ingresa el nombre de la empresa';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: FletegoSpacing.md),
                TextFormField(
                  controller: _legalName,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Razón social'),
                ),
                const SizedBox(height: FletegoSpacing.md),
                TextFormField(
                  controller: _nit,
                  decoration: const InputDecoration(labelText: 'NIT'),
                ),
                const SizedBox(height: FletegoSpacing.md),
                DropdownButtonFormField<CompanyType>(
                  // ignore: deprecated_member_use
                  value: _type,
                  decoration: const InputDecoration(labelText: 'Tipo'),
                  items: CompanyType.values
                      .map(
                        (t) =>
                            DropdownMenuItem(value: t, child: Text(t.labelEs)),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _type = v);
                  },
                ),
                const SizedBox(height: FletegoSpacing.md),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Teléfono'),
                ),
                const SizedBox(height: FletegoSpacing.md),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo de la empresa',
                  ),
                ),
                const SizedBox(height: FletegoSpacing.xl),
                FletegoButton(
                  label: 'Crear empresa',
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
