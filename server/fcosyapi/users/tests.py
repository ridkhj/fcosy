from django.urls import reverse
from rest_framework.test import APITestCase
from rest_framework import status
from django.contrib.auth.models import User
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


    def teste_idade_invalida(self):
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

    def test_username_dublicado(self):
        self.client.post(self.url, self.valid_data, format='json')
        response = self.client.post(self.url, self.valid_data, format='json')   

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)