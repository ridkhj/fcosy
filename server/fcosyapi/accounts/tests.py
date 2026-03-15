from rest_framework.test import APITestCase
from rest_framework import status
from django.contrib.auth import get_user_model
from .models import Conta

User = get_user_model()

class ContaTestCase(APITestCase):

    def setUp(self):

        self.user = User.objects.create_user(
            username="testuser",
            password="123456"
        )

        self.client.force_authenticate(user=self.user)

        self.url = "/api/contas/"

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