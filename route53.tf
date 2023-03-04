resource "aws_route53_record" "www" {
  count = var.create-domain-www ? 1 : 0
  zone_id = var.route53-zone
  name    = "www"
  type    = "A"

  alias {
    name                   = aws_lb.projeto-elb.dns_name
    zone_id                = aws_lb.projeto-elb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "root" {
  count = var.has-domain ? 1 : 0
  zone_id = var.route53-zone
  name    = var.domain
  type    = "A"

  alias {
    name                   = aws_lb.projeto-elb.dns_name
    zone_id                = aws_lb.projeto-elb.zone_id
    evaluate_target_health = true
  }
}
