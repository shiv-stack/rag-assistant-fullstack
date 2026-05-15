class ApiConstants {
  ApiConstants._(); // prevent instantiation

  // ── Base URL ─────────────────────────────────────────────────────
  // Web browser → localhost
  // Android emulator → 10.0.2.2
  // Physical device → your machine IP e.g. 192.168.1.5
  static const String baseUrl = 'http://localhost:8000';

  // ── Endpoints ────────────────────────────────────────────────────
  static const String health = '/health';
  static const String ingest = '/ingest';
  static const String query = '/query';
  static const String documents = '/documents';

  // ── Timeouts ─────────────────────────────────────────────────────
  // ingest can be slow on first run (model load + embedding)
  static const int connectTimeoutMs = 10000;   // 10s
  static const int receiveTimeoutMs = 120000;  // 120s — LLM can be slow
  static const int sendTimeoutMs = 60000;      // 60s — file upload

  // ── Request config ───────────────────────────────────────────────
  static const int defaultTopK = 5;
  static const int maxFileSizeMb = 20;
}