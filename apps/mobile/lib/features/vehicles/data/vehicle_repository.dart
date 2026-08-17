import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_failure.dart';
import '../../../shared/enums/company_enums.dart';
import '../../../shared/enums/vehicle_enums.dart';
import '../domain/vehicle_models.dart';

class VehicleRepository {
  VehicleRepository(this._client);

  final SupabaseClient _client;

  Future<List<VehicleType>> listVehicleTypes() async {
    try {
      final rows = await _client
          .from('vehicle_types')
          .select()
          .eq('is_active', true)
          .order('name_es');
      return (rows as List)
          .map((r) => VehicleType.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList();
    } on PostgrestException catch (e) {
      throw NetworkFailure('No pudimos cargar los tipos de vehículo.', e);
    } catch (e) {
      throw UnexpectedFailure.fromCause(e);
    }
  }

  Future<DriverProfile> ensureDriverProfile() async {
    try {
      final row = await _client.rpc('ensure_driver_profile');
      if (row is Map) {
        return DriverProfile.fromJson(Map<String, dynamic>.from(row));
      }
      throw const UnexpectedFailure(
        'No pudimos preparar el perfil de conductor.',
      );
    } on PostgrestException catch (e) {
      throw NetworkFailure('No pudimos preparar el perfil de conductor.', e);
    } catch (e) {
      if (e is AppFailure) rethrow;
      throw UnexpectedFailure.fromCause(e);
    }
  }

  Future<DriverProfile> updateDriverProfile({
    required String driverProfileId,
    String? licenseNumber,
    DateTime? licenseExpiry,
    int? yearsExperience,
    bool? acceptsReturnLoads,
  }) async {
    try {
      final row = await _client
          .from('driver_profiles')
          .update({
            'license_number': ?licenseNumber,
            if (licenseExpiry != null)
              'license_expiry': licenseExpiry
                  .toIso8601String()
                  .split('T')
                  .first,
            'years_experience': ?yearsExperience,
            'accepts_return_loads': ?acceptsReturnLoads,
          })
          .eq('id', driverProfileId)
          .select()
          .single();
      return DriverProfile.fromJson(Map<String, dynamic>.from(row));
    } on PostgrestException catch (e) {
      throw NetworkFailure('No pudimos actualizar tu perfil de conductor.', e);
    } catch (e) {
      throw UnexpectedFailure.fromCause(e);
    }
  }

  Future<List<Vehicle>> listMyVehicles() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw const AuthFailure('Debes iniciar sesión.');

    try {
      final rows = await _client
          .from('vehicles')
          .select('*, vehicle_types(*)')
          .eq('owner_profile_id', uid)
          .filter('deleted_at', 'is', null)
          .order('created_at', ascending: false);

      return (rows as List)
          .map((r) => Vehicle.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList();
    } on PostgrestException catch (e) {
      throw NetworkFailure('No pudimos cargar tus vehículos.', e);
    } catch (e) {
      throw UnexpectedFailure.fromCause(e);
    }
  }

  Future<List<Vehicle>> listCompanyVehicles(String companyId) async {
    try {
      try {
        final rows = await _client
            .from('vehicles')
            .select('*, vehicle_types(*)')
            .eq('company_id', companyId)
            .filter('deleted_at', 'is', null)
            .order('created_at', ascending: false);

        return (rows as List)
            .map((r) => Vehicle.fromJson(Map<String, dynamic>.from(r as Map)))
            .toList();
      } on PostgrestException {
        final rows = await _client
            .from('vehicles')
            .select('*')
            .eq('company_id', companyId)
            .filter('deleted_at', 'is', null)
            .order('created_at', ascending: false);

        return (rows as List)
            .map((r) => Vehicle.fromJson(Map<String, dynamic>.from(r as Map)))
            .toList();
      }
    } on PostgrestException catch (e) {
      throw NetworkFailure(
        'No pudimos cargar la flota.${e.message.isNotEmpty ? ' (${e.message})' : ''}',
        e,
      );
    } catch (e) {
      if (e is AppFailure) rethrow;
      throw UnexpectedFailure.fromCause(e);
    }
  }

  Future<Vehicle> createVehicle({
    required String vehicleTypeId,
    required String plate,
    String? companyId,
    String? brand,
    String? model,
    int? year,
    double? capacityKg,
    double? maxCargoKg,
    double? lengthM,
    double? widthM,
    double? heightM,
    bool hasRefrigeration = false,
    bool hasTarp = false,
    bool acceptsDangerousGoods = false,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw const AuthFailure('Debes iniciar sesión.');

    try {
      final row = await _client
          .from('vehicles')
          .insert({
            'vehicle_type_id': vehicleTypeId,
            'plate': plate.trim().toUpperCase(),
            'country_code': 'BO',
            if (companyId == null) 'owner_profile_id': uid,
            'company_id': ?companyId,
            'brand': ?brand,
            'model': ?model,
            'year': ?year,
            'capacity_kg': ?capacityKg,
            'max_cargo_kg': ?maxCargoKg,
            'length_m': ?lengthM,
            'width_m': ?widthM,
            'height_m': ?heightM,
            'has_refrigeration': hasRefrigeration,
            'has_tarp': hasTarp,
            'accepts_dangerous_goods': acceptsDangerousGoods,
          })
          .select('*, vehicle_types(*)')
          .single();

      return Vehicle.fromJson(Map<String, dynamic>.from(row));
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw const ValidationFailure('Ya existe un vehículo con esa placa.');
      }
      throw NetworkFailure('No pudimos registrar el vehículo.', e);
    } catch (e) {
      if (e is AppFailure) rethrow;
      throw UnexpectedFailure.fromCause(e);
    }
  }

  Future<Vehicle> updateVehicleAvailability({
    required String vehicleId,
    required AvailabilityStatus status,
  }) async {
    try {
      final row = await _client
          .from('vehicles')
          .update({'availability_status': status.dbValue})
          .eq('id', vehicleId)
          .select('*, vehicle_types(*)')
          .single();
      return Vehicle.fromJson(Map<String, dynamic>.from(row));
    } on PostgrestException catch (e) {
      throw NetworkFailure('No pudimos actualizar la disponibilidad.', e);
    } catch (e) {
      throw UnexpectedFailure.fromCause(e);
    }
  }

  Future<void> softDeleteVehicle(String vehicleId) async {
    try {
      await _client
          .from('vehicles')
          .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', vehicleId);
    } on PostgrestException catch (e) {
      throw NetworkFailure('No pudimos eliminar el vehículo.', e);
    } catch (e) {
      throw UnexpectedFailure.fromCause(e);
    }
  }

  Future<void> linkDriverToVehicle({
    required String driverProfileId,
    required String vehicleId,
    bool isPrimary = true,
  }) async {
    try {
      await _client.from('driver_vehicles').upsert({
        'driver_profile_id': driverProfileId,
        'vehicle_id': vehicleId,
        'is_primary': isPrimary,
        'deleted_at': null,
      }, onConflict: 'driver_profile_id, vehicle_id');
    } on PostgrestException catch (e) {
      throw NetworkFailure('No pudimos vincular el vehículo.', e);
    } catch (e) {
      throw UnexpectedFailure.fromCause(e);
    }
  }

  Future<DriverAvailability> publishAvailability({
    required String driverProfileId,
    required String vehicleId,
    required AvailabilityStatus status,
    DateTime? availableFrom,
    DateTime? availableUntil,
    bool acceptsReturnCargo = true,
    double? maxDeadheadKm,
  }) async {
    try {
      await updateVehicleAvailability(vehicleId: vehicleId, status: status);

      final row = await _client
          .from('availability')
          .insert({
            'driver_profile_id': driverProfileId,
            'vehicle_id': vehicleId,
            'status': status.dbValue,
            'available_from': availableFrom?.toUtc().toIso8601String(),
            'available_until': availableUntil?.toUtc().toIso8601String(),
            'accepts_return_cargo': acceptsReturnCargo,
            'max_deadhead_km': maxDeadheadKm,
          })
          .select('*, vehicles(*, vehicle_types(*))')
          .single();

      return DriverAvailability.fromJson(Map<String, dynamic>.from(row));
    } on PostgrestException catch (e) {
      throw NetworkFailure('No pudimos publicar tu disponibilidad.', e);
    } catch (e) {
      if (e is AppFailure) rethrow;
      throw UnexpectedFailure.fromCause(e);
    }
  }

  Future<void> goOffline({
    required String driverProfileId,
    required String vehicleId,
  }) async {
    try {
      await updateVehicleAvailability(
        vehicleId: vehicleId,
        status: AvailabilityStatus.offline,
      );
      await _client
          .from('availability')
          .update({
            'status': AvailabilityStatus.offline.dbValue,
            'deleted_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('driver_profile_id', driverProfileId)
          .eq('vehicle_id', vehicleId)
          .eq('status', AvailabilityStatus.available.dbValue);
    } on PostgrestException catch (e) {
      throw NetworkFailure('No pudimos actualizar tu estado.', e);
    } catch (e) {
      if (e is AppFailure) rethrow;
      throw UnexpectedFailure.fromCause(e);
    }
  }

  Future<DriverAvailability?> latestAvailability(String driverProfileId) async {
    try {
      final row = await _client
          .from('availability')
          .select('*, vehicles(*, vehicle_types(*))')
          .eq('driver_profile_id', driverProfileId)
          .filter('deleted_at', 'is', null)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (row == null) return null;
      return DriverAvailability.fromJson(Map<String, dynamic>.from(row));
    } on PostgrestException catch (e) {
      throw NetworkFailure('No pudimos cargar tu disponibilidad.', e);
    } catch (e) {
      throw UnexpectedFailure.fromCause(e);
    }
  }

  Future<void> addDriverDocumentMeta({
    required String driverProfileId,
    required DocumentKind kind,
    DateTime? issueDate,
    DateTime? expiryDate,
  }) async {
    try {
      await _client.from('driver_documents').insert({
        'driver_profile_id': driverProfileId,
        'kind': kind.dbValue,
        'issue_date': issueDate?.toIso8601String().split('T').first,
        'expiry_date': expiryDate?.toIso8601String().split('T').first,
        'verification_status': VerificationStatus.pending.dbValue,
      });
    } on PostgrestException catch (e) {
      throw NetworkFailure('No pudimos registrar el documento.', e);
    } catch (e) {
      throw UnexpectedFailure.fromCause(e);
    }
  }
}
