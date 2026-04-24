variable "knowledge_base_id" {
  type        = string
  description = "The ID for the knowledge bases for Amazon Bedrock"
}

variable "llm_model" {
  type        = string
  default     = "Anthropic-Claude-Sonnet-3"
  description = "The LLM model to be used for text generation on Amazon Bedrock"
  
  validation {
    condition     = contains(["Amazon-Titan-Text-Premier", "Anthropic-Claude-Sonnet-3"], var.llm_model)
    error_message = "Valid values for llm_model are: Amazon-Titan-Text-Premier, Anthropic-Claude-Sonnet-3"
  }
}

variable "region" {
  type        = string
  description = "AWS region to deploy resources"
}
