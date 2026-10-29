import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/theme.dart';
import '../../core/routes.dart';
import '../../core/api_service.dart';
import '../../core/storage_service.dart';
import '../../core/websocket_service.dart';
import '../../core/location_service.dart';
import '../../shared/models/trip_member.dart';
import '../../shared/widgets/banner_ad_widget.dart';
import '../../shared/widgets/member_list_sheet.dart';

class LiveMapScreen extends StatefulWidget {
  final LiveMapArgs args;
  const LiveMapScreen({super.key, required this.args});

  @override
  State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen> with WidgetsBindingObserver {
  GoogleMapController? _mapController;
  final _wsService = WebSocketService();
  final _locationService = LocationService();

  // Map of memberId → TripMember (other riders)
  final Map<String, TripMember> _members = {};
  final Map<String, Marker> _markers = {};

  Position? _myPosition;
  bool _isFollowingMe = true;

  // Light clean map style
  static const String _lightMapStyle = '''
  [
    {"featureType":"poi","stylers":[{"visibility":"off"}]},
    {"featureType":"transit","stylers":[{"visibility":"off"}]},
    {"featureType":"road","elementType":"labels.icon","stylers":[{"visibility":"off"}]}
  ]
  ''';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initServices();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _wsService.disconnect();
    _locationService.stopTracking();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initServices() async {
    // Get initial position
    final pos = await LocationService.getCurrentPosition();
    if (pos != null && mounted) {
      setState(() => _myPosition = pos);
      _animateCameraTo(pos.latitude, pos.longitude);
    }

    // Start location tracking
    await _locationService.startTracking(
      onUpdate: (lat, lng) {
        if (mounted) {
          setState(() => _myPosition = Position(
                latitude: lat,
                longitude: lng,
                timestamp: DateTime.now(),
                accuracy: 0,
                altitude: 0,
                altitudeAccuracy: 0,
                heading: 0,
                headingAccuracy: 0,
                speed: 0,
                speedAccuracy: 0,
              ));
          if (_isFollowingMe) _animateCameraTo(lat, lng);
        }
        _wsService.sendLocation(lat, lng);
      },
    );

    // Connect WebSocket
    _setupWebSocket();
    _wsService.connect(widget.args.tripCode, widget.args.member.memberId);
  }

  void _setupWebSocket() {
    _wsService.onMembersList = (members) {
      for (final m in members) {
        _updateMember(m);
      }
    };

    _wsService.onMemberUpdated = (member) {
      if (member.memberId != widget.args.member.memberId) {
        _updateMember(member);
      }
    };

    _wsService.onMemberJoined = (member) {
      if (member.memberId != widget.args.member.memberId) {
        _updateMember(member);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${member.displayName} joined the trip!'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    };

    _wsService.onMemberLeft = (memberId) {
      if (mounted) {
        setState(() {
          final name = _members[memberId]?.displayName ?? 'Someone';
          _members.remove(memberId);
          _markers.remove(memberId);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$name left the trip'),
              duration: const Duration(seconds: 2),
            ),
          );
        });
      }
    };

    _wsService.onConnectionStateChanged = (state) {
      if (mounted) setState(() {});
    };
  }

  void _updateMember(TripMember member) async {
    if (!mounted) return;
    setState(() {
      _members[member.memberId] = member;
    });
    if (member.lat != null && member.lng != null) {
      await _updateMarker(member);
    }
  }

  Future<void> _updateMarker(TripMember member) async {
    if (!mounted) return;
    final color = Color(
      int.parse('FF${member.color.replaceFirst('#', '')}', radix: 16),
    );

    final icon = await _createMarkerIcon(
      member.displayName,
      color,
    );

    final marker = Marker(
      markerId: MarkerId(member.memberId),
      position: LatLng(member.lat!, member.lng!),
      icon: icon,
      infoWindow: InfoWindow(title: member.displayName),
    );

    if (mounted) {
      setState(() {
        _markers[member.memberId] = marker;
      });
    }
  }

  Future<BitmapDescriptor> _createMarkerIcon(String name, Color color) async {
    const size = 120.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Circle background
    final paint = Paint()..color = color;
    canvas.drawCircle(const Offset(size / 2, size / 2), 44, paint);

    // White border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(const Offset(size / 2, size / 2), 44, borderPaint);

    // Initial letter
    final initial = name.isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    final initialPainter = TextPainter(
      text: TextSpan(
        text: initial,
        style: const TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    initialPainter.layout();
    initialPainter.paint(
      canvas,
      Offset(
        size / 2 - initialPainter.width / 2,
        size / 2 - initialPainter.height / 2 - 6,
      ),
    );

    // Name label below circle
    final namePainter = TextPainter(
      text: TextSpan(
        text: name.length > 10 ? '${name.substring(0, 9)}…' : name,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    namePainter.layout(maxWidth: size);
    namePainter.paint(
      canvas,
      Offset(size / 2 - namePainter.width / 2, size / 2 + 30),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    return BitmapDescriptor.bytes(bytes);
  }

  void _animateCameraTo(double lat, double lng) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(LatLng(lat, lng)),
    );
  }

  void _centerOnMe() {
    if (_myPosition != null) {
      _animateCameraTo(_myPosition!.latitude, _myPosition!.longitude);
      setState(() => _isFollowingMe = true);
    }
  }

  Future<void> _confirmLeave() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Leave Trip?',
          style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'You will be removed from the map and your crew won\'t see you anymore.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Stay', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      _wsService.disconnect();
      _locationService.stopTracking();
      await ApiService.leaveTrip(
        code: widget.args.tripCode,
        memberId: widget.args.member.memberId,
      );
      await StorageService.clearTrip();
      if (mounted) Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = _wsService.state == WsConnectionState.connected;
    final memberCount = _members.length + 1; // +1 for self

    return Scaffold(
      body: Stack(
        children: [
          // ── Google Map ──────────────────────────────────────────────────
          GoogleMap(
            style: _lightMapStyle,
            onMapCreated: (controller) async {
              _mapController = controller;
              if (_myPosition != null) {
                _animateCameraTo(_myPosition!.latitude, _myPosition!.longitude);
              }
            },
            initialCameraPosition: CameraPosition(
              target: _myPosition != null
                  ? LatLng(_myPosition!.latitude, _myPosition!.longitude)
                  : const LatLng(20.5937, 78.9629), // India center default
              zoom: 15,
            ),
            markers: Set<Marker>.from(_markers.values),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            onCameraMove: (_) => setState(() => _isFollowingMe = false),
          ),

          // ── Top Bar ─────────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Trip code badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.surface.withAlpha(245),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(77),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isConnected ? Icons.wifi : Icons.wifi_off,
                          color: isConnected ? AppTheme.success : AppTheme.error,
                          size: 14,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.args.tripCode,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            color: AppTheme.accent,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.accentDim,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$memberCount',
                            style: const TextStyle(
                              color: AppTheme.accent,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Leave button
                  GestureDetector(
                    onTap: _confirmLeave,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.error.withAlpha(38),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.error.withAlpha(128)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(77),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.exit_to_app, color: AppTheme.error, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom Sheet: Members list + Banner Ad ───────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MemberListSheet(
                  myMember: widget.args.member,
                  members: _members.values.toList(),
                ),
                const BannerAdWidget(),
              ],
            ),
          ),

          // ── FAB: Center on me ───────────────────────────────────────────
          Positioned(
            right: 16,
            bottom: 180,
            child: FloatingActionButton(
              onPressed: _centerOnMe,
              backgroundColor: _isFollowingMe ? AppTheme.accent : AppTheme.surface,
              elevation: 4,
              child: Icon(
                Icons.my_location,
                color: _isFollowingMe ? Colors.white : AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
