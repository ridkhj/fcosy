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
        self.assertEqual(response.data["count"], 1)
        self.assertEqual(len(response.data["results"]), 1)
        self.assertEqual(set(response.data["results"][0].keys()), {"id", "nome", "tipo", "saldo"})

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
            status="realizada",
            valor="100.00",
            descricao="salario",
            data_transacao=f"{self.current_month}-10"
        )

        Transacao.objects.create(
            conta=conta,
            tipo="despesa",
            status="realizada",
            valor="40.00",
            descricao="mercado",
            data_transacao=f"{self.current_month}-15"
        )

        Transacao.objects.create(
            conta=conta,
            tipo="ganho",
            status="pendente",
            valor="70.00",
            descricao="mes anterior",
            data_transacao=f"{self.previous_month}-10"
        )

        response = self.client.get(f"{self.url}{conta.id}/")

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["mes_referencia"], self.current_month)
        self.assertEqual(response.data["saldo_mes"], Decimal("60"))
        self.assertEqual(len(response.data["transacoes_mes"]), 2)
        self.assertEqual(response.data["saldo"], "560.00")

    def test_detalhar_conta_permite_consultar_mes_anterior(self):

        conta = Conta.objects.create(
            usuario=self.user,
            nome="Conta Corrente",
            tipo="corrente"
        )

        Transacao.objects.create(
            conta=conta,
            tipo="ganho",
            status="realizada",
            valor="120.00",
            descricao="fevereiro",
            data_transacao=f"{self.previous_month}-05"
        )

        Transacao.objects.create(
            conta=conta,
            tipo="despesa",
            status="realizada",
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

    def test_saldo_mes_ignora_pendentes_e_transacoes_mes_mostra_todas(self):

        conta = Conta.objects.create(
            usuario=self.user,
            nome="Conta Corrente",
            tipo="corrente"
        )

        Transacao.objects.create(
            conta=conta,
            tipo="ganho",
            status="realizada",
            valor="100.00",
            descricao="ganho realizado",
            data_transacao=f"{self.current_month}-10"
        )

        Transacao.objects.create(
            conta=conta,
            tipo="despesa",
            status="pendente",
            valor="30.00",
            descricao="despesa pendente",
            data_transacao=f"{self.current_month}-11"
        )

        response = self.client.get(f"{self.url}{conta.id}/")

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["saldo_mes"], Decimal("100"))
        self.assertEqual(len(response.data["transacoes_mes"]), 2)

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

        self.assertEqual(response.data["count"], 0)
        self.assertEqual(len(response.data["results"]), 0)

    def test_filtra_contas_por_tipo(self):

        Conta.objects.create(
            usuario=self.user,
            nome="Conta Corrente",
            tipo="corrente"
        )

        Conta.objects.create(
            usuario=self.user,
            nome="Conta Poupanca",
            tipo="poupanca"
        )

        response = self.client.get(f"{self.url}?tipo=poupanca")

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["count"], 1)
        self.assertEqual(response.data["results"][0]["tipo"], "poupanca")

    def test_filtra_contas_por_nome(self):

        Conta.objects.create(
            usuario=self.user,
            nome="Conta Corrente Principal",
            tipo="corrente"
        )

        Conta.objects.create(
            usuario=self.user,
            nome="Reserva",
            tipo="poupanca"
        )

        response = self.client.get(f"{self.url}?nome=Principal")

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["count"], 1)
        self.assertEqual(response.data["results"][0]["nome"], "Conta Corrente Principal")

    def test_ordena_contas_por_nome_desc(self):

        Conta.objects.create(
            usuario=self.user,
            nome="Alpha",
            tipo="corrente"
        )

        Conta.objects.create(
            usuario=self.user,
            nome="Zulu",
            tipo="poupanca"
        )

        response = self.client.get(f"{self.url}?ordering=-nome")

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["results"][0]["nome"], "Zulu")

    def test_paginar_contas_com_page_size(self):

        Conta.objects.create(usuario=self.user, nome="Conta 1", tipo="corrente")
        Conta.objects.create(usuario=self.user, nome="Conta 2", tipo="corrente")
        Conta.objects.create(usuario=self.user, nome="Conta 3", tipo="corrente")

        response = self.client.get(f"{self.url}?page_size=2")

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["count"], 3)
        self.assertEqual(len(response.data["results"]), 2)
        self.assertIsNotNone(response.data["next"])

    def test_tipo_invalido_retorna_400(self):

        response = self.client.get(f"{self.url}?tipo=invalido")

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("tipo", response.data)

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
