from rest_framework.test import APITestCase
from rest_framework import status
from django.contrib.auth import get_user_model
from django.utils import timezone
from decimal import Decimal
from .models import Conta
from transactions.models import Transacao

User = get_user_model()

class ContaTestCase(APITestCase):

    def setUp(self):

        self.user = User.objects.create_user(
            username="testuser",
            password="123456"
        )

        self.client.force_authenticate(user=self.user)

        self.url = "/api/contas/"
        self.today = timezone.localdate()
        self.current_month = self.today.strftime("%Y-%m")
        if self.today.month == 1:
            previous_year = self.today.year - 1
            previous_month = 12
        else:
            previous_year = self.today.year
            previous_month = self.today.month - 1
        self.previous_month = f"{previous_year:04d}-{previous_month:02d}"

    def test_criar_conta(self):

        data = {
            "nome": "Nubank",
            "tipo": "credito"
        }

        response = self.client.post(self.url, data, format="json")

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(Conta.objects.count(), 1)

    def test_listar_contas(self):

        Conta.objects.create(
            usuario=self.user,
            nome="Conta Corrente",
            tipo="corrente"
        )

        response = self.client.get(self.url)

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(set(response.data[0].keys()), {"id", "nome", "tipo", "saldo"})

    def test_detalhar_conta_retorna_transacoes_do_mes_atual_e_saldo_mes(self):

        conta = Conta.objects.create(
            usuario=self.user,
            nome="Conta Corrente",
            tipo="corrente",
            saldo="500.00"
        )

        Transacao.objects.create(
            conta=conta,
            tipo="ganho",
            valor="100.00",
            descricao="salario",
            data_transacao=f"{self.current_month}-10"
        )

        Transacao.objects.create(
            conta=conta,
            tipo="despesa",
            valor="40.00",
            descricao="mercado",
            data_transacao=f"{self.current_month}-15"
        )

        Transacao.objects.create(
            conta=conta,
            tipo="ganho",
            valor="70.00",
            descricao="mes anterior",
            data_transacao=f"{self.previous_month}-10"
        )

        response = self.client.get(f"{self.url}{conta.id}/")

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["mes_referencia"], self.current_month)
        self.assertEqual(response.data["saldo_mes"], Decimal("60"))
        self.assertEqual(len(response.data["transacoes_mes"]), 2)
        self.assertEqual(response.data["saldo"], "630.00")

    def test_detalhar_conta_permite_consultar_mes_anterior(self):

        conta = Conta.objects.create(
            usuario=self.user,
            nome="Conta Corrente",
            tipo="corrente"
        )

        Transacao.objects.create(
            conta=conta,
            tipo="ganho",
            valor="120.00",
            descricao="fevereiro",
            data_transacao=f"{self.previous_month}-05"
        )

        Transacao.objects.create(
            conta=conta,
            tipo="despesa",
            valor="20.00",
            descricao="marco",
            data_transacao=f"{self.current_month}-05"
        )

        response = self.client.get(f"{self.url}{conta.id}/?mes={self.previous_month}")

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["mes_referencia"], self.previous_month)
        self.assertEqual(response.data["saldo_mes"], Decimal("120"))
        self.assertEqual(len(response.data["transacoes_mes"]), 1)
        self.assertEqual(response.data["transacoes_mes"][0]["descricao"], "fevereiro")

    def test_detalhar_conta_com_mes_invalido_retorna_400(self):

        conta = Conta.objects.create(
            usuario=self.user,
            nome="Conta Corrente",
            tipo="corrente"
        )

        response = self.client.get(f"{self.url}{conta.id}/?mes=2026-13")

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("mes", response.data)

    def test_usuario_nao_ve_conta_de_outro(self):

        outro = User.objects.create_user(
            username="outro",
            password="123456"
        )

        Conta.objects.create(
            usuario=outro,
            nome="Conta de outro",
            tipo="corrente"
        )

        response = self.client.get(self.url)

        self.assertEqual(len(response.data), 0)

    def test_usuario_nao_atualiza_conta_de_outro(self):

        outro = User.objects.create_user(
            username="outro_update",
            password="123456"
        )

        conta_outro = Conta.objects.create(
            usuario=outro,
            nome="Conta de outro",
            tipo="corrente"
        )

        response = self.client.put(
            f"{self.url}{conta_outro.id}/",
            {
                "nome": "Conta alterada",
                "tipo": "credito",
                "saldo": "10.00"
            },
            format="json"
        )

        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

    def test_usuario_nao_edita_parcialmente_conta_de_outro(self):

        outro = User.objects.create_user(
            username="outro_patch",
            password="123456"
        )

        conta_outro = Conta.objects.create(
            usuario=outro,
            nome="Conta de outro",
            tipo="corrente"
        )

        response = self.client.patch(
            f"{self.url}{conta_outro.id}/",
            {
                "nome": "Conta patch"
            },
            format="json"
        )

        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

    def test_usuario_nao_remove_conta_de_outro(self):

        outro = User.objects.create_user(
            username="outro_delete",
            password="123456"
        )

        conta_outro = Conta.objects.create(
            usuario=outro,
            nome="Conta de outro",
            tipo="corrente"
        )

        response = self.client.delete(f"{self.url}{conta_outro.id}/")

        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)
        self.assertTrue(Conta.objects.filter(id=conta_outro.id).exists())
