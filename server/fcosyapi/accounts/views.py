from datetime import date

from django.utils import timezone
from rest_framework.exceptions import ValidationError
from rest_framework.viewsets import ModelViewSet
from rest_framework.permissions import IsAuthenticated
from .models import Conta
from .serializers import ContaDetailSerializer, ContaListSerializer, ContaWriteSerializer


def get_month_bounds(month_param):
    if month_param:
        try:
            year_str, month_str = month_param.split("-")
            year = int(year_str)
            month = int(month_str)
            month_start = date(year, month, 1)
        except (TypeError, ValueError):
            raise ValidationError({"mes": "Use o formato YYYY-MM."})
    else:
        today = timezone.localdate()
        month_start = date(today.year, today.month, 1)

    if month_start.month == 12:
        next_month_start = date(month_start.year + 1, 1, 1)
    else:
        next_month_start = date(month_start.year, month_start.month + 1, 1)

    month_end = next_month_start.fromordinal(next_month_start.toordinal() - 1)
    month_reference = month_start.strftime("%Y-%m")
    return month_start, month_end, month_reference


class ContaViewSet(ModelViewSet):

    queryset = Conta.objects.all()
    serializer_class = ContaWriteSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Conta.objects.filter(usuario=self.request.user)

    def get_serializer_class(self):
        if self.action == "list":
            return ContaListSerializer
        if self.action == "retrieve":
            return ContaDetailSerializer
        return ContaWriteSerializer

    def get_serializer_context(self):
        context = super().get_serializer_context()
        if self.action == "retrieve":
            month_start, month_end, month_reference = get_month_bounds(
                self.request.query_params.get("mes")
            )
            context.update(
                {
                    "month_start": month_start,
                    "month_end": month_end,
                    "month_reference": month_reference,
                }
            )
        return context

    def perform_create(self, serializer):
        serializer.save(usuario=self.request.user)
