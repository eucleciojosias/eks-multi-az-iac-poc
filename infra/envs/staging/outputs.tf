# Re-expose the module's outputs so `terraform output` works at the env root.
output "region" {
  value = module.platform.region
}

output "cluster_name" {
  value = module.platform.cluster_name
}

output "cluster_endpoint" {
  value = module.platform.cluster_endpoint
}

output "node_group_names" {
  value = module.platform.node_group_names
}
