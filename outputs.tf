output "storage_class" {
    depends_on = [helm_release.longhorn]
    value      = "longhorn"
}

locals {
    protocol = var.issuer_name == null ? "http" : "https"
}

output "url" {
    depends_on  = [helm_release.longhorn]
    value       = "${local.protocol}://${var.host}/"
    description = "installed application URL"
}