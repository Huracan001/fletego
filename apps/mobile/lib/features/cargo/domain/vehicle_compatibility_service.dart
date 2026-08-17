import '../../vehicles/domain/vehicle_models.dart';
import '../../../shared/enums/cargo_enums.dart';

class TruckRecommendation {
  const TruckRecommendation({
    required this.vehicleType,
    required this.reason,
    this.score = 0,
  });

  final VehicleType vehicleType;
  final String reason;
  final int score;
}

/// Deterministic recommendation engine — AI can plug in later behind this API.
abstract final class VehicleCompatibilityService {
  const VehicleCompatibilityService._();

  static TruckRecommendation? recommend({
    required List<VehicleType> types,
    required CargoType cargoType,
    double? weightKg,
    double? lengthM,
    double? widthM,
    double? heightM,
    ContainerSize? containerSize,
    bool requiresRefrigeration = false,
    bool dangerousGoods = false,
    bool requiresTarp = false,
    bool oversized = false,
  }) {
    if (types.isEmpty) return null;

    VehicleType? pickByCode(String code) {
      for (final t in types) {
        if (t.code == code) return t;
      }
      return null;
    }

    // Hard rules first
    if (cargoType == CargoType.contenedor || containerSize != null) {
      final type = pickByCode('portacontenedor') ?? pickByCode('plataforma');
      if (type != null) {
        return TruckRecommendation(
          vehicleType: type,
          reason:
              'Ideal para contenedores (${containerSize?.labelEs ?? 'estándar'}).',
          score: 100,
        );
      }
    }

    if (cargoType == CargoType.liquidos) {
      final type = pickByCode('cisterna');
      if (type != null) {
        return TruckRecommendation(
          vehicleType: type,
          reason: 'Recomendado para líquidos a granel.',
          score: 100,
        );
      }
    }

    if (cargoType == CargoType.vehiculos) {
      final type = pickByCode('ciguena');
      if (type != null) {
        return TruckRecommendation(
          vehicleType: type,
          reason: 'Cigüeña adecuada para transporte de vehículos.',
          score: 100,
        );
      }
    }

    if (requiresRefrigeration || cargoType == CargoType.refrigerada) {
      final type = pickByCode('refrigerado');
      if (type != null) {
        return TruckRecommendation(
          vehicleType: type,
          reason: 'Necesitas cadena de frío.',
          score: 95,
        );
      }
    }

    if (oversized || cargoType == CargoType.maquinaria) {
      final type = pickByCode('cama_baja') ?? pickByCode('plataforma');
      if (type != null) {
        return TruckRecommendation(
          vehicleType: type,
          reason: 'Mejor para maquinaria o carga sobredimensionada.',
          score: 90,
        );
      }
    }

    // Weight / general cargo heuristics
    final weight = weightKg ?? 0;
    if (weight > 20000) {
      final type = pickByCode('semirremolque') ?? pickByCode('sider');
      if (type != null) {
        return TruckRecommendation(
          vehicleType: type,
          reason: 'Tu peso sugiere un semirremolque / sider de alta capacidad.',
          score: 85,
        );
      }
    }

    if (requiresTarp || cargoType == CargoType.cargaGeneral) {
      final type = pickByCode('sider') ?? pickByCode('furgon');
      if (type != null) {
        return TruckRecommendation(
          vehicleType: type,
          reason: dangerousGoods
              ? 'Sider compatible; verifica permisos de carga peligrosa.'
              : 'Sider versátil para carga general.',
          score: 80,
        );
      }
    }

    if (cargoType == CargoType.cargaPeligrosa) {
      final type = pickByCode('furgon') ?? pickByCode('sider');
      if (type != null) {
        return TruckRecommendation(
          vehicleType: type,
          reason: 'Unidad cerrada preferible; el transportista debe estar habilitado.',
          score: 75,
        );
      }
    }

    final fallback = pickByCode('camion_rigido') ?? types.first;
    return TruckRecommendation(
      vehicleType: fallback,
      reason:
          'Opción inicial según tu carga. Puedes cambiarla si lo prefieres.',
      score: 50,
    );
  }
}
