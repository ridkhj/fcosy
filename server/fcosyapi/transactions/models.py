from django.db import models
from django.contrib.auth import get_user_model

User = get_user_model()

class Transacao(models.Model):

    TIPOS = (
        ('ganho', 'Ganho'),
        ('despesa', 'Despesa'),
    )

    usuario = models.ForeignKey(User, on_delete=models.CASCADE)
    tipo = models.CharField(max_length=10, choices=TIPOS)
    valor = models.DecimalField(max_digits=10, decimal_places=2)
    descricao = models.CharField(max_length=255)
    data = models.DateField()

    def __str__(self):
        return f"{self.tipo} - {self.valor}"