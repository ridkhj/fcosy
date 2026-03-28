# Generated manually to align the current Transacao model with the historical schema.

import django.db.models.deletion
import django.utils.timezone
from django.db import migrations, models


def migrate_usuario_to_conta(apps, schema_editor):
    Transacao = apps.get_model("transactions", "Transacao")
    Conta = apps.get_model("accounts", "Conta")

    for transacao in Transacao.objects.all():
        conta, _ = Conta.objects.get_or_create(
            usuario_id=transacao.usuario_id,
            nome="Conta migrada",
            defaults={
                "tipo": "corrente",
                "saldo": 0,
            },
        )
        transacao.conta_id = conta.id
        transacao.save(update_fields=["conta"])


class Migration(migrations.Migration):

    dependencies = [
        ("accounts", "0002_alter_conta_saldo"),
        ("transactions", "0001_initial"),
    ]

    operations = [
        migrations.AddField(
            model_name="transacao",
            name="conta",
            field=models.ForeignKey(
                blank=True,
                null=True,
                on_delete=django.db.models.deletion.CASCADE,
                related_name="transacoes",
                to="accounts.conta",
            ),
        ),
        migrations.RenameField(
            model_name="transacao",
            old_name="data",
            new_name="data_transacao",
        ),
        migrations.AddField(
            model_name="transacao",
            name="criado_em",
            field=models.DateTimeField(
                auto_now_add=True,
                default=django.utils.timezone.now,
            ),
            preserve_default=False,
        ),
        migrations.RunPython(migrate_usuario_to_conta, migrations.RunPython.noop),
        migrations.AlterField(
            model_name="transacao",
            name="conta",
            field=models.ForeignKey(
                on_delete=django.db.models.deletion.CASCADE,
                related_name="transacoes",
                to="accounts.conta",
            ),
        ),
        migrations.RemoveField(
            model_name="transacao",
            name="usuario",
        ),
    ]
