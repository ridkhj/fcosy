from rest_framework.routers import DefaultRouter
from .views import TransacaoViewSet

router = DefaultRouter()
router.register(r'transacoes', TransacaoViewSet)

urlpatterns = router.urls