from django.core.exceptions import ValidationError as djangovalidationError
from django.contrib.auth.models import User
from django.db import transaction
from rest_framework import serializers
from .models import Perfil
import re

class PerfilSerializer(serializers.ModelSerializer):
    class Meta:
        model = Perfil
        fields = ['primeiro_nome', 'sobrenome', 'idade']

class UserSerializer(serializers.ModelSerializer):
    perfil = PerfilSerializer(read_only=True)

    senha = serializers.CharField(write_only=True)
    email = serializers.EmailField(required=True)

    primeiro_nome = serializers.CharField(write_only=True, required=True)
    sobrenome = serializers.CharField(write_only=True, required=True)
    idade = serializers.IntegerField(write_only=True, required=True)
    numero = serializers.CharField(write_only=True, required=True)

    class Meta:
        model = User
        fields = [
            'id',
            'username',
            'email',
            'senha',
            'primeiro_nome',
            'sobrenome',
            'idade',
            'numero',
            'perfil'
        ]

    def create(self, validated_data):
        with transaction.atomic():

            senha = validated_data.pop('senha')
            primeiro_nome = validated_data.pop('primeiro_nome')
            sobrenome = validated_data.pop('sobrenome')
            idade = validated_data.pop('idade')
            numero = validated_data.pop('numero')

            user = User(**validated_data)
            user.set_password(senha)
            user.save()

            perfil = Perfil(
                user=user,
                primeiro_nome=primeiro_nome,
                sobrenome=sobrenome,
                idade=idade,
                numero=numero
            )
            try:
                perfil.full_clean()  
                perfil.save()
            except djangovalidationError as e:
                raise serializers.ValidationError(e.message_dict)    

        return user


    '''def to_representation(self, instance):
        rep = super().to_representation(instance)
        if hasattr(instance, 'perfil'):
            rep['primeiro_nome'] = instance.perfil.primeiro_nome
            rep['sobrenome'] = instance.perfil.sobrenome
            rep['idade'] = instance.perfil.idade
        return rep'''
        
