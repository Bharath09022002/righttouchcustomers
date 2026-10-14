import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/app_feedback.dart';
import '../../../core/widgets/ui.dart';
import '../../../data/models/models.dart';
import '../../providers/providers.dart';

class AddAddressScreen extends ConsumerStatefulWidget {
  const AddAddressScreen({super.key});

  @override
  ConsumerState<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends ConsumerState<AddAddressScreen> {
  String _type = 'Home';
  final _line = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _pin = TextEditingController();
  final _lat = TextEditingController();
  final _lng = TextEditingController();

  final MapController _mapController = MapController();
  // Default to Bangalore / central coords if location is not yet acquired
  LatLng _selectedPoint = const LatLng(12.9716, 77.5946);

  bool _busy = false;
  bool _locating = false;
  bool _geocoding = false;
  String? _err;

  @override
  void initState() {
    super.initState();
    // Prompt and fetch location when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _useCurrentLocation(silent: true);
    });
  }

  @override
  void dispose() {
    _line.dispose();
    _city.dispose();
    _state.dispose();
    _pin.dispose();
    _lat.dispose();
    _lng.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation({bool silent = false}) async {
    setState(() => _locating = true);
    try {
      // 1. Check if location services (GPS) are turned on
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted && !silent) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: Colors.white,
              title: const Row(
                children: [
                  Icon(Icons.location_off_rounded, color: AppColors.warning),
                  SizedBox(width: 8),
                  Text('Location Services Off', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                ],
              ),
              content: const Text(
                'GPS location is disabled on your device. Please turn on location services to auto-locate your address.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await Geolocator.openLocationSettings();
                  },
                  child: const Text('Turn on Location'),
                ),
              ],
            ),
          );
        }
        return;
      }

      // 2. Check and request location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted && !silent) {
            showError(
              context,
              title: 'Permission Denied',
              message: 'Location permission was denied. You can still tap on the map to set your address.',
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted && !silent) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: Colors.white,
              title: const Row(
                children: [
                  Icon(Icons.security_rounded, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text('Permission Needed', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                ],
              ),
              content: const Text(
                'Location permission is permanently blocked. Please allow location access in application settings.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await Geolocator.openAppSettings();
                  },
                  child: const Text('Open App Settings'),
                ),
              ],
            ),
          );
        }
        return;
      }

      // 3. Fetch current position
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );

      final newPoint = LatLng(pos.latitude, pos.longitude);
      _updateLocation(newPoint);

      if (mounted) {
        _mapController.move(newPoint, 16.5);
        if (!silent) {
          showSuccess(
            context,
            title: 'Location Captured',
            message: 'Map centered on your current GPS location.',
          );
        }
      }
    } catch (e) {
      if (mounted && !silent) {
        showError(
          context,
          title: 'Location Error',
          message: 'Could not fetch current GPS position: $e',
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _updateLocation(LatLng point) {
    setState(() {
      _selectedPoint = point;
      _lat.text = point.latitude.toStringAsFixed(6);
      _lng.text = point.longitude.toStringAsFixed(6);
    });
    _reverseGeocode(point.latitude, point.longitude);
  }

  Future<void> _reverseGeocode(double lat, double lng) async {
    setState(() => _geocoding = true);
    try {
      final dio = Dio();
      final res = await dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'format': 'json',
          'lat': lat,
          'lon': lng,
          'zoom': 18,
          'addressdetails': 1,
        },
        options: Options(
          headers: {'User-Agent': 'RightTouchCustomerApp/1.0'},
          receiveTimeout: const Duration(seconds: 6),
          sendTimeout: const Duration(seconds: 6),
        ),
      );

      if (res.data != null && res.data is Map) {
        final address = res.data['address'] as Map<String, dynamic>?;
        if (address != null) {
          final road = address['road'] ?? address['suburb'] ?? address['neighbourhood'] ?? '';
          final houseNo = address['house_number'] ?? '';
          final lineVal = [houseNo, road].where((s) => s.toString().isNotEmpty).join(', ');

          if (lineVal.isNotEmpty && (_line.text.isEmpty || _line.text.contains(','))) {
            _line.text = lineVal;
          } else if (_line.text.isEmpty && res.data['display_name'] != null) {
            _line.text = (res.data['display_name'] as String).split(',').take(2).join(', ').trim();
          }

          final cityVal = address['city'] ??
              address['town'] ??
              address['municipality'] ??
              address['city_district'] ??
              address['state_district'] ??
              address['district'] ??
              address['county'] ??
              address['suburb'] ??
              address['village'] ??
              '';
          if (cityVal.toString().isNotEmpty) {
            _city.text = cityVal.toString();
          } else if (res.data['display_name'] != null) {
            final parts = (res.data['display_name'] as String)
                .split(',')
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toList();
            if (parts.length >= 3) {
              _city.text = parts[parts.length - 3];
            }
          }

          final stateVal = address['state'] ?? '';
          if (stateVal.toString().isNotEmpty) {
            _state.text = stateVal.toString();
          }

          final pinVal = address['postcode'] ?? '';
          if (pinVal.toString().isNotEmpty) {
            _pin.text = pinVal.toString();
          }
        }
      }
    } catch (_) {
      // Graceful fallback: user inputs details manually
    } finally {
      if (mounted) setState(() => _geocoding = false);
    }
  }

  Future<void> _save() async {
    final line = _line.text.trim();
    String city = _city.text.trim();
    final state = _state.text.trim();
    final pin = _pin.text.trim();

    // Auto-fill city if empty from state or address line so user is never blocked
    if (city.isEmpty) {
      if (state.isNotEmpty) {
        city = state;
        _city.text = state;
      } else if (line.isNotEmpty) {
        city = line;
        _city.text = line;
      }
    }

    if (line.isEmpty || city.isEmpty || pin.isEmpty) {
      setState(() => _err = 'Address line, city, and pincode are required.');
      return;
    }

    setState(() {
      _busy = true;
      _err = null;
    });

    try {
      await ref.read(addressRepoProvider).create(
            AddressModel(
              id: '',
              type: _type,
              line: line,
              city: city,
              state: state,
              pincode: pin,
              lat: double.tryParse(_lat.text) ?? _selectedPoint.latitude,
              lng: double.tryParse(_lng.text) ?? _selectedPoint.longitude,
            ),
          );
      ref.invalidate(addressListProvider);
      if (mounted) {
        showSuccess(
          context,
          title: 'Address Saved',
          message: 'Your address has been saved successfully.',
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        final appErr = mapException(e);
        setState(() => _err = appErr.userMessage);
        showError(
          context,
          title: 'Failed to Save Address',
          message: appErr.userMessage,
          onRetry: _save,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Add Address',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. INTERACTIVE MAP SECTION
            Container(
              height: 240,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _selectedPoint,
                      initialZoom: 15.0,
                      onTap: (tapPosition, point) {
                        _updateLocation(point);
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.righttouch.righttouch',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _selectedPoint,
                            width: 50,
                            height: 50,
                            alignment: Alignment.topCenter,
                            child: const Icon(
                              Icons.location_on_rounded,
                              color: AppColors.primary,
                              size: 46,
                              shadows: [
                                Shadow(
                                  color: Color(0x40000000),
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Map instruction badge (Top Left)
                  Positioned(
                    top: 10,
                    left: 10,
                    right: 60,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2)),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _geocoding ? Icons.hourglass_top_rounded : Icons.touch_app_rounded,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _geocoding ? 'Detecting address...' : 'Tap map to place pin',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.ink),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Locate Me button (Bottom Right)
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: FloatingActionButton.small(
                      heroTag: 'map_locate_me',
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      elevation: 4,
                      onPressed: _locating ? null : () => _useCurrentLocation(),
                      child: _locating
                          ? const RtLoader.button(color: AppColors.primary, size: 16)
                          : const Icon(Icons.my_location_rounded, size: 20),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Quick Location Action Bar (GPS only)
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                backgroundColor: AppColors.primarySoft,
                side: const BorderSide(color: AppColors.primaryBorder),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                minimumSize: const Size.fromHeight(46),
              ),
              onPressed: _locating ? null : () => _useCurrentLocation(),
              icon: _locating
                  ? const RtLoader.button(color: AppColors.primary, size: 16)
                  : const Icon(Icons.gps_fixed_rounded, size: 18, color: AppColors.primary),
              label: Text(
                _locating ? 'Locating GPS...' : 'Use Current GPS',
                style: const TextStyle(color: AppColors.primary, fontSize: 13.5, fontWeight: FontWeight.w700),
              ),
            ),

            const SizedBox(height: 18),

            // 2. ADDRESS TYPE SELECTION
            const Text(
              'Save Address As',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.grey700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['Home', 'Work', 'Other'].map((t) {
                final selected = _type == t;
                return ChoiceChip(
                  label: Text(t),
                  selected: selected,
                  selectedColor: AppColors.primarySoft,
                  backgroundColor: Colors.white,
                  side: BorderSide(color: selected ? AppColors.primary : const Color(0xFFE2E8F0)),
                  labelStyle: TextStyle(
                    color: selected ? AppColors.primaryDark : AppColors.grey700,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  onSelected: (_) => setState(() => _type = t),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // 3. ADDRESS FORM FIELDS
            TextField(
              controller: _line,
              decoration: const InputDecoration(
                labelText: 'Address line *',
                hintText: 'House / Flat No., Street, Landmark',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _city,
                    decoration: const InputDecoration(
                      labelText: 'City *',
                      hintText: 'City name',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _state,
                    decoration: const InputDecoration(
                      labelText: 'State',
                      hintText: 'State name',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pin,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Pincode *',
                hintText: '6-digit PIN',
              ),
            ),

            if (_err != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary, width: 1.2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _err!,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // 4. SAVE BUTTON
            AppButton(
              label: 'Save Address',
              loading: _busy,
              fullWidth: true,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
