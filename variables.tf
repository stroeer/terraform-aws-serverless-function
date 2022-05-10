variable "bundle" {
  type = object({
    enabled : optional(bool)
    source_folder : optional(string)
  })
  description = "Controls wether the module should bundle code with the created lambda or use an empty archive file. Using an empty archive comes in handy when you want to seperate infrastructure changes from application changes in your workflow. When bundling you can also specify the folder where the src or binary of your function resides."
  default = null

  validation {
    condition     = var.bundle == null || var.bundle.enabled == null || var.bundle.enabled || (!var.bundle.enabled && var.bundle.source_folder == null)
    error_message = "When disabling bundling, you cannot set any other values on the bundle object."
  }
}

variable "description" {
  type        = string
  description = "The description of your lambda. Used for documenting purposes."
  default     = ""
}

variable "name" {
  type        = string
  description = "The name of your function. This must match the name of your binary in case of types [go]."
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
}

variable "timeout" {
  type        = number
  description = "The maximum amount of time (in seconds) your function is allowed to run."
  default     = 3
}

variable "environment_vars" {
  type        = map(string)
  description = "Environment variables you want to set in the lambda environment."
  default     = {}
}

variable "managed_policies" {
  type        = set(string)
  description = "A set of managed policies, referenced by arn, which will be attached to the created role of the lambda function."
  default     = []
}

variable "inline_policies" {
  type        = list(string)
  description = "A list of policy statements, in json, which will be set on the created role of the lambda function."
  default     = []
}

variable "logs" {
  type = object({
    enabled   = bool
    retention = optional(number)
  })

  description = "Enables cloudwatch logging with the given retention in days and also adds the needed iam policies to your lambda."
  default = {
    enabled   = false
    retention = 30
  }

  validation {
    condition     = var.logs.enabled ? contains([0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.logs.retention) : true
    error_message = "Only one of theese values are allowed for retention: [0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653]."
  }
}

variable "type" {
  type        = string
  description = "The type of function you are deploying."
  default     = "go"

  validation {
    condition     = contains(["go", "node", "python", "ruby", "java", ".net", "custom"], var.type)
    error_message = "Provide a valid type for your function from this list: [go, node, python, ruby, java, .net, custom]."
  }
}
