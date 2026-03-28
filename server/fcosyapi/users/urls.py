from django.urls import path
from .views import RegisterView, UserListView, UserMeView
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView

urlpatterns = [
    path('registro/', RegisterView.as_view(), name='register'),
    path('login/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('users/', UserListView.as_view(), name='user-list'),
    path('users/me/', UserMeView.as_view(), name='user-me'),
]
