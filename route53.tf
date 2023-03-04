resource "aws_route53_record" "root" {
  count = var.has-domain ? 1 : 0
  zone_id = var.route53-zone
  name    = var.domain
  type    = "A"

  alias {
    name = var.has-domain ? aws_lb.projeto-elb[0].dns_name : null
    zone_id = var.has-domain ? aws_lb.projeto-elb[0].zone_id : null
    evaluate_target_health = true
  }
}
