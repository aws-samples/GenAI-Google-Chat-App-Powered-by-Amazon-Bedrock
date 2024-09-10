import json
import sys
import os
from google.oauth2 import id_token
from google.auth.transport import requests

# Constants
CHAT_ISSUER = os.environ['CHAT_ISSUER']
AUDIENCE = os.environ['AUDIENCE']

def lambda_handler(event, context):

    # Extract the Authorization header
    headers = event.get('headers', {})
    auth_header = headers.get('authorization', '')
    # Check if the Authorization header is present and starts with 'Bearer '
    if not auth_header.startswith('Bearer '):
        return generate_policy('false')

    # Extract the Bearer token from the Authorization header
    bearer_token = auth_header[len('Bearer '):]

    try:
        # Verify the Bearer token
        request = requests.Request()
        token = id_token.verify_oauth2_token(bearer_token, request, AUDIENCE)
        
        # Check if the token's email is the expected issuer
        if token['email'] != CHAT_ISSUER:
            return generate_policy('false')
    except Exception as e:
        # Log the exception and deny access if token verification fails
        print(f"Token verification failed: {str(e)}")
        return generate_policy('false')

    return generate_policy('true')

def generate_policy(decision):
    # Generate a simple decision document to allow or deny the request
    policy = {
        "isAuthorized": decision
    }
    return policy

