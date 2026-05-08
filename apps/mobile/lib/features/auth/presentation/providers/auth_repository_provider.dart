import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:unishare_mobile/features/auth/data/datasources/firebase_auth_datasource.dart';
import 'package:unishare_mobile/features/auth/data/datasources/firestore_user_datasource.dart';
import 'package:unishare_mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:unishare_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:unishare_mobile/features/auth/domain/usecases/sign_out.dart';

part 'auth_repository_provider.g.dart';

@Riverpod(keepAlive: true)
FirebaseAuthDatasource firebaseAuthDatasource(Ref ref) {
  return FirebaseAuthDatasource();
}

@Riverpod(keepAlive: true)
FirestoreUserDatasource firestoreUserDatasource(Ref ref) {
  return FirestoreUserDatasource();
}

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  return AuthRepositoryImpl(
    authDatasource: ref.watch(firebaseAuthDatasourceProvider),
    firestoreDatasource: ref.watch(firestoreUserDatasourceProvider),
  );
}

@Riverpod(keepAlive: true)
SignOut signOutUseCase(Ref ref) => SignOut(ref.watch(authRepositoryProvider));
