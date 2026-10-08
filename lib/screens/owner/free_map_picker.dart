// screens/owner/free_map_picker.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../utils/theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class FreeMapPicker extends StatefulWidget {
  final GeoPoint? initialLocation;

  const FreeMapPicker({super.key, this.initialLocation});

  @override
  State<FreeMapPicker> createState() => _FreeMapPickerState();
}

class _FreeMapPickerState extends State<FreeMapPicker> {
  late MapController _mapController;
  LatLng? _selectedLocation;
  bool _isLocationSelected = false;
  String _address = 'Tap pada peta untuk memilih lokasi';
  bool _isLoadingAddress = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    // Set initial location
    if (widget.initialLocation != null) {
      _selectedLocation = LatLng(
        widget.initialLocation!.latitude,
        widget.initialLocation!.longitude,
      );
      _isLocationSelected = true;

      // Load address for initial location
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _getAddressFromLatLng(_selectedLocation!);
      });
    } else {
      _selectedLocation = const LatLng(-6.2088, 106.8456); // Jakarta default
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Lokasi Restoran'),
        backgroundColor: AppColors.primaryOrange,
        foregroundColor: Colors.white,
        actions: [
          if (_isLocationSelected)
            IconButton(
              icon: const Icon(Icons.check, color: Colors.white),
              onPressed: () {
                // Return both location and address
                Navigator.pop(context, {
                  'location': GeoPoint(
                    _selectedLocation!.latitude,
                    _selectedLocation!.longitude,
                  ),
                  'address': _address,
                });
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: _selectedLocation!,
              zoom: 13.0,
              onTap: (tapPosition, point) {
                setState(() {
                  _selectedLocation = point;
                  _isLocationSelected = true;
                });
                _getAddressFromLatLng(point); // Ambil alamat otomatis
              },
            ),
            children: [
              // FREE Tile Layer - OpenStreetMap
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.nyam_makaaan2',
              ),

              // Marker untuk lokasi terpilih - DIPERBAIKI
              if (_isLocationSelected)
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 50.0,
                      height: 50.0,
                      point: _selectedLocation!,
                      child: const Icon(
                        // Ganti builder dengan child
                        Icons.location_pin,
                        color: Colors.red,
                        size: 50.0,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Pin tengah untuk panduan
          const Center(
            child: Icon(
              Icons.location_searching,
              color: Colors.blue,
              size: 40.0,
            ),
          ),

          // Address Display Card
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Alamat Terpilih:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  if (_isLoadingAddress)
                    const Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Mencari alamat...'),
                      ],
                    )
                  else
                    Text(_address, style: const TextStyle(fontSize: 13)),
                  if (_isLocationSelected) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Lat: ${_selectedLocation!.latitude.toStringAsFixed(6)}, '
                      'Lng: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () {
              _mapController.move(_selectedLocation!, 15.0);
            },
            backgroundColor: AppColors.primaryOrange,
            child: const Icon(Icons.my_location, color: Colors.white),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: _getCurrentLocation,
            backgroundColor: Colors.blue,
            child: const Icon(Icons.gps_fixed, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Cek permission
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('GPS tidak aktif')));
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Izin lokasi ditolak')),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Izin lokasi ditolak permanen')),
          );
        }
        return;
      }

      // Dapatkan lokasi sekarang
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _selectedLocation = LatLng(position.latitude, position.longitude);
          _isLocationSelected = true;
        });

        _mapController.move(_selectedLocation!, 15.0);

        // Get address for current location
        _getAddressFromLatLng(_selectedLocation!);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lokasi saat ini berhasil didapatkan'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Fallback ke lokasi default jika GPS gagal
      if (mounted) {
        setState(() {
          _selectedLocation = const LatLng(-6.2088, 106.8456);
          _isLocationSelected = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Menggunakan lokasi default Jakarta'),
            backgroundColor: AppColors.primaryOrange,
          ),
        );
      }
    }
  }

  // Reverse Geocoding: Dari koordinat ke alamat - DIPERBAIKI
  Future<void> _getAddressFromLatLng(LatLng position) async {
    setState(() {
      _isLoadingAddress = true;
    });

    try {
      // Gunakan placemarkFromCoordinates langsung
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty && mounted) {
        Placemark place = placemarks[0];

        // Build address from placemark
        String address = '';

        if (place.street != null && place.street!.isNotEmpty) {
          address += place.street!;
        }

        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          if (address.isNotEmpty) address += ', ';
          address += place.subLocality!;
        }

        if (place.locality != null && place.locality!.isNotEmpty) {
          if (address.isNotEmpty) address += ', ';
          address += place.locality!;
        }

        if (place.subAdministrativeArea != null &&
            place.subAdministrativeArea!.isNotEmpty) {
          if (address.isNotEmpty) address += ', ';
          address += place.subAdministrativeArea!;
        }

        if (place.administrativeArea != null &&
            place.administrativeArea!.isNotEmpty) {
          if (address.isNotEmpty) address += ', ';
          address += place.administrativeArea!;
        }

        if (place.country != null && place.country!.isNotEmpty) {
          if (address.isNotEmpty) address += ', ';
          address += place.country!;
        }

        setState(() {
          _address = address.isNotEmpty ? address : 'Alamat tidak ditemukan';
          _isLoadingAddress = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _address = 'Gagal mendapatkan alamat: $e';
          _isLoadingAddress = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}
