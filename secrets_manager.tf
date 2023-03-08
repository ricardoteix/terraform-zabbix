resource "random_string" "random-name" {
  length           = 8
  special          = false
}

resource "aws_secretsmanager_secret" "zabbix-user-secret-key" {
  name = "zabbix-user-${random_string.random-name.result}"
}

resource "aws_secretsmanager_secret_version" "zabbix-user-secret-v1" {
  secret_id     = aws_secretsmanager_secret.zabbix-user-secret-key.id
  # secret_string = "${aws_iam_access_key.zabbix-user-key.id},${aws_iam_access_key.zabbix-user-key.secret}"
  secret_string = jsonencode(
    {
      id = aws_iam_access_key.zabbix-user-key.id,
      secret = aws_iam_access_key.zabbix-user-key.secret,
      zabbix_login = var.zabbix-login,
      zabbix_password = var.zabbix-password,
      zabbix_host = var.has-domain ? var.zabbix-host : "http://${aws_instance.projeto.public_dns}/zabbix/",
      zabbix_client_sg_id = aws_security_group.zabbix_client.id
    }
  )
}