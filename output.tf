
# Exibindo dados no console após criaçao

output "projeto-id" {
  value = aws_instance.projeto.id
}

output "projeto-dns" {
  value = aws_instance.projeto.public_dns
}

output "projeto-ip" {
  value = aws_instance.projeto.public_ip
}

output "elb-dns" {
  value = var.has-domain ? aws_lb.projeto-elb[0].dns_name : null
}

output "projeto-rds-nome-banco" {
  value = var.rds-nome-banco
}

output "projeto-rds-nome-usuario" {
  value = var.rds-nome-usuario
}

output "projeto-rds-nome-senha" {
  value = var.rds-senha-usuario
}

output "projeto-rds-dns" {
  value = aws_db_instance.projeto-rds.domain
}

output "projeto-rds-host" {
  value = aws_db_instance.projeto-rds.address
}

output "server" {
  value = "http://${aws_instance.projeto.public_dns}/info.php"
}

output "projeto-user-data-script" {
  value = data.template_file.projeto-user-data-script.rendered
}

output "domain" {
  value = var.domain
}
