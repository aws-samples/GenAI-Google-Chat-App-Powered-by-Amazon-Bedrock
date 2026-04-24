resource "aws_dynamodb_table" "chat_history_table" {
  name           = "chat-history-table"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "spaceid"
  
  attribute {
    name = "spaceid"
    type = "S"
  }
  
  # Note: AWS DynamoDB Global Tables are handled differently in Terraform
  # This creates a standard DynamoDB table. For global tables, you would need
  # additional configuration with aws_dynamodb_global_table resource
  
  lifecycle {
    ignore_changes = [replica]
  }
}
