from django.contrib import admin
from .models import Trip, TripMember


@admin.register(Trip)
class TripAdmin(admin.ModelAdmin):
    list_display = ['code', 'created_at', 'expires_at', 'is_active', 'member_count']
    list_filter = ['is_active']
    search_fields = ['code']

    def member_count(self, obj):
        return obj.members.filter(is_active=True).count()
    member_count.short_description = 'Active Members'


@admin.register(TripMember)
class TripMemberAdmin(admin.ModelAdmin):
    list_display = ['display_name', 'trip', 'avatar', 'color', 'lat', 'lng', 'is_active', 'last_seen']
    list_filter = ['is_active', 'avatar']
    search_fields = ['display_name', 'trip__code']
