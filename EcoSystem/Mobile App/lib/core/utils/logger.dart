// =============================================================================
// LOGGER UTILITY - Structured Logging for Debug and Production
// =============================================================================
// Provides a centralized logging solution for the application.
// Uses the logger package for formatted output with log levels.
// =============================================================================

import 'package:logger/logger.dart';

/// -----------------------------------------------------------------------------
/// App Logger
/// -----------------------------------------------------------------------------
/// Static utility class for application-wide logging.

class AppLogger {
  AppLogger._();

  /// The logger instance with pretty printing enabled
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,        // Number of method calls to be displayed
      errorMethodCount: 5,   // Number of method calls for errors
      lineLength: 80,        // Width of the output
      colors: true,          // Colorful log messages
      printEmojis: true,     // Print emojis for log levels
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  /// Log verbose (trace) message
  static void verbose(String message) {
    _logger.t(message);
  }

  /// Log debug message
  static void debug(String message) {
    _logger.d(message);
  }

  /// Log info message
  static void info(String message) {
    _logger.i(message);
  }

  /// Log warning message
  static void warning(String message) {
    _logger.w(message);
  }

  /// Log error message with optional error object and stack trace
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Log fatal/critical error
  static void fatal(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }
}
