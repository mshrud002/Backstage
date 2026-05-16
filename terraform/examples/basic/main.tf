provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

module "backstage" {
  source = "../../"

  name       = "backstage"
  namespace  = "backstage"
  app_title  = "My Company Developer Portal"
  app_base_url = "https://backstage.example.com"
  github_org = "my-company"

  image_repository = "ghcr.io/my-company/backstage"
  image_tag        = "latest"

  replicas    = 2
  service_type = "ClusterIP"

  create_ingress    = true
  ingress_class_name = "nginx"
  ingress_hosts     = ["backstage.example.com"]
  ingress_annotations = {
    "cert-manager.io/cluster-issuer" = "letsencrypt-prod"
  }
}
