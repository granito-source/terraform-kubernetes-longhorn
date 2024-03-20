resource "kubernetes_namespace" "longhorn" {
    metadata {
        name = var.namespace
    }
}

resource "terraform_data" "username" {
    input = var.username
}

resource "terraform_data" "password" {
    input = var.password
}

resource "kubernetes_secret" "longhorn_auth" {
    metadata {
        namespace = kubernetes_namespace.longhorn.metadata[0].name
        name      = "longhorn-auth"
    }
    data = {
        (terraform_data.username.output) = bcrypt(terraform_data.password.output)
    }
    lifecycle {
        replace_triggered_by = [
            terraform_data.username,
            terraform_data.password
        ]
        ignore_changes = [
            data
        ]
    }
}

resource "helm_release" "longhorn" {
    namespace  = kubernetes_namespace.longhorn.metadata[0].name
    name       = "longhorn"
    repository = "https://charts.longhorn.io"
    chart      = "longhorn"
    version    = var.longhorn_version
    values     = [
        <<-EOT
        defaultSettings:
          deletingConfirmationFlag: true
          allowCollectingLonghornUsageMetrics: false
        longhornUI:
          replicas: 1
        ingress:
          enabled: true
          ingressClassName: ${var.ingress_class_name}
          host: ${var.host}
          annotations:
            nginx.ingress.kubernetes.io/auth-type: basic
            nginx.ingress.kubernetes.io/auth-secret: ${kubernetes_secret.longhorn_auth.metadata[0].name}
            nginx.ingress.kubernetes.io/auth-secret-type: auth-map
            nginx.ingress.kubernetes.io/auth-realm: Longhorn
        EOT
    , var.issuer_name == null ? "" : <<-EOT
        ingress:
          tls: true
          annotations:
            cert-manager.io/${var.issuer_type}: ${var.issuer_name}
        EOT
    ]
}
