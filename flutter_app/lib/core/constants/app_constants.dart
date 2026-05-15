class AppConstants {
  AppConstants._();

  static const String appName = 'RAG Assistant';
  static const String appVersion = '1.0.0';

  // ── Supported file types ─────────────────────────────────────────
  static const List<String> allowedExtensions = ['pdf', 'txt', 'md'];

  // ── UI strings ───────────────────────────────────────────────────
  static const String uploadHint = 'Upload a PDF, TXT or MD file to get started';
  static const String queryHint = 'Ask a question about your documents...';
  static const String emptyDocuments = 'No documents indexed yet.\nUpload a file to begin.';
  static const String emptyChat = 'Ask anything about your uploaded documents.';
  static const String noAnswerFound = 'I could not find an answer in the provided documents.';

  // ── Error messages ───────────────────────────────────────────────
  static const String networkError = 'Network error. Is the backend running?';
  static const String serverError = 'Server error. Please try again.';
  static const String fileTooLarge = 'File too large. Max 20MB allowed.';
  static const String unsupportedFile = 'Unsupported file type. Use PDF, TXT or MD.';
  static const String emptyQuestion = 'Please enter a question first.';
}