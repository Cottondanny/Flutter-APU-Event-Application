import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class EventMapWidget extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String locationName;

  const EventMapWidget({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.locationName,
  });

  @override
  State<EventMapWidget> createState() => _EventMapWidgetState();
}

class _EventMapWidgetState extends State<EventMapWidget> {
  // Controller lets us interact with the map after it loads
  GoogleMapController? _mapController;

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  // Opens Google Maps app with directions to this location
  Future<void> _openInMaps() async {
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${widget.latitude},${widget.longitude}',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Google Maps')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final position = LatLng(widget.latitude, widget.longitude);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Map preview — fixed height, full width
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 180,
            child: GoogleMap(
              // Disable all gestures so the map doesn't
              // fight with the page scroll
              scrollGesturesEnabled: false,
              zoomGesturesEnabled: false,
              rotateGesturesEnabled: false,
              tiltGesturesEnabled: false,
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
              // Center the map on the event location
              initialCameraPosition: CameraPosition(
                target: position,
                zoom: 16,
              ),
              // Drop a pin on the exact location
              markers: {
                Marker(
                  markerId: const MarkerId('event_location'),
                  position: position,
                  infoWindow: InfoWindow(title: widget.locationName),
                ),
              },
              onMapCreated: (controller) {
                _mapController = controller;
              },
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Open in Maps button below the preview
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _openInMaps,
            icon: const Icon(Icons.directions, size: 18),
            label: const Text('Open in Google Maps'),
          ),
        ),
      ],
    );
  }
}