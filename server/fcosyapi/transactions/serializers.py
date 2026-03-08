from rest_framework import serializers
from .models import Transacao

class TransacaoSerializer(serializers.ModelSerializer):

    class Meta:
        model = Transacao
        fields = "__all__"
        read_only_fields = ["usuario"]

    def validate_valor(self, value):
        if value <= 0:
            raise serializers.ValidationError("O valor deve ser positivo.")
        return value