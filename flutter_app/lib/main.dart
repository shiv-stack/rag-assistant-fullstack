import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:rag_knowledge_assistant/core/network/api_client.dart';
import 'package:rag_knowledge_assistant/data/datasources/rag_remote_datasource.dart';
import 'package:rag_knowledge_assistant/data/repositories/rag_repository_impl.dart';
import 'package:rag_knowledge_assistant/domain/usecases/ask_question.dart';
import 'package:rag_knowledge_assistant/domain/usecases/delete_document.dart';
import 'package:rag_knowledge_assistant/domain/usecases/list_documents.dart';
import 'package:rag_knowledge_assistant/domain/usecases/upload_document.dart';
import 'package:rag_knowledge_assistant/presentation/chat/bloc/chat_bloc.dart';
import 'package:rag_knowledge_assistant/presentation/chat/chat_page.dart';

import 'package:rag_knowledge_assistant/presentation/upload/bloc/upload_bloc.dart';
import 'package:rag_knowledge_assistant/presentation/upload/upload_page.dart';
import 'package:rag_knowledge_assistant/presentation/widgets/documents_page.dart';

// ── Dependency injection ──────────────────────────────────────────────
final sl = GetIt.instance;

void setupDependencies() {
  // Network
  sl.registerLazySingleton(() => ApiClient.instance.dio);

  // Datasource
  sl.registerLazySingleton<RagRemoteDataSource>(
    () => RagRemoteDataSourceImpl(dio: sl()),
  );

  // Repository
  sl.registerLazySingleton<RagRepositoryImpl>(
    () => RagRepositoryImpl(remoteDataSource: sl()),
  );

  // Usecases
  sl.registerLazySingleton(() => AskQuestion(sl<RagRepositoryImpl>()));
  sl.registerLazySingleton(() => UploadDocument(sl<RagRepositoryImpl>()));
  sl.registerLazySingleton(() => ListDocuments(sl<RagRepositoryImpl>()));
  sl.registerLazySingleton(() => DeleteDocument(sl<RagRepositoryImpl>()));

  // BLoCs — registered as factory (new instance per page)
  sl.registerFactory(() => ChatBloc(askQuestion: sl()));
  sl.registerFactory(() => UploadBloc(uploadDocument: sl()));
  sl.registerFactory(
    () => DocumentsBloc(
      listDocuments: sl(),
      deleteDocument: sl(),
    ),
  );
}

// ── Entry point ───────────────────────────────────────────────────────
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  setupDependencies();
  runApp(const RagApp());
}

// ── App ───────────────────────────────────────────────────────────────
class RagApp extends StatelessWidget {
  const RagApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RAG Assistant',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      home: const RagHomePage(),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF6750A4),
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: 'Inter',
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

// ── Home — bottom nav ─────────────────────────────────────────────────
class RagHomePage extends StatefulWidget {
  const RagHomePage({super.key});

  @override
  State<RagHomePage> createState() => _RagHomePageState();
}

class _RagHomePageState extends State<RagHomePage> {
  int _currentIndex = 0;

  final _pages = const [
    _ChatTab(),
    _UploadTab(),
    _DocumentsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(Icons.chat_bubble_rounded),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.upload_file_outlined),
            selectedIcon: Icon(Icons.upload_file_rounded),
            label: 'Upload',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder_rounded),
            label: 'Documents',
          ),
        ],
      ),
    );
  }
}

// ── Tabs — each provides its own BLoC ─────────────────────────────────
class _ChatTab extends StatelessWidget {
  const _ChatTab();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ChatBloc>(),
      child: const ChatPage(),
    );
  }
}

class _UploadTab extends StatelessWidget {
  const _UploadTab();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<UploadBloc>(),
      child: const UploadPage(),
    );
  }
}

class _DocumentsTab extends StatelessWidget {
  const _DocumentsTab();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<DocumentsBloc>(),
      child: const DocumentsPage(),
    );
  }
}
