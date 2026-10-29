from django.utils import timezone
from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from .models import Trip, TripMember
from .serializers import (
    TripSerializer, TripMemberSerializer,
    CreateTripSerializer, JoinTripSerializer
)


@api_view(['POST'])
def create_trip(request):
    """Create a new trip. Returns trip code and the creator's member info."""
    serializer = CreateTripSerializer(data=request.data)
    if not serializer.is_valid():
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    data = serializer.validated_data

    # Create trip
    trip = Trip.objects.create()

    # Create the trip creator as first member
    member = TripMember.objects.create(
        trip=trip,
        display_name=data['display_name'],
        avatar=data.get('avatar', 'bike'),
        color=data.get('color', '#FF6B35'),
    )

    return Response({
        'trip_code': trip.code,
        'expires_at': trip.expires_at,
        'member': TripMemberSerializer(member).data,
    }, status=status.HTTP_201_CREATED)


@api_view(['POST'])
def join_trip(request, code):
    """Join an existing trip by code."""
    try:
        trip = Trip.objects.get(code=code.upper(), is_active=True)
    except Trip.DoesNotExist:
        return Response(
            {'error': 'Trip not found or has ended.'},
            status=status.HTTP_404_NOT_FOUND
        )

    if trip.is_expired():
        trip.is_active = False
        trip.save()
        return Response(
            {'error': 'This trip has expired.'},
            status=status.HTTP_410_GONE
        )

    serializer = JoinTripSerializer(data=request.data)
    if not serializer.is_valid():
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    data = serializer.validated_data

    # Check if member is rejoining (member_id provided)
    member_id = data.get('member_id')
    if member_id:
        try:
            member = TripMember.objects.get(trip=trip, member_id=member_id)
            member.is_active = True
            member.display_name = data['display_name']
            member.avatar = data.get('avatar', member.avatar)
            member.color = data.get('color', member.color)
            member.save()
            return Response({
                'trip_code': trip.code,
                'expires_at': trip.expires_at,
                'member': TripMemberSerializer(member).data,
                'rejoined': True,
            })
        except TripMember.DoesNotExist:
            pass  # fall through to create new member

    # Create new member
    member = TripMember.objects.create(
        trip=trip,
        display_name=data['display_name'],
        avatar=data.get('avatar', 'bike'),
        color=data.get('color', '#FF6B35'),
    )

    return Response({
        'trip_code': trip.code,
        'expires_at': trip.expires_at,
        'member': TripMemberSerializer(member).data,
        'rejoined': False,
    }, status=status.HTTP_201_CREATED)


@api_view(['GET'])
def get_members(request, code):
    """Get all active members of a trip."""
    try:
        trip = Trip.objects.get(code=code.upper(), is_active=True)
    except Trip.DoesNotExist:
        return Response(
            {'error': 'Trip not found.'},
            status=status.HTTP_404_NOT_FOUND
        )

    members = trip.members.filter(is_active=True)
    return Response({
        'trip_code': trip.code,
        'expires_at': trip.expires_at,
        'members': TripMemberSerializer(members, many=True).data,
    })


@api_view(['POST'])
def leave_trip(request, code):
    """Mark a member as inactive (leave trip)."""
    member_id = request.data.get('member_id')
    if not member_id:
        return Response({'error': 'member_id required.'}, status=status.HTTP_400_BAD_REQUEST)

    try:
        trip = Trip.objects.get(code=code.upper())
        member = TripMember.objects.get(trip=trip, member_id=member_id)
        member.is_active = False
        member.save()
        return Response({'status': 'left', 'member_id': str(member_id)})
    except (Trip.DoesNotExist, TripMember.DoesNotExist):
        return Response({'error': 'Not found.'}, status=status.HTTP_404_NOT_FOUND)


@api_view(['GET'])
def trip_detail(request, code):
    """Get trip detail including all active members."""
    try:
        trip = Trip.objects.get(code=code.upper(), is_active=True)
    except Trip.DoesNotExist:
        return Response({'error': 'Trip not found.'}, status=status.HTTP_404_NOT_FOUND)

    return Response(TripSerializer(trip).data)
