import 'dart:ui';
import 'package:flutter/material.dart';

/// Error Boundary Widget - Catches and displays errors gracefully
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(Object error, StackTrace? stackTrace)? errorBuilder;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.errorBuilder,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;

  @override
  void initState() {
    super.initState();
    ErrorHandling.ensureInitialized();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.errorBuilder?.call(_error!, _stackTrace) ??
          _DefaultErrorDisplay(error: _error!, stackTrace: _stackTrace);
    }
    return ErrorBoundaryScope(
      onError: (error, stackTrace) {
        setState(() {
          _error = error;
          _stackTrace = stackTrace;
        });
      },
      child: widget.child,
    );
  }
}

class ErrorBoundaryScope extends InheritedWidget {
  final void Function(Object error, StackTrace stackTrace) onError;

  const ErrorBoundaryScope({
    super.key,
    required this.onError,
    required super.child,
  });

  static ErrorBoundaryScope of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ErrorBoundaryScope>()!;
  }

  @override
  bool updateShouldNotify(ErrorBoundaryScope oldWidget) => false;
}

class _DefaultErrorDisplay extends StatelessWidget {
  final Object error;
  final StackTrace? stackTrace;

  const _DefaultErrorDisplay({required this.error, this.stackTrace});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE0F2FE), Color(0xFFF1F5F9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Something went wrong',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: const TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Error Handling Utilities
class ErrorHandling {
  static bool _initialized = false;

  static void ensureInitialized() {
    if (!_initialized) {
      FlutterError.onError = (details) {
        ErrorHandling.logError(details.exception, details.stack);
      };
      PlatformDispatcher.instance.onError = (error, stack) {
        ErrorHandling.logError(error, stack);
        return true;
      };
      _initialized = true;
    }
  }

  static void logError(Object error, StackTrace? stack) {
    debugPrint('Unhandled error: $error\n$stack');
  }
}
