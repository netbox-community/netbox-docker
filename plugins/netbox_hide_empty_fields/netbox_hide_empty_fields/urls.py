"""
URLs do plugin.
"""
from django.urls import path

from . import views

app_name = 'netbox_hide_empty_fields'

urlpatterns = [
    path('settings/', views.UserSettingsView.as_view(), name='settings'),
]
