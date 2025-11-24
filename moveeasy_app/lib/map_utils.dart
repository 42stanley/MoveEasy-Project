import 'dart:ui' as ui;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/foundation.dart';

Future<BitmapDescriptor> loadMarkerBitmapDescriptor(BuildContext context, String assetPath, {int width = 96}) async {
  try {
    final config = ImageConfiguration(devicePixelRatio: MediaQuery.of(context).devicePixelRatio);
    return await BitmapDescriptor.fromAssetImage(config, assetPath);
  } catch (e, st) {
    if (kDebugMode) debugPrint('Marker load failed for $assetPath: $e\n$st');
    return BitmapDescriptor.defaultMarker;
  }
}

// Example usage in your map init / marker creation code:
/*
final BitmapDescriptor icon = await loadMarkerBitmapDescriptor(context, 'assets/marker.png', width: 96);
final marker = Marker(markerId: MarkerId('id'), position: LatLng(lat, lng), icon: icon);
setState(() { markers.add(marker); });
*/