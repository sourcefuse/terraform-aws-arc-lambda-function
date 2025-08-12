import json
import logging
import os

# Configure logging
logger = logging.getLogger()
logger.setLevel(os.environ.get('LOG_LEVEL', 'INFO'))

def lambda_handler(event, context):
    """
    Basic Lambda function handler

    Args:
        event: Lambda event data
        context: Lambda context object

    Returns:
        dict: Response with status code and body
    """

    logger.info(f"Received event: {json.dumps(event)}")

    # Get environment variables
    environment = os.environ.get('ENVIRONMENT', 'unknown')

    # Create response
    response = {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps({
            'message': '${message}',
            'environment': environment,
            'function_name': context.function_name,
            'function_version': context.function_version,
            'request_id': context.aws_request_id,
            'event': event
        })
    }

    logger.info(f"Returning response: {json.dumps(response)}")

    return response
