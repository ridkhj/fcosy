# Generated manually to add transaction status without changing current behavior.

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("transactions", "0002_align_transacao_with_accounts"),
    ]

    operations = [
        migrations.AddField(
            model_name="transacao",
            name="status",
            field=models.CharField(
                choices=[("pendente", "Pendente"), ("realizada", "Realizada")],
                default="realizada",
                max_length=10,
            ),
        ),
    ]
