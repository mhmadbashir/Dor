/// A point on the map (WGS84).
class GeoPoint {
  const GeoPoint(this.latitude, this.longitude);

  final double latitude;
  final double longitude;

  @override
  bool operator ==(Object other) =>
      other is GeoPoint && other.latitude == latitude && other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);
}

/// A position fix, with altitude when the device provides one.
class DeviceFix {
  const DeviceFix(this.point, {this.altitudeM, this.altitudeAccuracyM});

  final GeoPoint point;
  final double? altitudeM;
  final double? altitudeAccuracyM;
}

/// Why the device location could not be read.
enum LocationIssue { serviceDisabled, permissionDenied, permissionDeniedForever, unavailable }

class LocationException implements Exception {
  const LocationException(this.issue, [this.cause]);

  final LocationIssue issue;
  final Object? cause;

  @override
  String toString() => 'LocationException($issue)';
}

/// Reads the device's current position, handling permission prompts.
abstract interface class DeviceLocationService {
  /// Throws [LocationException] when the position can't be obtained.
  Future<DeviceFix> currentPosition();

  /// Whether [openSettingsFor] can do anything on this platform.
  bool get canOpenSettings;

  /// Opens the system screen that resolves [issue] (location or app settings).
  Future<void> openSettingsFor(LocationIssue issue);
}
