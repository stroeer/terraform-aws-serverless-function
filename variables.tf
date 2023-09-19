variable "bundle" {
  type = object({
    enabled       = bool
    source_folder = optional(string, "./.artifacts")
  })
  description = "Controls wether the module should bundle code with the created lambda or use an empty archive file. Using an empty archive comes in handy when you want to seperate infrastructure changes from application changes in your workflow. When bundling you can also specify the folder where the src or binary of your function resides."
  default = {
    enabled = false
  }
  nullable = false
}

variable "bootstrap_folder" {
  type        = string
  description = "The folder to locate the bootstrap file."
  default     = ""
}

variable "description" {
  type        = string
  description = "The description of your lambda. Used for documenting purposes."
  default     = null
}

variable "name" {
  type        = string
  description = "The name of your function. This must match the name of your binary in case of types [go]."
  nullable    = false
}

variable "prefix" {
  type        = string
  description = "Adds a prefix to the function name."
  default     = ""
}

variable "suffix" {
  type        = string
  description = "Adds a suffix to the function name."
  default     = ""
}

variable "memory" {
  type        = number
  description = "The memory you wish to assign to the lambda function."
  default     = 256
  nullable    = false
}

variable "timeout" {
  type        = number
  description = "The maximum amount of time (in seconds) your function is allowed to run."
  default     = 3
  nullable    = false
}

variable "environment_vars" {
  type        = map(string)
  description = "Environment variables you want to set in the lambda environment."
  default     = {}
  nullable    = false
}

variable "managed_policies" {
  type        = set(string)
  description = "A set of managed policies, referenced by arn, which will be attached to the created role of the lambda function."
  default     = []
  nullable    = false
}

variable "inline_policies" {
  type        = list(string)
  description = "A list of policy statements, in json, which will be set on the created role of the lambda function."
  default     = []
  nullable    = false
}

variable "logs" {
  type = object({
    enabled   = bool
    retention = optional(number, 30)
  })
  description = "Enables cloudwatch logging with the given retention in days and also adds the needed iam policies to your lambda."
  default = {
    enabled = false
  }
  nullable = false

  validation {
    condition     = !var.logs.enabled ? true : contains([0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.logs.retention)
    error_message = "Only one of theese values are allowed for retention: [0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653]."
  }
}

variable "type" {
  type        = string
  description = "The type of function you are deploying."
  nullable    = false

  validation {
    condition     = contains(["go", "node", "python", "ruby", "java", ".net", "custom"], var.type)
    error_message = "Provide a valid type for your function from this list: [go, node, python, ruby, java, .net, custom]."
  }
}

variable "handler" {
  type        = string
  description = "Sets a custom name for the handler. Leave empty if you want to use the default of this module, which sets the name based on the type (runtime)."
  default     = null
}

variable "vpc" {
  type = object({
    subnet_ids         = list(string)
    security_group_ids = list(string)
  })
  description = "VPC configuration. Be aware that this will change the operational behaviour of your lambda and could have impacts on costs."

  default = null

  validation {
    condition     = var.vpc == null ? true : (length(var.vpc.subnet_ids) > 0 && length(var.vpc.security_group_ids) > 0)
    error_message = "If you provide the vpc input, then you have to set both: subnet and security group ids."
  }
}
