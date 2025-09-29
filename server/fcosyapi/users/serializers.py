from rest_framework import serializers
from django.contrib.auth.models import User
from .models import Perfil

class PerfilSerializer(serializers.ModelSerializer):
    class Meta:
        model = Perfil
        fields = ['primeiro_nome', 'sobrenome']

class UserSerializer(serializers.ModelSerializer):
    perfil = PerfilSerializer(read_only=True)
    senha = serializers.CharField(write_only=True)
    primeiro_nome = serializers.CharField(write_only=True, required=True)
    sobrenome = serializers.CharField(write_only=True, required=True)

    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'senha', 'primeiro_nome', 'sobrenome', 'perfil']

    def create(self, validated_data):
        senha = validated_data.pop('senha')
        primeiro_nome = validated_data.pop('primeiro_nome')
        sobrenome = validated_data.pop('sobrenome')

        user = User(**validated_data)
        user.set_password(senha)
        user.save()

        Perfil.objects.create(user=user, primeiro_nome=primeiro_nome, sobrenome=sobrenome)
        return user

    def to_representation(self, instance):
        rep = super().to_representation(instance)
        if hasattr(instance, 'profile'):
            rep['primeiro_nome'] = instance.profile.primeiro_nome
            rep['sobrenome'] = instance.profile.sobrenome
        return rep
