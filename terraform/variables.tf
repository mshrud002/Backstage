variable "name" {
  description = "Name for all Backstage resources"
  type        = string
  default     = "backstage"
}

variable "namespace" {
  description = "Kubernetes namespace to deploy into"
  type        = string
  default     = "backstage"
}

variable "create_namespace" {
  description = "Whether to create the Kubernetes namespace"
  type        = bool
  default     = true
}

variable "app_title" {
  description = "Backstage application title"
  type        = string
  default     = "Backstage"
}

variable "app_base_url" {
  description = "Public URL for the Backstage instance"
  type        = string
}

variable "organization_name" {
  description = "Organization name displayed in Backstage"
  type        = string
  default     = "My Company"
}

variable "github_org" {
  description = "GitHub organization for catalog discovery"
  type        = string
  default     = "your-org"
}

variable "github_client_id" {
  description = "GitHub OAuth App client ID"
  type        = string
  default     = ""
}

variable "github_client_secret" {
  description = "GitHub OAuth App client secret"
  type        = string
  default     = ""
  sensitive   = true
}

variable "image_repository" {
  description = "Container image repository for Backstage"
  type        = string
}

variable "image_tag" {
  description = "Container image tag"
  type        = string
  default     = "latest"
}

variable "image_pull_policy" {
  description = "Container image pull policy"
  type        = string
  default     = "Always"
}

variable "replicas" {
  description = "Number of Backstage replicas"
  type        = number
  default     = 2
}

variable "service_type" {
  description = "Kubernetes service type"
  type        = string
  default     = "ClusterIP"
}

variable "create_ingress" {
  description = "Whether to create an Ingress resource"
  type        = bool
  default     = false
}

variable "ingress_class_name" {
  description = "Ingress class name"
  type        = string
  default     = ""
}

variable "ingress_hosts" {
  description = "Hostnames for the Ingress"
  type        = list(string)
  default     = []
}

variable "ingress_annotations" {
  description = "Annotations for the Ingress resource"
  type        = map(string)
  default     = {}
}

variable "postgres_user" {
  description = "PostgreSQL username"
  type        = string
  default     = "backstage"
}

variable "postgres_database" {
  description = "PostgreSQL database name"
  type        = string
  default     = "backstage"
}

variable "postgres_storage_size" {
  description = "Persistent volume size for PostgreSQL"
  type        = string
  default     = "8Gi"
}

variable "postgres_resources" {
  description = "Resource requests/limits for PostgreSQL"
  type = object({
    requests = object({
      memory = string
      cpu    = string
    })
    limits = object({
      memory = string
      cpu    = string
    })
  })
  default = {
    requests = {
      memory = "256Mi"
      cpu    = "250m"
    }
    limits = {
      memory = "512Mi"
      cpu    = "500m"
    }
  }
}

variable "resources_requests_memory" {
  description = "Memory request for Backstage container"
  type        = string
  default     = "512Mi"
}

variable "resources_requests_cpu" {
  description = "CPU request for Backstage container"
  type        = string
  default     = "250m"
}

variable "resources_limits_memory" {
  description = "Memory limit for Backstage container"
  type        = string
  default     = "1Gi"
}

variable "resources_limits_cpu" {
  description = "CPU limit for Backstage container"
  type        = string
  default     = "500m"
}
