from rest_framework import serializers
from .models import Trip, TripMember


class TripMemberSerializer(serializers.ModelSerializer):
    class Meta:
        model = TripMember
        fields = [
            'member_id', 'display_name', 'avatar', 'color',
            'lat', 'lng', 'last_seen', 'is_active', 'joined_at'
        ]
        read_only_fields = ['member_id', 'last_seen', 'joined_at']


class TripSerializer(serializers.ModelSerializer):
    members = TripMemberSerializer(many=True, read_only=True)
    member_count = serializers.SerializerMethodField()

    class Meta:
        model = Trip
        fields = ['code', 'created_at', 'expires_at', 'is_active', 'members', 'member_count']

    def get_member_count(self, obj):
        return obj.members.filter(is_active=True).count()


class CreateTripSerializer(serializers.Serializer):
    display_name = serializers.CharField(max_length=50)
    avatar = serializers.CharField(max_length=20, default='bike')
    color = serializers.CharField(max_length=7, default='#FF6B35')


class JoinTripSerializer(serializers.Serializer):
    display_name = serializers.CharField(max_length=50)
    avatar = serializers.CharField(max_length=20, default='bike')
    color = serializers.CharField(max_length=7, default='#FF6B35')
    member_id = serializers.UUIDField(required=False)  # for rejoining
