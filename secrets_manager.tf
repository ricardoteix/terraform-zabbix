resource "aws_secretsmanager_secret" "zabbix-user-sercret" {
  name = "zabbix-user-sercret"
}

resource "aws_secretsmanager_secret_version" "zabbix-user-sercret-v1" {
  secret_id     = aws_secretsmanager_secret.zabbix-user-sercret.id
  secret_string = "${aws_iam_access_key.zabbix-user-key.id},${aws_iam_access_key.zabbix-user-key.secret}"
}