from django.db import models
from django.contrib.auth import get_user_model

User = get_user_model()

class Conta(models.Model):

    TIPOS = [
        ('corrente', 'Conta Corrente'),
        ('poupanca', 'Conta Poupança'),
        ('investimento', 'Conta de Investimento'),
        ('credito', 'Conta de Crédito'),
    ]

    usuario = models.ForeignKey(User, on_delete=models.CASCADE)
    nome = models.CharField(max_length=100)
    tipo = models.CharField(max_length=20, choices=TIPOS)
    saldo = models.DecimalField(max_digits=10, decimal_places=2, default = 0)
    
    def __str__(self):
        return f"{self.nome} - {self.tipo} - Saldo: {self.saldo}"