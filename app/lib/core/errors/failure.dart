/// Domain-level error thrown by repositories. Presentation code maps each
/// [FailureKind] to a localized message; raw backend errors never reach widgets.
enum FailureKind {
  invalidPhone,
  invalidOtp,
  network,
  rateLimited,
  forbidden,
  sessionExpired,
  unknown,
}

class Failure implements Exception {
  const Failure(this.kind, [this.cause]);

  final FailureKind kind;

  /// The underlying error, kept for logging only.
  final Object? cause;

  @override
  String toString() => 'Failure($kind${cause == null ? '' : ': $cause'})';
}
