################################################################################
# Ingress certificate
################################################################################

resource "aws_acm_certificate" "ingress" {
  count = local.create_ingress_record ? 1 : 0

  domain_name       = var.ingress_hostname
  validation_method = "DNS"

  tags = merge(local.tags, { Name = var.ingress_hostname })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "ingress" {
  count = local.create_ingress_record ? 1 : 0

  certificate_arn         = aws_acm_certificate.ingress[0].arn
  validation_record_fqdns = [for r in aws_route53_record.ingress_cert_validation : r.fqdn]
}
