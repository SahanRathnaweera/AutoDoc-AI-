import 'package:cloud_firestore/cloud_firestore.dart' as i974;
import 'package:firebase_auth/firebase_auth.dart' as i59;
import 'package:firebase_storage/firebase_storage.dart' as i457;
import 'package:get_it/get_it.dart' as i174;
import 'package:injectable/injectable.dart' as i526;

import '../core/firebase/firebase_module.dart' as i1053;
import '../core/firebase/firebase_storage_service.dart' as i301;
import '../core/firebase/firebase_token_provider.dart' as i582;
import '../core/firebase/firestore_service.dart' as i494;
import '../features/authentication/data/datasources/auth_remote_data_source.dart'
    as i299;
import '../features/authentication/data/repositories/auth_repository_impl.dart'
    as i781;
import '../features/authentication/domain/repositories/auth_repository.dart'
    as i716;
import '../features/authentication/domain/usecases/get_current_user.dart'
    as i518;
import '../features/authentication/domain/usecases/get_id_token.dart' as i1048;
import '../features/authentication/domain/usecases/login_user.dart' as i395;
import '../features/authentication/domain/usecases/logout_user.dart' as i792;
import '../features/authentication/domain/usecases/observe_auth_state.dart'
    as i390;
import '../features/authentication/domain/usecases/register_user.dart' as i682;
import '../features/authentication/domain/usecases/reset_password.dart' as i756;
import '../features/authentication/domain/usecases/send_email_verification.dart'
    as i763;
import '../features/authentication/domain/usecases/send_phone_otp.dart' as i821;
import '../features/authentication/domain/usecases/verify_phone_otp.dart'
    as i822;

extension GetItInjectableX on i174.GetIt {
  i174.GetIt init({
    String? environment,
    i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = i526.GetItHelper(this, environment, environmentFilter);
    final firebaseModule = _$FirebaseModule();
    gh.lazySingleton<i59.FirebaseAuth>(() => firebaseModule.firebaseAuth);
    gh.lazySingleton<i974.FirebaseFirestore>(() => firebaseModule.firestore);
    gh.lazySingleton<i457.FirebaseStorage>(
      () => firebaseModule.firebaseStorage,
    );
    gh.lazySingleton<i299.AuthRemoteDataSource>(
      () => i299.AuthRemoteDataSourceImpl(
        gh<i59.FirebaseAuth>(),
        gh<i974.FirebaseFirestore>(),
      ),
    );
    gh.lazySingleton<i301.FirebaseStorageService>(
      () => i301.FirebaseStorageService(gh<i457.FirebaseStorage>()),
    );
    gh.lazySingleton<i494.FirestoreService>(
      () => i494.FirestoreService(gh<i974.FirebaseFirestore>()),
    );
    gh.lazySingleton<i582.FirebaseTokenProvider>(
      () => i582.FirebaseTokenProvider(gh<i59.FirebaseAuth>()),
    );
    gh.lazySingleton<i716.AuthRepository>(
      () => i781.AuthRepositoryImpl(gh<i299.AuthRemoteDataSource>()),
    );
    gh.lazySingleton<i518.GetCurrentUser>(
      () => i518.GetCurrentUser(gh<i716.AuthRepository>()),
    );
    gh.lazySingleton<i1048.GetIdToken>(
      () => i1048.GetIdToken(gh<i716.AuthRepository>()),
    );
    gh.lazySingleton<i395.LoginUser>(
      () => i395.LoginUser(gh<i716.AuthRepository>()),
    );
    gh.lazySingleton<i792.LogoutUser>(
      () => i792.LogoutUser(gh<i716.AuthRepository>()),
    );
    gh.lazySingleton<i390.ObserveAuthState>(
      () => i390.ObserveAuthState(gh<i716.AuthRepository>()),
    );
    gh.lazySingleton<i682.RegisterUser>(
      () => i682.RegisterUser(gh<i716.AuthRepository>()),
    );
    gh.lazySingleton<i756.ResetPassword>(
      () => i756.ResetPassword(gh<i716.AuthRepository>()),
    );
    gh.lazySingleton<i763.SendEmailVerification>(
      () => i763.SendEmailVerification(gh<i716.AuthRepository>()),
    );
    gh.lazySingleton<i821.SendPhoneOtp>(
      () => i821.SendPhoneOtp(gh<i716.AuthRepository>()),
    );
    gh.lazySingleton<i822.VerifyPhoneOtp>(
      () => i822.VerifyPhoneOtp(gh<i716.AuthRepository>()),
    );
    return this;
  }
}

class _$FirebaseModule extends i1053.FirebaseModule {}
