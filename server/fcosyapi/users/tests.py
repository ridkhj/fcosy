from rest_framework.test import APITestCase
from rest_framework import status
from django.contrib.auth.models import User
from .models import Perfil


class RegistroTestCase(APITestCase):
    def setUp(self):
        self.url = "/api/registro/"

        self.valid_data = {
            "username": "testuser",
            "email": "testuser@example.com",
            "senha": "testpassword123",
            "primeiro_nome": "Test",
            "sobrenome": "User",
            "idade": 25,
            "numero": "+5511987654321"
        }

    def test_registro_sucesso(self):
        response = self.client.post(self.url, self.valid_data, format='json')

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(User.objects.count(), 1)
        self.assertEqual(Perfil.objects.count(), 1)


    def test_idade_invalida(self):
        data = self.valid_data.copy()
        data["idade"] = -1

        response = self.client.post(self.url, data, format='json')

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
    
    def test_telefone_invalido(self):
        data = self.valid_data.copy()
        data["numero"] = "12345"

        response = self.client.post(self.url, data, format='json')

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
    
    def test_email_invalido(self):
        data = self.valid_data.copy()
        data["email"] = "emailinvalido"

        response = self.client.post(self.url, data, format='json')

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_username_duplicado(self):
        self.client.post(self.url, self.valid_data, format='json')
        response = self.client.post(self.url, self.valid_data, format='json')

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)


class UserMeViewTestCase(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            username="userme",
            email="userme@example.com",
            password="123456"
        )

        Perfil.objects.create(
            user=self.user,
            primeiro_nome="User",
            sobrenome="Me",
            idade=25,
            numero="+5511987654321"
        )

        self.other_user = User.objects.create_user(
            username="otheruser",
            email="other@example.com",
            password="123456"
        )

        Perfil.objects.create(
            user=self.other_user,
            primeiro_nome="Other",
            sobrenome="User",
            idade=30,
            numero="+5511987654322"
        )

        login = self.client.post("/api/login/", {
            "username": "userme",
            "password": "123456"
        })

        token = login.data["access"]
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {token}")

    def test_retorna_usuario_autenticado_em_users_me(self):
        response = self.client.get("/api/users/me/")

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["id"], self.user.id)
        self.assertEqual(response.data["username"], self.user.username)

    def test_rota_antiga_por_pk_nao_existe_mais(self):
        response = self.client.get(f"/api/users/{self.other_user.id}/")

        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)
