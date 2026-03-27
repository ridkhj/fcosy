from django.db import models

class Transacao(models.Model):

    TIPOS = (
        ('ganho', 'Ganho'),
        ('despesa', 'Despesa'),
    )

    conta = models.ForeignKey("accounts.Conta", on_delete=models.CASCADE, related_name="transacoes")
    tipo = models.CharField(max_length=10, choices=TIPOS)
    valor = models.DecimalField(max_digits=10, decimal_places=2)
    descricao = models.CharField(max_length=255)
    data_transacao = models.DateField()
    criado_em = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.tipo} - {self.valor}"