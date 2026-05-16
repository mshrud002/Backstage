terraform {
  required_version = ">= 1.3"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

locals {
  labels = {
    app       = var.name
    managedBy = "terraform"
  }
}

resource "random_password" "postgres" {
  length  = 24
  special = false
}

resource "kubernetes_namespace" "this" {
  count = var.create_namespace ? 1 : 0
  metadata {
    name = var.namespace
    labels = local.labels
  }
}

resource "kubernetes_secret" "auth" {
  metadata {
    name      = "${var.name}-auth"
    namespace = var.namespace
    labels    = local.labels
  }
  data = {
    githubClientId     = var.github_client_id
    githubClientSecret = var.github_client_secret
  }
}

resource "kubernetes_config_map" "app_config" {
  metadata {
    name      = "${var.name}-config"
    namespace = var.namespace
    labels    = local.labels
  }

  data = {
    "app-config.yaml" = yamlencode({
      app = {
        title   = var.app_title
        baseUrl = var.app_base_url
      }
      organization = {
        name = var.organization_name
      }
      backend = {
        baseUrl = var.app_base_url
        listen = {
          port = 7007
        }
        database = {
          client = "pg"
          connection = {
            host     = "${var.name}-postgresql"
            port     = 5432
            user     = var.postgres_user
            password = random_password.postgres.result
          }
        }
        cors = {
          origin      = var.app_base_url
          methods     = ["GET", "HEAD", "PATCH", "POST", "PUT", "DELETE"]
          credentials = true
        }
        reading = {
          allow = [{ host = "*" }]
        }
      }
      integrations = {
        github = [
          {
            host = "github.com"
            apps = []
          }
        ]
      }
      auth = {
        environment = "production"
        providers = {
          github = {
            production = {
              clientId     = "${AUTH_GITHUB_CLIENT_ID}"
              clientSecret = "${AUTH_GITHUB_CLIENT_SECRET}"
            }
          }
        }
      }
      catalog = {
        import = {
          entityFilename       = "catalog-info.yaml"
          pullRequestBranchName = "backstage-integration"
        }
        rules = [
          { allow = ["Component", "System", "API", "Resource", "Location"] }
        ]
        locations = [
          {
            type = "url"
            target = "https://github.com/${var.github_org}/backstage/blob/main/catalog-info.yaml"
            rules = [
              { allow = ["Component", "System", "API", "Resource", "Location"] }
            ]
          }
        ]
      }
    })
  }
}

resource "helm_release" "backstage" {
  name       = var.name
  namespace  = var.namespace
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "postgresql"
  version    = "12.x.x"

  values = [yamlencode({
    auth = {
      username = var.postgres_user
      password = random_password.postgres.result
      database = var.postgres_database
    }
    primary = {
      persistence = {
        size = var.postgres_storage_size
      }
      resources = var.postgres_resources
    }
  })]

  depends_on = [kubernetes_namespace.this]
}

resource "kubernetes_deployment" "backstage" {
  metadata {
    name      = var.name
    namespace = var.namespace
    labels    = local.labels
  }

  spec {
    replicas = var.replicas

    selector {
      match_labels = {
        app = var.name
      }
    }

    template {
      metadata {
        labels = merge(local.labels, {
          app = var.name
        })
      }

      spec {
        service_account_name = kubernetes_service_account.this.metadata[0].name

        container {
          name              = "backstage"
          image             = "${var.image_repository}:${var.image_tag}"
          image_pull_policy = var.image_pull_policy

          port {
            name           = "http"
            container_port = 7007
            protocol       = "TCP"
          }

          env {
            name  = "NODE_ENV"
            value = "production"
          }
          env {
            name  = "APP_BASE_URL"
            value = var.app_base_url
          }
          env {
            name  = "BACKEND_BASE_URL"
            value = var.app_base_url
          }
          env {
            name  = "POSTGRES_HOST"
            value = "${var.name}-postgresql"
          }
          env {
            name  = "POSTGRES_PORT"
            value = "5432"
          }
          env {
            name  = "POSTGRES_USER"
            value = var.postgres_user
          }
          env {
            name  = "POSTGRES_PASSWORD"
            value = random_password.postgres.result
          }
          env {
            name  = "POSTGRES_DB"
            value = var.postgres_database
          }
          env {
            name = "AUTH_GITHUB_CLIENT_ID"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.auth.metadata[0].name
                key  = "githubClientId"
              }
            }
          }
          env {
            name = "AUTH_GITHUB_CLIENT_SECRET"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.auth.metadata[0].name
                key  = "githubClientSecret"
              }
            }
          }

          volume_mount {
            name       = "config"
            mount_path = "/app/app-config.yaml"
            sub_path   = "app-config.yaml"
            read_only  = true
          }

          resources {
            requests = {
              memory = var.resources_requests_memory
              cpu    = var.resources_requests_cpu
            }
            limits = {
              memory = var.resources_limits_memory
              cpu    = var.resources_limits_cpu
            }
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = "http"
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 5
          }

          readiness_probe {
            http_get {
              path = "/health"
              port = "http"
            }
            initial_delay_seconds = 10
            period_seconds        = 5
            timeout_seconds       = 3
          }
        }

        volume {
          name = "config"
          config_map {
            name = kubernetes_config_map.app_config.metadata[0].name
          }
        }
      }
    }
  }

  depends_on = [helm_release.backstage]
}

resource "kubernetes_service" "backstage" {
  metadata {
    name      = var.name
    namespace = var.namespace
    labels    = local.labels
  }

  spec {
    type = var.service_type
    port {
      port        = 7007
      target_port = "http"
      protocol    = "TCP"
      name        = "http"
    }
    selector = {
      app = var.name
    }
  }
}

resource "kubernetes_service_account" "this" {
  metadata {
    name      = "${var.name}-sa"
    namespace = var.namespace
    labels    = local.labels
  }
}

resource "kubernetes_ingress_v1" "backstage" {
  count = var.create_ingress ? 1 : 0

  metadata {
    name      = var.name
    namespace = var.namespace
    labels    = local.labels
    annotations = var.ingress_annotations
  }

  spec {
    ingress_class_name = var.ingress_class_name

    dynamic "rule" {
      for_each = var.ingress_hosts
      content {
        host = rule.value
        http {
          path {
            path     = "/"
            path_type = "Prefix"
            backend {
              service {
                name = kubernetes_service.backstage.metadata[0].name
                port {
                  number = 7007
                }
              }
            }
          }
        }
      }
    }
  }
}
