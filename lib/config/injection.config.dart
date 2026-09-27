// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:cloud_firestore/cloud_firestore.dart' as _i974;
import 'package:firebase_auth/firebase_auth.dart' as _i59;
import 'package:firebase_storage/firebase_storage.dart' as _i457;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

import '../core/firebase/firebase_module.dart' as _i1053;
import '../core/firebase/firebase_storage_service.dart' as _i301;
import '../core/firebase/firebase_token_provider.dart' as _i582;
import '../core/firebase/firestore_service.dart' as _i494;
import '../features/acoustic_diagnostic/data/datasources/engine_diagnostic_remote_data_source.dart'
    as _i935;
import '../features/acoustic_diagnostic/data/repositories/engine_diagnostic_repository_impl.dart'
    as _i877;
import '../features/acoustic_diagnostic/domain/repositories/engine_diagnostic_repository.dart'
    as _i557;
import '../features/acoustic_diagnostic/domain/usecases/get_diagnostics_by_inspection.dart'
    as _i176;
import '../features/acoustic_diagnostic/domain/usecases/save_diagnostic_result.dart'
    as _i65;
import '../features/authentication/data/datasources/auth_remote_data_source.dart'
    as _i299;
import '../features/authentication/data/repositories/auth_repository_impl.dart'
    as _i781;
import '../features/authentication/domain/repositories/auth_repository.dart'
    as _i716;
import '../features/authentication/domain/usecases/get_current_user.dart'
    as _i518;
import '../features/authentication/domain/usecases/get_id_token.dart' as _i1048;
import '../features/authentication/domain/usecases/login_user.dart' as _i395;
import '../features/authentication/domain/usecases/logout_user.dart' as _i792;
import '../features/authentication/domain/usecases/observe_auth_state.dart'
    as _i390;
import '../features/authentication/domain/usecases/register_user.dart' as _i682;
import '../features/authentication/domain/usecases/reset_password.dart'
    as _i756;
import '../features/authentication/domain/usecases/send_email_verification.dart'
    as _i763;
import '../features/damage_assessment/data/datasources/damage_remote_data_source.dart'
    as _i434;
import '../features/damage_assessment/data/repositories/damage_repository_impl.dart'
    as _i874;
import '../features/damage_assessment/domain/repositories/damage_repository.dart'
    as _i400;
import '../features/damage_assessment/domain/usecases/get_damage_results_by_inspection.dart'
    as _i148;
import '../features/damage_assessment/domain/usecases/save_damage_result.dart'
    as _i408;
import '../features/inspections/data/datasources/inspection_remote_data_source.dart'
    as _i343;
import '../features/inspections/data/repositories/inspection_repository_impl.dart'
    as _i147;
import '../features/inspections/domain/repositories/inspection_repository.dart'
    as _i222;
import '../features/inspections/domain/usecases/create_inspection.dart'
    as _i924;
import '../features/inspections/domain/usecases/get_inspection_by_id.dart'
    as _i260;
import '../features/inspections/domain/usecases/get_inspections_by_user.dart'
    as _i28;
import '../features/inspections/domain/usecases/get_inspections_by_vehicle.dart'
    as _i840;
import '../features/inspections/domain/usecases/update_inspection_status.dart'
    as _i119;
import '../features/marketplace/data/datasources/marketplace_remote_data_source.dart'
    as _i49;
import '../features/marketplace/data/repositories/marketplace_repository_impl.dart'
    as _i333;
import '../features/marketplace/domain/repositories/marketplace_repository.dart'
    as _i485;
import '../features/marketplace/domain/usecases/create_listing.dart' as _i404;
import '../features/marketplace/domain/usecases/get_active_listings.dart'
    as _i623;
import '../features/marketplace/domain/usecases/get_listing_by_id.dart'
    as _i664;
import '../features/marketplace/domain/usecases/update_listing_status.dart'
    as _i728;
import '../features/reports/data/datasources/report_remote_data_source.dart'
    as _i922;
import '../features/reports/data/repositories/report_repository_impl.dart'
    as _i593;
import '../features/reports/domain/repositories/report_repository.dart' as _i22;
import '../features/reports/domain/usecases/get_report_by_id.dart' as _i52;
import '../features/reports/domain/usecases/get_report_by_inspection_id.dart'
    as _i622;
import '../features/reports/domain/usecases/save_report.dart' as _i744;
import '../features/vehicles/data/datasources/vehicle_remote_data_source.dart'
    as _i410;
import '../features/vehicles/data/repositories/vehicle_repository_impl.dart'
    as _i815;
import '../features/vehicles/domain/repositories/vehicle_repository.dart'
    as _i742;
import '../features/vehicles/domain/usecases/create_vehicle.dart' as _i828;
import '../features/vehicles/domain/usecases/delete_vehicle.dart' as _i283;
import '../features/vehicles/domain/usecases/get_vehicle_by_id.dart' as _i679;
import '../features/vehicles/domain/usecases/get_vehicles_by_owner.dart'
    as _i644;
import '../features/vehicles/domain/usecases/update_vehicle.dart' as _i517;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final firebaseModule = _$FirebaseModule();
    gh.lazySingleton<_i59.FirebaseAuth>(() => firebaseModule.firebaseAuth);
    gh.lazySingleton<_i974.FirebaseFirestore>(() => firebaseModule.firestore);
    gh.lazySingleton<_i457.FirebaseStorage>(
      () => firebaseModule.firebaseStorage,
    );
    gh.lazySingleton<_i299.AuthRemoteDataSource>(
      () => _i299.AuthRemoteDataSourceImpl(
        gh<_i59.FirebaseAuth>(),
        gh<_i974.FirebaseFirestore>(),
      ),
    );
    gh.lazySingleton<_i301.FirebaseStorageService>(
      () => _i301.FirebaseStorageService(gh<_i457.FirebaseStorage>()),
    );
    gh.lazySingleton<_i494.FirestoreService>(
      () => _i494.FirestoreService(gh<_i974.FirebaseFirestore>()),
    );
    gh.lazySingleton<_i582.FirebaseTokenProvider>(
      () => _i582.FirebaseTokenProvider(gh<_i59.FirebaseAuth>()),
    );
    gh.lazySingleton<_i434.DamageRemoteDataSource>(
      () => _i434.DamageRemoteDataSourceImpl(gh<_i494.FirestoreService>()),
    );
    gh.lazySingleton<_i716.AuthRepository>(
      () => _i781.AuthRepositoryImpl(gh<_i299.AuthRemoteDataSource>()),
    );
    gh.lazySingleton<_i343.InspectionRemoteDataSource>(
      () => _i343.InspectionRemoteDataSourceImpl(gh<_i494.FirestoreService>()),
    );
    gh.lazySingleton<_i935.EngineDiagnosticRemoteDataSource>(
      () => _i935.EngineDiagnosticRemoteDataSourceImpl(
        gh<_i494.FirestoreService>(),
      ),
    );
    gh.lazySingleton<_i922.ReportRemoteDataSource>(
      () => _i922.ReportRemoteDataSourceImpl(gh<_i494.FirestoreService>()),
    );
    gh.lazySingleton<_i557.EngineDiagnosticRepository>(
      () => _i877.EngineDiagnosticRepositoryImpl(
        gh<_i935.EngineDiagnosticRemoteDataSource>(),
      ),
    );
    gh.lazySingleton<_i410.VehicleRemoteDataSource>(
      () => _i410.VehicleRemoteDataSourceImpl(gh<_i494.FirestoreService>()),
    );
    gh.lazySingleton<_i49.MarketplaceRemoteDataSource>(
      () => _i49.MarketplaceRemoteDataSourceImpl(gh<_i494.FirestoreService>()),
    );
    gh.lazySingleton<_i518.GetCurrentUser>(
      () => _i518.GetCurrentUser(gh<_i716.AuthRepository>()),
    );
    gh.lazySingleton<_i1048.GetIdToken>(
      () => _i1048.GetIdToken(gh<_i716.AuthRepository>()),
    );
    gh.lazySingleton<_i395.LoginUser>(
      () => _i395.LoginUser(gh<_i716.AuthRepository>()),
    );
    gh.lazySingleton<_i792.LogoutUser>(
      () => _i792.LogoutUser(gh<_i716.AuthRepository>()),
    );
    gh.lazySingleton<_i390.ObserveAuthState>(
      () => _i390.ObserveAuthState(gh<_i716.AuthRepository>()),
    );
    gh.lazySingleton<_i682.RegisterUser>(
      () => _i682.RegisterUser(gh<_i716.AuthRepository>()),
    );
    gh.lazySingleton<_i756.ResetPassword>(
      () => _i756.ResetPassword(gh<_i716.AuthRepository>()),
    );
    gh.lazySingleton<_i763.SendEmailVerification>(
      () => _i763.SendEmailVerification(gh<_i716.AuthRepository>()),
    );
    gh.lazySingleton<_i222.InspectionRepository>(
      () => _i147.InspectionRepositoryImpl(
        gh<_i343.InspectionRemoteDataSource>(),
      ),
    );
    gh.lazySingleton<_i176.GetDiagnosticsByInspection>(
      () => _i176.GetDiagnosticsByInspection(
        gh<_i557.EngineDiagnosticRepository>(),
      ),
    );
    gh.lazySingleton<_i65.SaveDiagnosticResult>(
      () => _i65.SaveDiagnosticResult(gh<_i557.EngineDiagnosticRepository>()),
    );
    gh.lazySingleton<_i400.DamageRepository>(
      () => _i874.DamageRepositoryImpl(gh<_i434.DamageRemoteDataSource>()),
    );
    gh.lazySingleton<_i22.ReportRepository>(
      () => _i593.ReportRepositoryImpl(gh<_i922.ReportRemoteDataSource>()),
    );
    gh.lazySingleton<_i485.MarketplaceRepository>(
      () => _i333.MarketplaceRepositoryImpl(
        gh<_i49.MarketplaceRemoteDataSource>(),
      ),
    );
    gh.lazySingleton<_i742.VehicleRepository>(
      () => _i815.VehicleRepositoryImpl(gh<_i410.VehicleRemoteDataSource>()),
    );
    gh.lazySingleton<_i924.CreateInspection>(
      () => _i924.CreateInspection(gh<_i222.InspectionRepository>()),
    );
    gh.lazySingleton<_i260.GetInspectionById>(
      () => _i260.GetInspectionById(gh<_i222.InspectionRepository>()),
    );
    gh.lazySingleton<_i28.GetInspectionsByUser>(
      () => _i28.GetInspectionsByUser(gh<_i222.InspectionRepository>()),
    );
    gh.lazySingleton<_i840.GetInspectionsByVehicle>(
      () => _i840.GetInspectionsByVehicle(gh<_i222.InspectionRepository>()),
    );
    gh.lazySingleton<_i119.UpdateInspectionStatus>(
      () => _i119.UpdateInspectionStatus(gh<_i222.InspectionRepository>()),
    );
    gh.lazySingleton<_i148.GetDamageResultsByInspection>(
      () => _i148.GetDamageResultsByInspection(gh<_i400.DamageRepository>()),
    );
    gh.lazySingleton<_i408.SaveDamageResult>(
      () => _i408.SaveDamageResult(gh<_i400.DamageRepository>()),
    );
    gh.lazySingleton<_i404.CreateListing>(
      () => _i404.CreateListing(gh<_i485.MarketplaceRepository>()),
    );
    gh.lazySingleton<_i623.GetActiveListings>(
      () => _i623.GetActiveListings(gh<_i485.MarketplaceRepository>()),
    );
    gh.lazySingleton<_i664.GetListingById>(
      () => _i664.GetListingById(gh<_i485.MarketplaceRepository>()),
    );
    gh.lazySingleton<_i728.UpdateListingStatus>(
      () => _i728.UpdateListingStatus(gh<_i485.MarketplaceRepository>()),
    );
    gh.lazySingleton<_i52.GetReportById>(
      () => _i52.GetReportById(gh<_i22.ReportRepository>()),
    );
    gh.lazySingleton<_i622.GetReportByInspectionId>(
      () => _i622.GetReportByInspectionId(gh<_i22.ReportRepository>()),
    );
    gh.lazySingleton<_i744.SaveReport>(
      () => _i744.SaveReport(gh<_i22.ReportRepository>()),
    );
    gh.lazySingleton<_i828.CreateVehicle>(
      () => _i828.CreateVehicle(gh<_i742.VehicleRepository>()),
    );
    gh.lazySingleton<_i283.DeleteVehicle>(
      () => _i283.DeleteVehicle(gh<_i742.VehicleRepository>()),
    );
    gh.lazySingleton<_i679.GetVehicleById>(
      () => _i679.GetVehicleById(gh<_i742.VehicleRepository>()),
    );
    gh.lazySingleton<_i644.GetVehiclesByOwner>(
      () => _i644.GetVehiclesByOwner(gh<_i742.VehicleRepository>()),
    );
    gh.lazySingleton<_i517.UpdateVehicle>(
      () => _i517.UpdateVehicle(gh<_i742.VehicleRepository>()),
    );
    return this;
  }
}

class _$FirebaseModule extends _i1053.FirebaseModule {}
