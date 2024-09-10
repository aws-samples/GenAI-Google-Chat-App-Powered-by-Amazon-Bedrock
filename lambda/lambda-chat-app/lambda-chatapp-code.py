import json
import os
import logging
import boto3
from botocore.exceptions import ClientError

logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO)
  
def retrievefromkb(user_message, session_id):
    bedrock_client = boto3.client(service_name='bedrock-agent-runtime')
    
    config_params = {
        'input': {
            'text': user_message
        },
        'retrieveAndGenerateConfiguration': {
            'type': 'KNOWLEDGE_BASE',
            'knowledgeBaseConfiguration': {
                'knowledgeBaseId': os.environ['kbId'],
                'modelArn': os.environ['modelarn']
            }
        }
    }
        
    if session_id != -1:
        config_params['sessionId'] = session_id
    
    try:
    	assistantmessage = bedrock_client.retrieve_and_generate(**config_params)
    except bedrock_client.exceptions.ValidationException as e:
    	if 'sessionId' in config_params:
            # Log the exception and retry without session_id
            print(f"ValidationException occurred with session_id: {str(e)}. Probably the session Id has expired. Creating a new session Id")
            del config_params['sessionId']
            # Retry the retrieve_and_generate call without session_id
            assistantmessage = bedrock_client.retrieve_and_generate(**config_params)
    return assistantmessage 
    
def conversewithbedrock(messages):
    bedrock_client = boto3.client(service_name='bedrock-runtime')
    response = bedrock_client.converse(modelId=os.environ['modelarn'],messages=messages)
    return response['output']['message']
    
def get_response(event):
    if event['type'] == 'MESSAGE':
        user_message = event['message']['text']
        dynamodb = boto3.resource('dynamodb')
        table = dynamodb.Table(os.environ['dynamoDBTable'])
        response = table.get_item(
            Key={
                os.environ['spaceId'] : event['space']['name']
            }
        )
        
        if (os.environ['kbId'] != "None"):
            # Use the retrieveandgenerate Bedrock API
            if ('Item' in response) and ('session_id' in response['Item']):
                item = response.get('Item')
                session_id = item['session_id']
                assistantmessage = retrievefromkb(user_message, session_id)
                if assistantmessage['sessionId'] != session_id:
                    # Old session Id has expired and a new session Id has been generated.
                    # Updating the appropriate item in dynamodb table
                    table.put_item(
                        Item={
		                    os.environ['spaceId']: event['space']['name'],
		                    'session_id' : assistantmessage['sessionId']
		                    }
                )
            else:
                assistantmessage = retrievefromkb(user_message, -1)
                table.put_item(
                    Item={
                        os.environ['spaceId']: event['space']['name'],
                        'session_id' : assistantmessage['sessionId']
                        }
                )
        else:
            if not('Item' in response) or not('messages' in response['Item']):
                item = {
                    os.environ['spaceId']: event['space']['name'],
                    'messages': []
                }
                table.put_item(Item=item)
            else:
                item = response.get('Item')
            if 'messages' in item:
                dict_messages = item['messages']
                user_message = event['message']['text']
                # function needed to pull messages history from a dynamodb table
                invoke_message = {
                    "role": "user",
                    "content": [{"text": user_message}]
                }
                dict_messages.append(invoke_message)
                assistantmessage = conversewithbedrock(dict_messages)
                dict_messages.append(assistantmessage)
                table.put_item( Item={
                     os.environ['spaceId']: event['space']['name'],
                    'messages': dict_messages
                    }
                )
    return assistantmessage 

def handle_post(data):
    """Handle POST requests from Google Chat."""
    response = get_response(data)
    
    if (os.environ['kbId'] != 'None'):
        # The user did designate a knowledge base Id, so we add the data sources to the answer
        output_text = response['output']['text']
        source_uris = []
        

        for citation in response['citations']:
            for reference in citation.get("retrievedReferences", []):
                location = reference.get('location', {})
                
                # Check for 'url' in any location
                for loc_type, loc_value in location.items():
                    if 'url' in loc_value:
                        source_uris.append(loc_value['url'])
                    elif 'uri' in loc_value:
                        source_uris.append(loc_value['uri'])

        # Create a string with numbered sources on separate lines
        concatenated_citations = "\n ".join(f"{i+1}. {uri}" for i, uri in enumerate(source_uris))
        output_answer = output_text + "\n\nSources:\n " + concatenated_citations
        return output_answer
    else:
        # No knowledge base, just pass the content of the response
        output_content = response['content']
        output_text = output_content[0]['text']
        return output_text

def lambda_handler(event, context):
    if event['requestContext']['http']['method'] == 'POST':
        # A POST request indicates a Google Chat App Event sent by the application        
        data = json.loads(event['body'])
        # Invoke handle_post function that includes the logic to process Google chat app events
        response = handle_post(data)
        return { 'text': response }
    else:
        return {
            'statusCode': 405,
            'body': json.dumps("Method Not Allowed. This function must be called from Google Chat.")
        }
