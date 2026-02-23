from django.db import models
from django.contrib.auth.models import User
from django.core.validators import RegexValidator, MinValueValidator, MaxValueValidator


class Perfil(models.Model):
    user = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        related_name='perfil'
    )

    telefone_validator = RegexValidator(
        regex=r'^(\+55)?[1-9]{2}9\d{8}$',
        message="Número inválido. Use formato brasileiro válido."
    )

    primeiro_nome = models.CharField(max_length=20, null=True, blank=True)
    sobrenome = models.CharField(max_length=40, null=True, blank=True)

    idade = models.PositiveIntegerField(
        validators=[
            MinValueValidator(18),
            MaxValueValidator(80)
        ]
    )

    numero = models.CharField(
        max_length=14,
        validators=[telefone_validator]
    )

    def __str__(self):
        return f"{self.primeiro_nome} {self.sobrenome} - ({self.idade} anos)"