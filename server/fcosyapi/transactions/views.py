from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated
from .models import Transacao
from .serializers import TransacaoSerializer


class TransacaoViewSet(viewsets.ModelViewSet):

    queryset = Transacao.objects.all()
    serializer_class = TransacaoSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        queryset = Transacao.objects.filter(conta__usuario=self.request.user).select_related("conta")

        data_inicio = self.request.query_params.get("data_inicio")
        data_fim = self.request.query_params.get("data_fim")
        conta = self.request.query_params.get("conta")
        tipo = self.request.query_params.get("tipo")

        if data_inicio:
            queryset = queryset.filter(data_transacao__gte=data_inicio)

        if data_fim:
            queryset = queryset.filter(data_transacao__lte=data_fim)

        if conta:
            queryset = queryset.filter(conta_id=conta)

        if tipo:
            queryset = queryset.filter(tipo=tipo)

        return queryset

    def perform_create(self, serializer):
        serializer.save()
