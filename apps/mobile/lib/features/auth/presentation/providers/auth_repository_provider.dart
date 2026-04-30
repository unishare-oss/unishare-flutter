import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/datasources/firebase_auth_datasource.dart';
import '../../data/datasources/firestore_user_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';

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
