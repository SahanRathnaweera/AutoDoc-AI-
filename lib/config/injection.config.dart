import 'package:cloud_firestore/cloud_firestore.dart' as _i974;
import 'package:firebase_auth/firebase_auth.dart' as _i59;
import 'package:firebase_storage/firebase_storage.dart' as _i457;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

import '../core/firebase/firebase_module.dart' as _i1053;
import '../core/firebase/firebase_storage_service.dart' as _i301;
import '../core/firebase/firebase_token_provider.dart' as _i582;
import '../core/firebase/firestore_service.dart' as _i494;
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
import '../features/authentication/domain/usecases/send_phone_otp.dart'
    as _i821;
import '../features/authentication/domain/usecases/verify_phone_otp.dart'
    as _i822;

extension GetItInjectableX on _i174.GetIt {
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
    gh.lazySingleton<_i716.AuthRepository>(
      () => _i781.AuthRepositoryImpl(gh<_i299.AuthRemoteDataSource>()),
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
    gh.lazySingleton<_i821.SendPhoneOtp>(
      () => _i821.SendPhoneOtp(gh<_i716.AuthRepository>()),
    );
    gh.lazySingleton<_i822.VerifyPhoneOtp>(
      () => _i822.VerifyPhoneOtp(gh<_i716.AuthRepository>()),
    );
    return this;
  }
}

class _$FirebaseModule extends _i1053.FirebaseModule {}
