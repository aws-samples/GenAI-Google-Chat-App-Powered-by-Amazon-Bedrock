#!/bin/bash

# Display initial message
echo "This demo script deploys a CloudFormation stack on AWS. It includes resources and components that are needed to implement an AI-powered business assistant for Google Chat, leveraging the power of Amazon Bedrock."

# Prompt for knowledge base ID
read -p "Please provide the ID for the knowledge bases for Amazon Bedrock (optional): " kb_id

if [ -z "$kb_id" ]; then
    kb_id="None"
    echo "No Knowledge Base ID provided. Proceeding with kb_id set to 'None'."
fi

# Prompt for LLM model selection
echo "Select the LLM model to be used for text generation:"
echo "1. Anthropic-Claude-Sonnet-3 (default)"
echo "2. Amazon-Titan-Text-Premier"
read -p "Enter your choice (1 or 2): " model_choice

# Set LLM based on user choice
case $model_choice in
    2)
        llm="Amazon-Titan-Text-Premier"
        ;;
    *)
        llm="Anthropic-Claude-Sonnet-3"
        ;;
esac

# Display selected options
echo "Knowledge Base ID: $kb_id"
echo "Selected LLM: $llm"

# Deploy the stack using CDK
echo "Deploying the stack..."
cdk deploy --parameters KnowledgeBaseID="$kb_id"  --parameters LLMModel="$llm"