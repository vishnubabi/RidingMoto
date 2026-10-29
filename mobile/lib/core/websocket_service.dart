import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../shared/models/trip_member.dart';
import 'constants.dart';

enum WsConnectionState { disconnected, connecting, connected, error }

class WebSocketService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  WsConnectionState _state = WsConnectionState.disconnected;
  WsConnectionState get state => _state;

  // Callbacks
  void Function(TripMember member)? onMemberUpdated;
  void Function(TripMember member)? onMemberJoined;
  void Function(String memberId)? onMemberLeft;
  void Function(List<TripMember> members)? onMembersList;
  void Function(WsConnectionState state)? onConnectionStateChanged;

  void connect(String tripCode, String memberId) {
    _updateState(WsConnectionState.connecting);
    final url = kWsTripUrl(tripCode, memberId);

    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      _updateState(WsConnectionState.connected);

      _subscription = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
      );
    } catch (e) {
      _updateState(WsConnectionState.error);
    }
  }

  void sendLocation(double lat, double lng) {
    if (_state != WsConnectionState.connected) return;
    _send({
      'type': 'location_update',
      'lat': lat,
      'lng': lng,
    });
  }

  void disconnect() {
    _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
    _updateState(WsConnectionState.disconnected);
  }

  void _send(Map<String, dynamic> data) {
    try {
      _channel?.sink.add(jsonEncode(data));
    } catch (_) {}
  }

  void _onMessage(dynamic raw) {
    try {
      final data = jsonDecode(raw as String) as Map<String, dynamic>;
      final type = data['type'] as String?;

      switch (type) {
        case 'members_list':
          final list = (data['members'] as List)
              .map((m) => TripMember.fromJson(m as Map<String, dynamic>))
              .toList();
          onMembersList?.call(list);

        case 'member_update':
          final member = TripMember(
            memberId: data['member_id'] as String,
            displayName: data['display_name'] as String,
            avatar: data['avatar'] as String,
            color: data['color'] as String,
            lat: (data['lat'] as num?)?.toDouble(),
            lng: (data['lng'] as num?)?.toDouble(),
          );
          onMemberUpdated?.call(member);

        case 'member_joined':
          final member = TripMember(
            memberId: data['member_id'] as String,
            displayName: data['display_name'] as String,
            avatar: data['avatar'] as String,
            color: data['color'] as String,
            lat: (data['lat'] as num?)?.toDouble(),
            lng: (data['lng'] as num?)?.toDouble(),
          );
          onMemberJoined?.call(member);

        case 'member_left':
          onMemberLeft?.call(data['member_id'] as String);
      }
    } catch (_) {}
  }

  void _onError(Object error) {
    _updateState(WsConnectionState.error);
  }

  void _onDone() {
    _updateState(WsConnectionState.disconnected);
  }

  void _updateState(WsConnectionState newState) {
    _state = newState;
    onConnectionStateChanged?.call(newState);
  }
}
