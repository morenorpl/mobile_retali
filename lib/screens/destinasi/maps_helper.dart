import 'package:url_launcher/url_launcher.dart';

Future<void> openMapsTo(double lat, double lng, {String? label}) async {
  final encoded = Uri.encodeComponent(label ?? '');
  // Coba buka app Google Maps lebih dulu
  final uriApp = Uri.parse('comgooglemaps://?daddr=$lat,$lng&directionsmode=driving');
  // Fallback ke browser kalau app nggak ada
  final uriWeb = Uri.parse(
    'https://www.google.com/maps/dir/?api=1'
    '&destination=$lat,$lng'
    '${label != null ? '&destination_place=$encoded' : ''}'
    '&travelmode=driving',
  );

  if (await canLaunchUrl(uriApp)) {
    await launchUrl(uriApp);
  } else {
    await launchUrl(uriWeb, mode: LaunchMode.externalApplication);
  }
}