output "namespace" {
  description = "Kubernetes namespace where Backstage is deployed"
  value       = var.namespace
}

output "service_name" {
  description = "Name of the Backstage Kubernetes service"
  value       = kubernetes_service.backstage.metadata[0].name
}

output "deployment_name" {
  description = "Name of the Backstage deployment"
  value       = kubernetes_deployment.backstage.metadata[0].name
}

output "postgres_password" {
  description = "PostgreSQL password (sensitive)"
  value       = random_password.postgres.result
  sensitive   = true
}
