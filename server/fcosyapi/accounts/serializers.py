from decimal import Decimal

from django.db.models import Case, DecimalField, F, Sum, Value, When
from django.db.models.functions import Coalesce
from rest_framework import serializers
from .models import Conta
from transactions.models import Transacao


class ContaWriteSerializer(serializers.ModelSerializer):
    class Meta:
        model = Conta
        fields = ["id", "usuario", "nome", "tipo", "saldo"]
        read_only_fields = ["id", "usuario"]


class ContaListSerializer(serializers.ModelSerializer):
    class Meta:
        model = Conta
        fields = ["id", "nome", "tipo", "saldo"]


class TransacaoMesSerializer(serializers.ModelSerializer):
    class Meta:
        model = Transacao
        fields = ["id", "tipo", "valor", "descricao", "data_transacao", "criado_em"]
        read_only_fields = fields


class ContaDetailSerializer(serializers.ModelSerializer):
    saldo_mes = serializers.SerializerMethodField()
    mes_referencia = serializers.SerializerMethodField()
    transacoes_mes = serializers.SerializerMethodField()

    class Meta:
        model = Conta
        fields = [
            "id",
            "usuario",
            "nome",
            "tipo",
            "saldo",
            "mes_referencia",
            "saldo_mes",
            "transacoes_mes",
        ]
        read_only_fields = fields

    def _get_month_transactions(self, obj):
        month_start = self.context["month_start"]
        month_end = self.context["month_end"]
        return obj.transacoes.filter(
            data_transacao__gte=month_start,
            data_transacao__lte=month_end,
        ).order_by("-data_transacao", "-id")

    def get_mes_referencia(self, obj):
        return self.context["month_reference"]

    def get_saldo_mes(self, obj):
        saldo_mes = self._get_month_transactions(obj).filter(status="realizada").aggregate(
            total=Coalesce(
                Sum(
                    Case(
                        When(tipo="ganho", then=F("valor")),
                        When(tipo="despesa", then=F("valor") * Value(-1)),
                        output_field=DecimalField(max_digits=10, decimal_places=2),
                    )
                ),
                Value(Decimal("0.00")),
                output_field=DecimalField(max_digits=10, decimal_places=2),
            )
        )["total"]
        return saldo_mes

    def get_transacoes_mes(self, obj):
        transacoes = self._get_month_transactions(obj)
        return TransacaoMesSerializer(transacoes, many=True).data
