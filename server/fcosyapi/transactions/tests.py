from rest_framework.test import APITestCase
from rest_framework import status
from django.contrib.auth import get_user_model
from accounts.models import Conta
from .models import Transacao

User = get_user_model()

class TransacaoTestCase(APITestCase):

    def setUp(self):

        self.user = User.objects.create_user(
            username="teste",
            password="123456"
        )

        login = self.client.post("/api/login/", {
            "username": "teste",
            "password": "123456"
        })

        token = login.data["access"]

        self.client.credentials(
            HTTP_AUTHORIZATION=f"Bearer {token}"
        )

        self.conta = Conta.objects.create(
            usuario=self.user,
            nome="Conta Corrente",
            tipo="corrente"
        )

        self.url = "/api/transacoes/"

        self.valid_data = {
            "conta": self.conta.id,
            "tipo": "ganho",
            "valor": 1000,
            "descricao": "salario",
            "data_transacao": "2026-03-08"
        }

    def test_criar_transacao(self):

        response = self.client.post(self.url, self.valid_data, format="json")

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(Transacao.objects.count(), 1)

    def test_tipo_invalido(self):

        data = self.valid_data.copy()
        data["tipo"] = "dinheiro"

        response = self.client.post(self.url, data, format="json")

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_valor_negativo(self):

        data = self.valid_data.copy()
        data["valor"] = -100

        response = self.client.post(self.url, data, format="json")

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
    
    def test_usuario_nao_acessa_transacao_de_outro(self):

        outro = User.objects.create_user(
            username="outro",
            password="123456"
        )

        conta_outro = Conta.objects.create(
            usuario=outro,
            nome="Conta Outro",
            tipo="corrente"
        )

        Transacao.objects.create(
            conta=conta_outro,
            tipo="ganho",
            valor=500,
            descricao="teste",
            data_transacao="2026-03-01"
        )

        response = self.client.get(self.url)

        self.assertEqual(len(response.data), 0)