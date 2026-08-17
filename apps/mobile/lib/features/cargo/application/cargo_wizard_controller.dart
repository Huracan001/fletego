import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/network/supabase_client.dart';
import '../../../shared/enums/cargo_enums.dart';
import '../../auth/application/auth_controller.dart';
import '../../vehicles/domain/vehicle_models.dart';
import '../data/cargo_repository.dart';
import '../domain/cargo_models.dart';
import '../domain/vehicle_compatibility_service.dart';

final cargoRepositoryProvider = Provider<CargoRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  return CargoRepository(client);
});

class CargoWizardState {
  const CargoWizardState({
    this.step = 0,
    this.draft = const CargoRequestDraft(),
    this.vehicleTypes = const [],
    this.recommendation,
    this.isSubmitting = false,
    this.error,
    this.submittedId,
  });

  static const totalSteps = 8;

  final int step;
  final CargoRequestDraft draft;
  final List<VehicleType> vehicleTypes;
  final TruckRecommendation? recommendation;
  final bool isSubmitting;
  final String? error;
  final String? submittedId;

  double get progress => (step + 1) / totalSteps;

  CargoWizardState copyWith({
    int? step,
    CargoRequestDraft? draft,
    List<VehicleType>? vehicleTypes,
    TruckRecommendation? recommendation,
    bool? isSubmitting,
    String? error,
    String? submittedId,
    bool clearError = false,
    bool clearRecommendation = false,
    bool clearSubmitted = false,
  }) {
    return CargoWizardState(
      step: step ?? this.step,
      draft: draft ?? this.draft,
      vehicleTypes: vehicleTypes ?? this.vehicleTypes,
      recommendation: clearRecommendation
          ? null
          : (recommendation ?? this.recommendation),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
      submittedId: clearSubmitted ? null : (submittedId ?? this.submittedId),
    );
  }
}

class CargoWizardController extends Notifier<CargoWizardState> {
  @override
  CargoWizardState build() {
    Future.microtask(_loadTypes);
    return const CargoWizardState();
  }

  CargoRepository? get _repo => ref.read(cargoRepositoryProvider);

  Future<void> _loadTypes() async {
    final repo = _repo;
    if (repo == null) return;
    try {
      final types = await repo.listVehicleTypes();
      state = state.copyWith(vehicleTypes: types);
      _refreshRecommendation();
    } catch (_) {
      // Types may be empty until Phase 4 migration; wizard still works.
    }
  }

  void reset() {
    state = CargoWizardState(vehicleTypes: state.vehicleTypes);
  }

  void next() {
    if (state.step < CargoWizardState.totalSteps - 1) {
      state = state.copyWith(step: state.step + 1, clearError: true);
      if (state.step == 4) _refreshRecommendation();
    }
  }

  void back() {
    if (state.step > 0) {
      state = state.copyWith(step: state.step - 1, clearError: true);
    }
  }

  void goTo(int step) {
    state = state.copyWith(
      step: step.clamp(0, CargoWizardState.totalSteps - 1),
    );
  }

  void updateDraft(CargoRequestDraft draft) {
    state = state.copyWith(draft: draft, clearError: true);
    _refreshRecommendation();
  }

  void _refreshRecommendation() {
    final draft = state.draft;
    if (draft.cargoType == null || state.vehicleTypes.isEmpty) return;

    final rec = VehicleCompatibilityService.recommend(
      types: state.vehicleTypes,
      cargoType: draft.cargoType!,
      weightKg: draft.totalWeightKg ?? draft.container?.grossWeightKg,
      lengthM: draft.lengthM,
      widthM: draft.widthM,
      heightM: draft.heightM,
      containerSize: draft.container?.containerType,
      requiresRefrigeration:
          draft.requiresRefrigeration ||
          draft.specialRequirements.contains(SpecialRequirement.refrigerated) ||
          (draft.container?.refrigerated ?? false),
      dangerousGoods:
          draft.dangerousGoods ||
          draft.specialRequirements.contains(SpecialRequirement.dangerousGoods),
      requiresTarp:
          draft.requiresTarp ||
          draft.specialRequirements.contains(SpecialRequirement.tarp),
      oversized: draft.specialRequirements.contains(
        SpecialRequirement.oversized,
      ),
    );

    if (rec == null) return;

    var nextDraft = draft.copyWith(
      recommendedVehicleTypeId: rec.vehicleType.id,
    );
    if (draft.unknownTruck || draft.requestedVehicleTypeId == null) {
      nextDraft = nextDraft.copyWith(
        requestedVehicleTypeId: rec.vehicleType.id,
        unknownTruck: draft.unknownTruck,
      );
    }
    state = state.copyWith(draft: nextDraft, recommendation: rec);
  }

  String? validateCurrentStep() {
    final d = state.draft;
    switch (state.step) {
      case 0:
        if (d.cargoType == null) return 'Selecciona el tipo de carga.';
      case 1:
        if (!d.origin.isValid) return 'Indica la ciudad de origen.';
      case 2:
        if (!d.destination.isValid) return 'Indica la ciudad de destino.';
      case 3:
        if (d.cargoType == CargoType.contenedor) {
          if (d.container?.grossWeightKg == null && d.totalWeightKg == null) {
            return 'Indica el peso del contenedor.';
          }
        } else if (d.totalWeightKg == null || d.totalWeightKg! <= 0) {
          return 'Indica el peso de la carga.';
        }
      case 4:
        if (!d.unknownTruck && d.requestedVehicleTypeId == null) {
          return 'Elige un tipo de camión o “No sé qué camión necesito”.';
        }
      case 5:
        if (d.scheduleMode == ScheduleMode.scheduled && d.pickupAt == null) {
          return 'Elige fecha y hora de recogida.';
        }
      default:
        break;
    }
    return null;
  }

  bool continueNext() {
    final error = validateCurrentStep();
    if (error != null) {
      state = state.copyWith(error: error);
      return false;
    }
    next();
    return true;
  }

  Future<bool> submit() async {
    final auth = ref.read(authControllerProvider);
    if (auth.status != AuthStatus.authenticated) {
      state = state.copyWith(error: 'Debes iniciar sesión.');
      return false;
    }

    final error = validateCurrentStep();
    if (error != null) {
      state = state.copyWith(error: error);
      return false;
    }

    final repo = _repo;
    if (repo == null) {
      state = state.copyWith(error: 'Supabase no está configurado.');
      return false;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final summary = await repo.submit(state.draft);
      state = state.copyWith(isSubmitting: false, submittedId: summary.id);
      return true;
    } on AppFailure catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isSubmitting: false,
        error: 'No pudimos enviar la solicitud.',
      );
      return false;
    }
  }
}

final cargoWizardControllerProvider =
    NotifierProvider<CargoWizardController, CargoWizardState>(
      CargoWizardController.new,
    );

class MyRequestsState {
  const MyRequestsState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  final List<CargoRequestSummary> items;
  final bool isLoading;
  final String? error;
}

class MyRequestsController extends Notifier<MyRequestsState> {
  @override
  MyRequestsState build() {
    ref.listen<AuthSessionState>(authControllerProvider, (prev, next) {
      if (next.status == AuthStatus.authenticated) {
        refresh();
      } else {
        state = const MyRequestsState();
      }
    });
    Future.microtask(refresh);
    return const MyRequestsState(isLoading: true);
  }

  Future<void> refresh() async {
    final repo = ref.read(cargoRepositoryProvider);
    final auth = ref.read(authControllerProvider);
    if (repo == null || auth.status != AuthStatus.authenticated) {
      state = const MyRequestsState();
      return;
    }
    state = const MyRequestsState(isLoading: true);
    try {
      final items = await repo.listMyRequests();
      state = MyRequestsState(items: items);
    } on AppFailure catch (e) {
      state = MyRequestsState(error: e.message);
    } catch (_) {
      state = const MyRequestsState(
        error: 'No pudimos cargar tus solicitudes.',
      );
    }
  }
}

final myRequestsControllerProvider =
    NotifierProvider<MyRequestsController, MyRequestsState>(
      MyRequestsController.new,
    );
