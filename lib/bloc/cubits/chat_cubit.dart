import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:test_task/api_client.dart';
import 'package:test_task/api_endpoints.dart';
import 'package:test_task/bloc/state/chat_state.dart';
import 'package:test_task/data/models/chat_message.dart';
import 'package:test_task/data/repositories/chat_repository.dart';
import 'package:test_task/data/repositories/chat_repository_impl.dart';

class ChatCubit extends Cubit<ChatState> {
  final ChatRepository repository;

  ChatCubit()
    : repository = ChatRepositoryImpl(
        apiClient: ApiClient(
          baseUrl: ApiEndpoints.baseUrl,
          tokenStorage: TokenLocalDataSource(),
        ),
      ),
      super(ChatInitial()) {
    // Загружаем сообщения при инициализации
    loadMessages();
  }

  Future<void> loadMessages() async {
    emit(ChatLoading());
    try {
      // Используем await для получения результата из Future
      final List<ChatMessage> messages = await repository.getMessages();
      emit(ChatLoaded(messages));
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }
}
