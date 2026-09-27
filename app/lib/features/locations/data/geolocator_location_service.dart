import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../domain/device_location.dart';

class GeolocatorLocationService implements DeviceLocationService {
  const GeolocatorLocationService();

  /// Neighborhood-level accuracy is plenty and resolves faster than GPS-fine.
  static const _settings = LocationSettings(
    accuracy: LocationAccuracy.medium,
    timeLimit: Duration(seconds: 15),
  );

  @override
  Future<GeoPoint> currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationException(LocationIssue.serviceDisabled);
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    switch (permission) {
      case LocationPermission.deniedForever:
        throw const LocationException(LocationIssue.permissionDeniedForever);
      case LocationPermission.denied || LocationPermission.unableToDetermine:
        throw const LocationException(LocationIssue.permissionDenied);
      case LocationPermission.whileInUse || LocationPermission.always:
        break;
    }

    try {
      final position = await Geolocator.getCurrentPosition(locationSettings: _settings);
      return GeoPoint(position.latitude, position.longitude);
    } on LocationServiceDisabledException catch (e) {
      throw LocationException(LocationIssue.serviceDisabled, e);
    } on PermissionDeniedException catch (e) {
      throw LocationException(LocationIssue.permissionDenied, e);
    } on TimeoutException catch (e) {
      final last = await _lastKnown();
      if (last != null) return last;
      throw LocationException(LocationIssue.unavailable, e);
    } catch (e) {
      throw LocationException(LocationIssue.unavailable, e);
    }
  }

  Future<GeoPoint?> _lastKnown() async {
    if (kIsWeb) return null; // not supported by browsers
    try {
      final p = await Geolocator.getLastKnownPosition();
      return p == null ? null : GeoPoint(p.latitude, p.longitude);
    } catch (_) {
      return null;
    }
  }

  @override
  bool get canOpenSettings => !kIsWeb;

  @override
  Future<void> openSettingsFor(LocationIssue issue) async {
    if (issue == LocationIssue.serviceDisabled) {
      await Geolocator.openLocationSettings();
    } else {
      await Geolocator.openAppSettings();
    }
  }
}
