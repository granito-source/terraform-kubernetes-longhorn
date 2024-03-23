output "storage_class" {
    depends_on  = [helm_release.longhorn]
    value       = "longhorn"
    description = "provided default storage class"
}

locals {
    protocol = var.issuer_name == null ? "http" : "https"
}

output "url" {
    depends_on  = [helm_release.longhorn]
    value       = local.configure_ingress ? "${local.protocol}://${var.host}/" : null
    description = "installed application URL"
}
