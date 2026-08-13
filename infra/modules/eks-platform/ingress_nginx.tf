################################################################################
# ingress-nginx — the cluster's single entry point
################################################################################

resource "helm_release" "ingress_nginx" {
  count = var.enable_ingress_nginx ? 1 : 0

  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = var.ingress_nginx_chart_version

  namespace        = "ingress-nginx"
  create_namespace = true

  timeout = 600

  values = [yamlencode({
    controller = {
      replicaCount = var.ingress_nginx_replica_count

      service = {
        annotations = {
          "service.beta.kubernetes.io/aws-load-balancer-type"                              = "nlb"
          "service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled" = "true"
        }
      }

      ingressClassResource = {
        default = true
      }

      topologySpreadConstraints = [{
        maxSkew           = 1
        topologyKey       = "topology.kubernetes.io/zone"
        whenUnsatisfiable = "ScheduleAnyway"

        labelSelector = {
          matchLabels = {
            "app.kubernetes.io/name"      = "ingress-nginx"
            "app.kubernetes.io/instance"  = "ingress-nginx"
            "app.kubernetes.io/component" = "controller"
          }
        }
      }]

      resources = {
        requests = {
          cpu    = "100m"
          memory = "128Mi"
        }
      }
    }
  })]

  depends_on = [
    aws_eks_node_group.default,
    aws_eks_addon.core,
    aws_eks_access_policy_association.cluster_access,
  ]
}
