################################################################################
# App namespaces — one per app repo
################################################################################

# Terraform creates these, not `helm --create-namespace`: the app CD role's
# AmazonEKSEditPolicy is namespace-scoped and can't create namespaces.
resource "kubernetes_namespace_v1" "app" {
  for_each = toset(var.app_namespaces)

  metadata {
    name = each.key
  }

  # Same as the ingress-nginx release: the apply identity needs its
  # cluster-admin access entry before it can talk to the API.
  depends_on = [aws_eks_access_policy_association.cluster_access]
}
