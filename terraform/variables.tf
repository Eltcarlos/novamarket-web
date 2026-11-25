variable "project_id" {
  description = "ID del proyecto GCP asignado."
  type        = string
  nullable    = false
}

variable "name_prefix" {
  description = "Prefijo para el nombre de los recursos."
  type        = string
  default     = "novamarket"
}

variable "primary_region" {
  description = "Region primaria (donde vivira la base de datos primaria)."
  type        = string
  default     = "northamerica-south1"

  validation {
    condition     = contains(keys(var.regions), var.primary_region)
    error_message = "primary_region debe ser una de las claves de var.regions."
  }
}

# Agregar un pais/region = agregar una entrada a este mapa.
# /22 = 1024 IPs: Cloud Run (Direct VPC egress) consume varias IPs por instancia
# y conviven dos revisiones durante un despliegue.
variable "regions" {
  description = "Regiones a desplegar y el CIDR de su subred de aplicaciones."
  type = map(object({
    app_cidr = string
  }))
  default = {
    northamerica-south1 = { app_cidr = "10.10.0.0/22" } # Queretaro
    southamerica-west1  = { app_cidr = "10.20.0.0/22" } # Santiago
  }

  validation {
    condition     = alltrue([for r in values(var.regions) : can(cidrhost(r.app_cidr, 0))])
    error_message = "Cada app_cidr debe ser un CIDR IPv4 valido."
  }
}

variable "enable_nat" {
  description = "Crea Cloud NAT con IP fija por region (allowlist en pasarelas de pago y aliados)."
  type        = bool
  default     = true
}

variable "deployer_impersonators" {
  description = "Identidades que pueden impersonar al deployer, p. ej. user:persona@empresa.com."
  type        = set(string)
  default     = []

  validation {
    condition     = alltrue([for m in var.deployer_impersonators : can(regex("^(user|group|serviceAccount):[^@\\s]+@[^@\\s]+$", m))])
    error_message = "Use user:, group: o serviceAccount: con un correo. No se permiten allUsers ni allAuthenticatedUsers."
  }
}
