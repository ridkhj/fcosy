from rest_framework.routers import DefaultRouter
from .views import ContaViewSet

router = DefaultRouter()
router.register(r'contas', ContaViewSet)

urlpatterns = router.urls