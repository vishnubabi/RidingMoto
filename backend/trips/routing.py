from django.urls import re_path
from . import consumers

websocket_urlpatterns = [
    re_path(r'ws/trip/(?P<code>[A-Z0-9]{6})/(?P<member_id>[0-9a-f-]+)/$', consumers.TripConsumer.as_asgi()),
]
