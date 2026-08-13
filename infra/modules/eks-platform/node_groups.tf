################################################################################
# Launch template
################################################################################

resource "aws_launch_template" "node" {
  name        = "${local.name}-node"
  description = "Managed node group nodes for ${local.name}"

  update_default_version = true

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = var.node_disk_size
      volume_type           = var.node_volume_type
      encrypted             = true
      delete_on_termination = true
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = var.node_imds_hop_limit
  }

  dynamic "tag_specifications" {
    for_each = toset(["instance", "volume", "network-interface"])

    content {
      resource_type = tag_specifications.value
      tags          = merge(local.tags, { Name = "${local.name}-node" })
    }
  }

  tags = merge(local.tags, { Name = "${local.name}-node" })
}

################################################################################
# Node group
################################################################################

resource "aws_eks_node_group" "default" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "default"
  node_role_arn   = aws_iam_role.node.arn

  subnet_ids = [for s in aws_subnet.private : s.id]

  ami_type       = var.node_ami_type
  capacity_type  = var.node_capacity_type
  instance_types = var.node_instance_types

  launch_template {
    id = aws_launch_template.node.id

    version = aws_launch_template.node.latest_version
  }

  scaling_config {
    min_size     = var.node_min_size
    desired_size = var.node_desired_size
    max_size     = var.node_max_size
  }

  update_config {
    max_unavailable = 1
  }

  tags = local.tags

  depends_on = [
    aws_iam_role_policy_attachment.node,
    aws_route.private_nat,
  ]
}
