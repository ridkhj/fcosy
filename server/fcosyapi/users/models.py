from django.db import models
from django.contrib.auth.models import User


class Perfil(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='profile')
    primeiro_nome = models.CharField("Primeiro Nome", max_length=20)
    sobrenome = models.CharField("Sobrenome", max_length=40)

    def __str__(self):
        return f"{self.primeiro_nome} {self.sobrenome}"