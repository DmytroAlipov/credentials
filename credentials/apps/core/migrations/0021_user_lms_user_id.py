# Generated by Django 2.2.24 on 2021-08-31 17:14

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('core', '0020_last_name'),
    ]

    operations = [
        migrations.AddField(
            model_name='user',
            name='lms_user_id',
            field=models.IntegerField(db_index=True, null=True),
        ),
    ]