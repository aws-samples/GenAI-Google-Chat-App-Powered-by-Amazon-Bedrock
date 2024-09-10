from aws_cdk import (
    Stack,
    Duration,
    aws_dynamodb as dynamodb,
    aws_lambda as lambdaf,
    RemovalPolicy,
    aws_lambda_python_alpha as python,
    aws_iam as iam,
    aws_apigatewayv2 as apigateway,
    aws_apigatewayv2_integrations as integrations,
    aws_apigatewayv2_authorizers as authorizers,
    CfnOutput,
    CfnParameter,
    # aws_sqs as sqs,
)
from constructs import Construct
import os

class BedrockGoogleChat(Stack):

    def __init__(self, scope: Construct, construct_id: str, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)

        knowledge_base_id = CfnParameter(
            self, 
            "KnowledgeBaseID", 
            type="String",
            description="The ID for the knowledge bases for Amazon Bedrock"
        )
        
        llm_model = CfnParameter(
            self, 
            "LLMModel", 
            type="String",
            description="The LLM model to be used for text generation on Amazon Bedrock",
            allowed_values=["Amazon-Titan-Text-Premier", "Anthropic-Claude-Sonnet-3"],
            default="Anthropic-Claude-Sonnet-3"
        )
        
        table = dynamodb.TableV2(
            self, "chat-history-table",
            partition_key=dynamodb.Attribute(
                name="spaceid",
                type=dynamodb.AttributeType.STRING
            ),
            removal_policy=RemovalPolicy.DESTROY
        )
    
        lambda_auth = python.PythonFunction(self, "chat-app-authorizer",
            entry="./lambda/lambda-auth",  # required
            runtime=lambdaf.Runtime.PYTHON_3_12,  # required
            index="lambda-authorizer-code.py",  # optional, defaults to 'index.py'
            handler="lambda_handler",
            timeout=Duration.seconds(30)
        )

        lambda_chatapp = python.PythonFunction(self, "chat-app-main",
            entry="./lambda/lambda-chat-app",  # required
            runtime=lambdaf.Runtime.PYTHON_3_12,  # required
            index="lambda-chatapp-code.py",  # optional, defaults to 'index.py'
            handler="lambda_handler",
            timeout=Duration.seconds(30)
        )
        
        lambda_auth.add_environment("CHAT_ISSUER", self.node.try_get_context('CHAT_ISSUER'))
        lambda_chatapp.add_environment("dynamoDBTable", table.table_name)
        
        
        
        lambda_chatapp.add_environment("kbId", knowledge_base_id.value_as_string)
        #lambda_chatapp.add_environment("kbId", self.node.try_get_context('knowledgebase-id'))
        if llm_model.value_as_string == "Amazon-Titan-Text-Premier":
            lambda_chatapp.add_environment("modelarn", self.node.try_get_context('titan-text-premier-model-arn'))
        else:
            lambda_chatapp.add_environment("modelarn", self.node.try_get_context('anthropic-claude-sonnet-3-model-arn'))
        lambda_chatapp.add_environment("spaceId", "spaceid")
        lambda_chatapp.add_to_role_policy(iam.PolicyStatement(
            effect=iam.Effect.ALLOW,
            actions=[
                "bedrock:CreateDataSource",
                "bedrock:GetFoundationModelAvailability",
                "bedrock:InvokeModel",
                "bedrock:UpdateKnowledgeBase",
                "bedrock:GetKnowledgeBase",
                "bedrock:GetModelInvocationLoggingConfiguration",
                "bedrock:AssociateThirdPartyKnowledgeBase",
                "bedrock:ListKnowledgeBases",
                "bedrock:InvokeModelWithResponseStream",
                "bedrock:DetectGeneratedContent",
                "bedrock:RetrieveAndGenerate",
                "bedrock:CreateKnowledgeBase",
                "bedrock:CreateModelInvocationJob",
                "bedrock:GetFoundationModel",
                "bedrock:ListFoundationModels",
                "bedrock:Retrieve"
            ],
            resources=["*"]
        ))
    
        table.grant_read_write_data(lambda_chatapp)
        
        http_api = apigateway.HttpApi(self, 'Google_Chat_App_HTTP_Api')
        lambda_integration = integrations.HttpLambdaIntegration("LambdaIntegration", handler=lambda_chatapp);
        
        lambda_authorizer = authorizers.HttpLambdaAuthorizer("lambda-chat-app-Authorizer",  lambda_auth,response_types=[authorizers.HttpLambdaResponseType.SIMPLE])
        http_api.add_routes(
            path= "/",
            methods=[apigateway.HttpMethod.POST],
            authorizer=lambda_authorizer,
            integration= lambda_integration
        );
        lambda_auth.add_environment("AUDIENCE", http_api.api_endpoint)
        
        #api.add_routes(integration=HttpUrlIntegration("BooksIntegration", "https://get-books-proxy.example.com"),path="/books",authorizer=authorizer)
        
        #api = apigateway.LambdaRestApi(
        #    self, "Google_Chat_App_Api",
        #    handler = lambda_chatapp,
        #    proxy = False,
        #)
        #api.root.add_method("ANY")
        
        
        CfnOutput(self, "ApiEndpoint", value=http_api.api_endpoint)