locals {
    configure_backup  = var.backup_target != null && var.aws_access_key_id != null && var.aws_secret_access_key != null
    configure_ingress = var.host != null && nonsensitive(var.password != null)
}

resource "kubernetes_namespace_v1" "longhorn" {
    metadata {
        name = var.namespace
    }
}

resource "kubernetes_secret_v1" "backup" {
    count = local.configure_backup ? 1 : 0
    metadata {
        namespace = kubernetes_namespace_v1.longhorn.metadata[0].name
        name      = "backup-s3"
    }
    data = {
        AWS_ENDPOINTS         = var.aws_endpoints
        AWS_ACCESS_KEY_ID     = var.aws_access_key_id
        AWS_SECRET_ACCESS_KEY = var.aws_secret_access_key
    }
}

resource "terraform_data" "username" {
    input = var.username
}

resource "terraform_data" "password" {
    input = var.password
}

resource "kubernetes_secret_v1" "longhorn_auth" {
    count = local.configure_ingress ? 1 : 0
    metadata {
        namespace = kubernetes_namespace_v1.longhorn.metadata[0].name
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
    namespace  = kubernetes_namespace_v1.longhorn.metadata[0].name
    name       = "longhorn"
    repository = "https://charts.longhorn.io"
    chart      = "longhorn"
    version    = var.longhorn_version
    values     = [
        <<EOT
defaultSettings:
  deletingConfirmationFlag: true
  allowCollectingLonghornUsageMetrics: false
%{ if local.configure_backup ~}
  backupTarget: ${var.backup_target}
  backupTargetCredentialSecret: ${kubernetes_secret_v1.backup[0].metadata[0].name}
%{ endif ~}
longhornUI:
  replicas: 1
%{ if local.configure_ingress ~}
ingress:
  enabled: true
  ingressClassName: ${var.ingress_class == null ? "null" : var.ingress_class}
  host: ${var.host}
%{ if var.issuer_name != null ~}
  tls: true
%{ endif ~}
  annotations:
%{ if var.issuer_name != null ~}
    cert-manager.io/${var.issuer_type}: ${var.issuer_name}
%{ endif ~}
    nginx.ingress.kubernetes.io/auth-type: basic
    nginx.ingress.kubernetes.io/auth-secret: ${kubernetes_secret_v1.longhorn_auth[0].metadata[0].name}
    nginx.ingress.kubernetes.io/auth-secret-type: auth-map
    nginx.ingress.kubernetes.io/auth-realm: Longhorn
%{ endif ~}
EOT
    ]
}
