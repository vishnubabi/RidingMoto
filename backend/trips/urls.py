from django.urls import path
from . import views

urlpatterns = [
    path('trips/', views.create_trip, name='create_trip'),
    path('trips/<str:code>/', views.trip_detail, name='trip_detail'),
    path('trips/<str:code>/join/', views.join_trip, name='join_trip'),
    path('trips/<str:code>/members/', views.get_members, name='get_members'),
    path('trips/<str:code>/leave/', views.leave_trip, name='leave_trip'),
]
