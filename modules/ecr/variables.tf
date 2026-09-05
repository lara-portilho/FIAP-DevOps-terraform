variable "project_name" {
  type = string
}

variable "services" {
  description = "Names of the microservices, one ECR repository is created per entry"
  type        = list(string)
  default     = ["auth-service", "flag-service", "targeting-service", "evaluation-service", "analytics-service"]
}
