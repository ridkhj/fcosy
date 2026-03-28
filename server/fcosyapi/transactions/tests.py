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
        self.conta.refresh_from_db()
        self.assertEqual(str(self.conta.saldo), "1000.00")

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

    def test_usuario_nao_cria_transacao_em_conta_de_outro(self):

        outro = User.objects.create_user(
            username="terceiro",
            password="123456"
        )

        conta_outro = Conta.objects.create(
            usuario=outro,
            nome="Conta de Outro",
            tipo="corrente"
        )

        data = self.valid_data.copy()
        data["conta"] = conta_outro.id

        response = self.client.post(self.url, data, format="json")

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(Transacao.objects.count(), 0)

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

    def test_usuario_nao_atualiza_transacao_de_outro(self):

        outro = User.objects.create_user(
            username="outro_update",
            password="123456"
        )

        conta_outro = Conta.objects.create(
            usuario=outro,
            nome="Conta Outro",
            tipo="corrente"
        )

        transacao_outro = Transacao.objects.create(
            conta=conta_outro,
            tipo="ganho",
            valor=500,
            descricao="teste",
            data_transacao="2026-03-01"
        )

        response = self.client.put(
            f"{self.url}{transacao_outro.id}/",
            {
                "conta": conta_outro.id,
                "tipo": "despesa",
                "valor": 100,
                "descricao": "alterada",
                "data_transacao": "2026-03-10"
            },
            format="json"
        )

        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

    def test_usuario_nao_edita_parcialmente_transacao_de_outro(self):

        outro = User.objects.create_user(
            username="outro_patch",
            password="123456"
        )

        conta_outro = Conta.objects.create(
            usuario=outro,
            nome="Conta Outro",
            tipo="corrente"
        )

        transacao_outro = Transacao.objects.create(
            conta=conta_outro,
            tipo="ganho",
            valor=500,
            descricao="teste",
            data_transacao="2026-03-01"
        )

        response = self.client.patch(
            f"{self.url}{transacao_outro.id}/",
            {
                "descricao": "patch"
            },
            format="json"
        )

        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

    def test_usuario_nao_remove_transacao_de_outro(self):

        outro = User.objects.create_user(
            username="outro_delete",
            password="123456"
        )

        conta_outro = Conta.objects.create(
            usuario=outro,
            nome="Conta Outro",
            tipo="corrente"
        )

        transacao_outro = Transacao.objects.create(
            conta=conta_outro,
            tipo="ganho",
            valor=500,
            descricao="teste",
            data_transacao="2026-03-01"
        )

        response = self.client.delete(f"{self.url}{transacao_outro.id}/")

        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)
        self.assertTrue(Transacao.objects.filter(id=transacao_outro.id).exists())

    def test_filtra_transacoes_por_periodo(self):

        Transacao.objects.create(
            conta=self.conta,
            tipo="ganho",
            valor=100,
            descricao="inicio do mes",
            data_transacao="2026-03-01"
        )

        Transacao.objects.create(
            conta=self.conta,
            tipo="ganho",
            valor=200,
            descricao="meio do mes",
            data_transacao="2026-03-15"
        )

        response = self.client.get(f"{self.url}?data_inicio=2026-03-10&data_fim=2026-03-31")

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)

    def test_filtra_transacoes_combinando_periodo_tipo_e_conta(self):

        outra_conta = Conta.objects.create(
            usuario=self.user,
            nome="Conta Poupanca",
            tipo="poupanca"
        )

        Transacao.objects.create(
            conta=self.conta,
            tipo="ganho",
            valor=100,
            descricao="ganho valido",
            data_transacao="2026-03-15"
        )

        Transacao.objects.create(
            conta=self.conta,
            tipo="despesa",
            valor=50,
            descricao="tipo diferente",
            data_transacao="2026-03-15"
        )

        Transacao.objects.create(
            conta=outra_conta,
            tipo="ganho",
            valor=200,
            descricao="conta diferente",
            data_transacao="2026-03-15"
        )

        Transacao.objects.create(
            conta=self.conta,
            tipo="ganho",
            valor=300,
            descricao="fora do periodo",
            data_transacao="2026-04-10"
        )

        response = self.client.get(
            f"{self.url}?data_inicio=2026-03-10&data_fim=2026-03-31&tipo=ganho&conta={self.conta.id}"
        )

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]["descricao"], "ganho valido")

    def test_atualizar_transacao_recalcula_saldo_da_conta(self):

        transacao = Transacao.objects.create(
            conta=self.conta,
            tipo="ganho",
            valor=100,
            descricao="salario",
            data_transacao="2026-03-08"
        )

        response = self.client.put(
            f"{self.url}{transacao.id}/",
            {
                "conta": self.conta.id,
                "tipo": "despesa",
                "valor": 40,
                "descricao": "conta de luz",
                "data_transacao": "2026-03-09"
            },
            format="json"
        )

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.conta.refresh_from_db()
        self.assertEqual(str(self.conta.saldo), "-40.00")

    def test_remover_transacao_reverte_saldo_da_conta(self):

        transacao = Transacao.objects.create(
            conta=self.conta,
            tipo="ganho",
            valor=100,
            descricao="salario",
            data_transacao="2026-03-08"
        )

        response = self.client.delete(f"{self.url}{transacao.id}/")

        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
        self.conta.refresh_from_db()
        self.assertEqual(str(self.conta.saldo), "0.00")

    def test_mover_transacao_para_outra_conta_atualiza_saldos_das_duas(self):

        outra_conta = Conta.objects.create(
            usuario=self.user,
            nome="Conta Investimento",
            tipo="investimento"
        )

        transacao = Transacao.objects.create(
            conta=self.conta,
            tipo="ganho",
            valor=150,
            descricao="aporte",
            data_transacao="2026-03-08"
        )

        response = self.client.patch(
            f"{self.url}{transacao.id}/",
            {
                "conta": outra_conta.id
            },
            format="json"
        )

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.conta.refresh_from_db()
        outra_conta.refresh_from_db()
        self.assertEqual(str(self.conta.saldo), "0.00")
        self.assertEqual(str(outra_conta.saldo), "150.00")
