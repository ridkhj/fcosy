from rest_framework import serializers
from .models import Transacao


class TransacaoSerializer(serializers.ModelSerializer):

    class Meta:
        model = Transacao
        fields = "__all__"
        read_only_fields = ["criado_em"]

    def validate_valor(self, value):
        if value <= 0:
            raise serializers.ValidationError("O valor deve ser positivo.")
        return value

    def validate_conta(self, value):
        request = self.context.get("request")

        if request and request.user.is_authenticated and value.usuario_id != request.user.id:
            raise serializers.ValidationError("A conta informada nao pertence ao usuario autenticado.")

        return value
