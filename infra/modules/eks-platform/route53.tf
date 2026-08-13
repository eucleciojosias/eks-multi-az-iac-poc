################################################################################
# Ingress DNS
################################################################################

locals {
  create_ingress_record = var.enable_ingress_nginx && var.ingress_hostname != "" && var.route53_zone_name != ""
}

data "aws_route53_zone" "ingress" {
  count = local.create_ingress_record ? 1 : 0

  name         = var.route53_zone_name
  private_zone = false
}

data "aws_lb" "ingress" {
  count = local.create_ingress_record ? 1 : 0

  tags = {
    "kubernetes.io/service-name"                         = "ingress-nginx/ingress-nginx-controller"
    "kubernetes.io/cluster/${aws_eks_cluster.this.name}" = "owned"
  }

  depends_on = [helm_release.ingress_nginx]
}

resource "aws_route53_record" "ingress" {
  count = local.create_ingress_record ? 1 : 0

  zone_id = data.aws_route53_zone.ingress[0].zone_id
  name    = var.ingress_hostname
  type    = "A"

  alias {
    name                   = data.aws_lb.ingress[0].dns_name
    zone_id                = data.aws_lb.ingress[0].zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "ingress_cert_validation" {
  count = local.create_ingress_record ? 1 : 0

  zone_id = data.aws_route53_zone.ingress[0].zone_id
  name    = one(aws_acm_certificate.ingress[0].domain_validation_options).resource_record_name
  type    = one(aws_acm_certificate.ingress[0].domain_validation_options).resource_record_type
  records = [one(aws_acm_certificate.ingress[0].domain_validation_options).resource_record_value]
  ttl     = 60

  allow_overwrite = true
}
