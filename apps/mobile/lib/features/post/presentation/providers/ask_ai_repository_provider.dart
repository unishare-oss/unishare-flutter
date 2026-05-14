import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:unishare_mobile/features/post/data/datasources/ask_ai_datasource.dart';
import 'package:unishare_mobile/features/post/data/repositories/ask_ai_repository_impl.dart';
import 'package:unishare_mobile/features/post/domain/repositories/ask_ai_repository.dart';
import 'package:unishare_mobile/features/post/domain/usecases/ask_ai.dart';

part 'ask_ai_repository_provider.g.dart';

@riverpod
AskAiRepository askAiRepository(Ref ref) =>
    AskAiRepositoryImpl(AskAiDatasource());

@riverpod
AskAiUseCase askAiUseCase(Ref ref) =>
    AskAiUseCase(ref.watch(askAiRepositoryProvider));
