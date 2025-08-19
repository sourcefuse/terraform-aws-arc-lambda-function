import json
import logging
import os
import sys
from datetime import datetime, timezone
from typing import Dict, Any, Optional

import boto3
import requests
from botocore.exceptions import ClientError
from pydantic import BaseModel, ValidationError


# Configure structured logging
APPLICATION_JSON = "application/json"
logging.basicConfig(
    level=os.environ.get('LOG_LEVEL', 'INFO'),
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Initialize AWS clients
ssm_client = boto3.client('ssm')

class LambdaEvent(BaseModel):
    """Pydantic model for Lambda event validation"""
    action: str
    payload: Optional[Dict[str, Any]] = {}

class LambdaResponse(BaseModel):
    """Pydantic model for Lambda response"""
    statusCode: int
    headers: Dict[str, str]
    body: str

def get_parameter(parameter_name: str, default_value: str = None) -> str:
    """
    Get parameter from AWS Systems Manager Parameter Store

    Args:
        parameter_name: Name of the parameter
        default_value: Default value if parameter not found

    Returns:
        Parameter value or default value
    """
    try:
        response = ssm_client.get_parameter(
            Name=parameter_name,
            WithDecryption=True
        )
        return response['Parameter']['Value']
    except ClientError as e:
        if e.response['Error']['Code'] == 'ParameterNotFound':
            logger.warning(f"Parameter {parameter_name} not found, using default value")
            return default_value
        else:
            logger.error(f"Error getting parameter {parameter_name}: {e}")
            raise

def handle_health_check() -> Dict[str, Any]:
    """Handle health check requests"""
    return {
        'status': 'healthy',
        'timestamp': datetime.now(timezone.utc).isoformat(),
        'version': os.environ.get('APP_VERSION', 'unknown'),
        'environment': os.environ.get('ENVIRONMENT', 'unknown'),
        'python_version': sys.version,
        'container_info': {
            'platform': sys.platform,
            'architecture': os.uname().machine if hasattr(os, 'uname') else 'unknown'
        }
    }

def handle_external_api_call(url: str) -> Dict[str, Any]:
    """Make an external API call"""
    try:
        response = requests.get(url, timeout=10)
        response.raise_for_status()

        return {
            'status': 'success',
            'status_code': response.status_code,
            'headers': dict(response.headers),
            'data': response.json() if response.headers.get('content-type', '').startswith(APPLICATION_JSON) else response.text[:500]
        }
    except requests.RequestException as e:
        logger.error(f"External API call failed: {e}")
        return {
            'status': 'error',
            'error': str(e)
        }

def handle_parameter_demo() -> Dict[str, Any]:
    """Demonstrate parameter store integration"""
    function_name = os.environ.get('FUNCTION_NAME', 'unknown')

    # Try to get a parameter (this will likely not exist, demonstrating error handling)
    config_value = get_parameter(
        f"/{function_name}/config/demo_setting",
        default_value="default_config_value"
    )

    return {
        'parameter_demo': {
            'config_value': config_value,
            'parameter_name': f"/{function_name}/config/demo_setting",
            'note': 'This demonstrates parameter store integration'
        }
    }

def lambda_handler(event: Dict[str, Any], context) -> Dict[str, Any]:
    """
    Main Lambda handler for container-based function

    Args:
        event: Lambda event data
        context: Lambda context object

    Returns:
        dict: HTTP response
    """

    logger.info(f"Container Lambda function invoked with event: {json.dumps(event)}")

    try:
        # Validate event structure
        try:
            validated_event = LambdaEvent(**event)
        except ValidationError as e:
            logger.error(f"Event validation failed: {e}")
            return LambdaResponse(
                statusCode=400,
                headers={'Content-Type': APPLICATION_JSON},
                body=json.dumps({
                    'error': 'Invalid event structure',
                    'details': str(e),
                    'request_id': context.aws_request_id
                })
            ).dict()

        # Get environment information
        environment_info = {
            'function_name': context.function_name,
            'function_version': context.function_version,
            'request_id': context.aws_request_id,
            'environment': os.environ.get('ENVIRONMENT', 'unknown'),
            'app_version': os.environ.get('APP_VERSION', 'unknown'),
            'memory_limit': context.memory_limit_in_mb,
            'remaining_time': context.get_remaining_time_in_millis()
        }

        # Handle different actions
        result_data = {}

        if validated_event.action == 'health':
            result_data = handle_health_check()

        elif validated_event.action == 'external_api':
            url = validated_event.payload.get('url', 'https://httpbin.org/json')
            result_data = handle_external_api_call(url)

        elif validated_event.action == 'parameter_demo':
            result_data = handle_parameter_demo()

        elif validated_event.action == 'echo':
            result_data = {
                'echo': validated_event.payload,
                'message': 'This is an echo response from the container Lambda'
            }

        else:
            logger.warning(f"Unknown action: {validated_event.action}")
            return LambdaResponse(
                statusCode=400,
                headers={'Content-Type': APPLICATION_JSON},
                body=json.dumps({
                    'error': 'Unknown action',
                    'action': validated_event.action,
                    'available_actions': ['health', 'external_api', 'parameter_demo', 'echo'],
                    'request_id': context.aws_request_id
                })
            ).dict()

        # Create successful response
        response_body = {
            'message': f'Container Lambda executed successfully - action: {validated_event.action}',
            'environment_info': environment_info,
            'result': result_data,
            'timestamp': datetime.now(timezone.utc).isoformat()
        }

        logger.info(f"Successfully processed action: {validated_event.action}")

        return LambdaResponse(
            statusCode=200,
            headers={
                'Content-Type': APPLICATION_JSON,
                'Access-Control-Allow-Origin': '*',
                'X-Function-Version': context.function_version,
                'X-Request-ID': context.aws_request_id
            },
            body=json.dumps(response_body, default=str)
        ).dict()

    except Exception as e:
        logger.error(f"Unexpected error in lambda_handler: {str(e)}", exc_info=True)

        return LambdaResponse(
            statusCode=500,
            headers={'Content-Type': APPLICATION_JSON},
            body=json.dumps({
                'error': 'Internal server error',
                'error_message': str(e),
                'request_id': context.aws_request_id,
                'function_name': context.function_name
            })
        ).dict()

# For local testing
if __name__ == "__main__":
    # Mock context for local testing
    class MockContext:
        function_name = "container-lambda-example"
        function_version = "$LATEST"
        aws_request_id = "test-request-id"
        memory_limit_in_mb = 512

        def get_remaining_time_in_millis(self):
            return 30000

    # Test events
    test_events = [
        {"action": "health"},
        {"action": "echo", "payload": {"test": "data"}},
        {"action": "external_api", "payload": {"url": "https://httpbin.org/json"}},
        {"action": "parameter_demo"}
    ]

    # sonarignore:end
    for test_event in test_events:
        print(f"\nTesting event: {test_event}")
        result = lambda_handler(test_event, MockContext())
        print(f"Result: {json.dumps(result, indent=2)}")
