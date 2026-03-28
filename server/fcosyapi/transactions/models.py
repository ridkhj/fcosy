from decimal import Decimal

from django.db import models
from django.db import transaction
from django.db.models import F

class Transacao(models.Model):

    TIPOS = (
        ('ganho', 'Ganho'),
        ('despesa', 'Despesa'),
    )

    STATUS = (
        ('pendente', 'Pendente'),
        ('realizada', 'Realizada'),
    )

    conta = models.ForeignKey("accounts.Conta", on_delete=models.CASCADE, related_name="transacoes")
    tipo = models.CharField(max_length=10, choices=TIPOS)
    status = models.CharField(max_length=10, choices=STATUS, default="realizada")
    valor = models.DecimalField(max_digits=10, decimal_places=2)
    descricao = models.CharField(max_length=255)
    data_transacao = models.DateField()
    criado_em = models.DateTimeField(auto_now_add=True)

    @staticmethod
    def _signed_amount(tipo, valor, status="realizada"):
        if status != "realizada":
            return Decimal("0")
        valor = Decimal(valor)
        if tipo == "ganho":
            return valor
        return -valor

    @staticmethod
    def _adjust_conta_balance(conta_id, amount):
        from accounts.models import Conta

        Conta.objects.filter(id=conta_id).update(saldo=F("saldo") + amount)

    def __str__(self):
        return f"{self.tipo} - {self.valor}"

    def save(self, *args, **kwargs):
        from accounts.models import Conta

        with transaction.atomic():
            previous = None
            involved_conta_ids = {self.conta_id}

            if self.pk:
                previous = Transacao.objects.select_for_update().get(pk=self.pk)
                involved_conta_ids.add(previous.conta_id)

            list(Conta.objects.select_for_update().filter(id__in=involved_conta_ids))

            super().save(*args, **kwargs)

            new_amount = self._signed_amount(self.tipo, self.valor, self.status)

            if previous is None:
                if new_amount != Decimal("0"):
                    self._adjust_conta_balance(self.conta_id, new_amount)
                return

            previous_amount = self._signed_amount(previous.tipo, previous.valor, previous.status)

            if previous.conta_id == self.conta_id:
                delta = new_amount - previous_amount
                if delta != Decimal("0"):
                    self._adjust_conta_balance(self.conta_id, delta)
                return

            self._adjust_conta_balance(previous.conta_id, -previous_amount)
            self._adjust_conta_balance(self.conta_id, new_amount)

    def delete(self, *args, **kwargs):
        from accounts.models import Conta

        with transaction.atomic():
            list(Conta.objects.select_for_update().filter(id=self.conta_id))
            amount = self._signed_amount(self.tipo, self.valor, self.status)
            if amount != Decimal("0"):
                self._adjust_conta_balance(self.conta_id, -amount)
            super().delete(*args, **kwargs)
