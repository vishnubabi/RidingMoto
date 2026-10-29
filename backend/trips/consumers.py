import json
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.db import database_sync_to_async
from django.utils import timezone


class TripConsumer(AsyncWebsocketConsumer):
    """
    WebSocket consumer for real-time location sharing within a trip.
    
    Each trip has a channel group named: trip_{code}
    Members join/leave this group as they connect/disconnect.
    
    Messages:
      Client → Server: { "type": "location_update", "lat": float, "lng": float }
      Server → All:    { "type": "member_update", "member_id": str, "display_name": str,
                         "avatar": str, "color": str, "lat": float, "lng": float }
      Server → All:    { "type": "member_left", "member_id": str }
      Server → Joining: { "type": "members_list", "members": [...] }
    """

    async def connect(self):
        self.trip_code = self.scope['url_route']['kwargs']['code'].upper()
        self.member_id = self.scope['url_route']['kwargs']['member_id']
        self.group_name = f'trip_{self.trip_code}'

        # Validate trip and member exist
        member = await self.get_member()
        if not member:
            await self.close(code=4004)
            return

        self.member = member

        # Join trip channel group
        await self.channel_layer.group_add(self.group_name, self.channel_name)
        await self.accept()

        # Mark member as active
        await self.set_member_active(True)

        # Send current members list to the newly connected client
        members = await self.get_active_members()
        await self.send(text_data=json.dumps({
            'type': 'members_list',
            'members': members,
        }))

        # Notify others that this member joined
        await self.channel_layer.group_send(
            self.group_name,
            {
                'type': 'member_joined',
                'member_id': self.member_id,
                'display_name': member['display_name'],
                'avatar': member['avatar'],
                'color': member['color'],
                'lat': member['lat'],
                'lng': member['lng'],
            }
        )

    async def disconnect(self, close_code):
        if hasattr(self, 'group_name'):
            # Mark member inactive
            await self.set_member_active(False)

            # Notify others
            await self.channel_layer.group_send(
                self.group_name,
                {
                    'type': 'member_left',
                    'member_id': self.member_id,
                }
            )

            await self.channel_layer.group_discard(self.group_name, self.channel_name)

    async def receive(self, text_data):
        try:
            data = json.loads(text_data)
        except json.JSONDecodeError:
            return

        msg_type = data.get('type')

        if msg_type == 'location_update':
            lat = data.get('lat')
            lng = data.get('lng')

            if lat is None or lng is None:
                return

            # Validate range
            if not (-90 <= lat <= 90) or not (-180 <= lng <= 180):
                return

            # Update DB
            member = await self.update_location(lat, lng)
            if not member:
                return

            # Broadcast to all in trip
            await self.channel_layer.group_send(
                self.group_name,
                {
                    'type': 'member_location',
                    'member_id': self.member_id,
                    'display_name': member['display_name'],
                    'avatar': member['avatar'],
                    'color': member['color'],
                    'lat': lat,
                    'lng': lng,
                }
            )

    # ── Group message handlers ──────────────────────────────────────────────

    async def member_location(self, event):
        """Broadcast location update to all WebSocket clients."""
        await self.send(text_data=json.dumps({
            'type': 'member_update',
            'member_id': event['member_id'],
            'display_name': event['display_name'],
            'avatar': event['avatar'],
            'color': event['color'],
            'lat': event['lat'],
            'lng': event['lng'],
        }))

    async def member_joined(self, event):
        """Notify clients when a new member joins."""
        await self.send(text_data=json.dumps({
            'type': 'member_joined',
            'member_id': event['member_id'],
            'display_name': event['display_name'],
            'avatar': event['avatar'],
            'color': event['color'],
            'lat': event.get('lat'),
            'lng': event.get('lng'),
        }))

    async def member_left(self, event):
        """Notify clients when a member disconnects."""
        await self.send(text_data=json.dumps({
            'type': 'member_left',
            'member_id': event['member_id'],
        }))

    # ── DB helpers ──────────────────────────────────────────────────────────

    @database_sync_to_async
    def get_member(self):
        from .models import TripMember
        try:
            m = TripMember.objects.select_related('trip').get(
                member_id=self.member_id,
                trip__code=self.trip_code,
            )
            return {
                'display_name': m.display_name,
                'avatar': m.avatar,
                'color': m.color,
                'lat': m.lat,
                'lng': m.lng,
            }
        except TripMember.DoesNotExist:
            return None

    @database_sync_to_async
    def set_member_active(self, active: bool):
        from .models import TripMember
        TripMember.objects.filter(member_id=self.member_id).update(is_active=active)

    @database_sync_to_async
    def update_location(self, lat, lng):
        from .models import TripMember
        try:
            m = TripMember.objects.get(member_id=self.member_id)
            m.lat = lat
            m.lng = lng
            m.save(update_fields=['lat', 'lng', 'last_seen'])
            return {
                'display_name': m.display_name,
                'avatar': m.avatar,
                'color': m.color,
            }
        except TripMember.DoesNotExist:
            return None

    @database_sync_to_async
    def get_active_members(self):
        from .models import TripMember
        members = TripMember.objects.filter(
            trip__code=self.trip_code,
            is_active=True,
        ).exclude(member_id=self.member_id)
        return [
            {
                'member_id': str(m.member_id),
                'display_name': m.display_name,
                'avatar': m.avatar,
                'color': m.color,
                'lat': m.lat,
                'lng': m.lng,
            }
            for m in members
        ]
