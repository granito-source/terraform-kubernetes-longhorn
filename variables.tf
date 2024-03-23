variable "namespace" {
    type        = string
    default     = "longhorn-system"
    description = "namespace to use for the installation"
}

variable "longhorn_version" {
    type        = string
    default     = null
    description = "Longhorn Helm chart version"
}

variable "host" {
    type        = string
    default     = null
    description = "FQDN for the ingress, must be set to configure ingress"
}

variable "ingress_class_name" {
    type        = string
    default     = null
    description = "ingress class to use"
}

variable "issuer_name" {
    type        = string
    default     = null
    description = "cert-manager issuer, use TLS if defined"
}

variable "issuer_type" {
    type        = string
    default     = "cluster-issuer"
    description = "cert-manager issuer type"
    validation {
        condition     = contains(["cluster-issuer", "issuer"], var.issuer_type)
        error_message = "issuer type must be 'issuer' or 'cluster-issuer'"
    }
}

variable "username" {
    type        = string
    default     = "longhorn"
    description = "Longhorn UI username"
}

variable "password" {
    type        = string
    default     = null
    description = "Longhorn UI password, must be set to configure ingress"
}
