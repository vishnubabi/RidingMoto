import uuid
import random
import string
from django.db import models
from django.utils import timezone
from datetime import timedelta


def generate_trip_code():
    """Generate a unique 6-character alphanumeric trip code."""
    chars = string.ascii_uppercase + string.digits
    while True:
        code = ''.join(random.choices(chars, k=6))
        if not Trip.objects.filter(code=code).exists():
            return code


class Trip(models.Model):
    code = models.CharField(max_length=6, unique=True, default=generate_trip_code)
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField()
    is_active = models.BooleanField(default=True)

    def save(self, *args, **kwargs):
        if not self.expires_at:
            self.expires_at = timezone.now() + timedelta(hours=24)
        super().save(*args, **kwargs)

    def is_expired(self):
        return timezone.now() > self.expires_at

    def __str__(self):
        return f"Trip {self.code}"

    class Meta:
        ordering = ['-created_at']


class TripMember(models.Model):
    AVATAR_CHOICES = [
        ('bike', '🏍️'),
        ('car', '🚗'),
        ('bicycle', '🚲'),
        ('hiker', '🥾'),
        ('van', '🚐'),
        ('truck', '🛻'),
    ]

    trip = models.ForeignKey(Trip, on_delete=models.CASCADE, related_name='members')
    member_id = models.UUIDField(default=uuid.uuid4, unique=True)
    display_name = models.CharField(max_length=50)
    avatar = models.CharField(max_length=20, default='bike', choices=AVATAR_CHOICES)
    color = models.CharField(max_length=7, default='#FF6B35')  # hex color
    last_seen = models.DateTimeField(auto_now=True)
    lat = models.FloatField(null=True, blank=True)
    lng = models.FloatField(null=True, blank=True)
    is_active = models.BooleanField(default=True)
    joined_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.display_name} in {self.trip.code}"

    class Meta:
        ordering = ['joined_at']
