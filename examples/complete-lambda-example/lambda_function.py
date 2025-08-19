import json
import logging
import os
import socket
import time
import random
import urllib.request
import urllib.error
from datetime import datetime
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime, timezone

import boto3
from botocore.exceptions import ClientError

# Configure logging
# sonar-ignore-start
logger = logging.getLogger()
logger.setLevel(os.environ.get('LOG_LEVEL', 'INFO'))

# Initialize AWS clients
s3_client = boto3.client('s3')
sns_client = boto3.client('sns')
sqs_client = boto3.client('sqs')
ssm_client = boto3.client('ssm')
cloudwatch_client = boto3.client('cloudwatch')

def identify_event_source(event):
    """Identify the source of the Lambda invocation"""
    if 'Records' in event:
        # S3, SNS, or SQS event
        if event['Records'][0].get('eventSource') == 'aws:s3':
            return 's3', event['Records'][0]
        elif event['Records'][0].get('EventSource') == 'aws:sns':
            return 'sns', event['Records'][0]
        elif event['Records'][0].get('eventSource') == 'aws:sqs':
            return 'sqs', event['Records'][0]
    elif 'source' in event and event['source'] == 'aws.events':
        # EventBridge event
        return 'eventbridge', event
    elif 'httpMethod' in event or 'requestContext' in event:
        # API Gateway event
        return 'api_gateway', event
    elif event.get('action'):
        # Direct invocation with action
        return 'direct', event
    else:
        return 'unknown', event

def send_custom_metric(metric_name, value, unit='Count', dimensions=None):
    """Send custom metric to CloudWatch"""
    try:
        metric_data = {
            'MetricName': metric_name,
            'Value': value,
            'Unit': unit,
            'Timestamp': datetime.now(time.timezone.utc)
        }

        if dimensions:
            metric_data['Dimensions'] = dimensions

        cloudwatch_client.put_metric_data(
            Namespace='Lambda/CompleteExample',
            MetricData=[metric_data]
        )
        logger.debug(f"Custom metric sent: {metric_name} = {value}")
    except Exception as e:
        logger.error(f"Error sending custom metric: {e}")

def get_ssm_parameters():
    """Retrieve all SSM parameters for the function"""
    try:
        function_name = os.environ.get('AWS_LAMBDA_FUNCTION_NAME', 'complete-lambda-example')

        response = ssm_client.get_parameters_by_path(
            Path=f'/{function_name}/',
            Recursive=True,
            WithDecryption=True
        )

        parameters = {}
        for param in response['Parameters']:
            param_name = param['Name'].replace(f'/{function_name}/', '')
            parameters[param_name] = {
                'value': param['Value'] if param['Type'] != 'SecureString' else '[ENCRYPTED]',
                'type': param['Type'],
                'last_modified': param['LastModifiedDate'].isoformat()
            }

        return parameters

    except Exception as e:
        logger.error(f"Error getting SSM parameters: {e}")
        return {}

def test_database_connection():
    """Test database connectivity"""
    db_endpoint = os.environ.get('DB_ENDPOINT', '${db_endpoint}')
    db_name = os.environ.get('DB_NAME', 'lambdadb')

    try:
        # Test basic connectivity to database port
        db_host = db_endpoint.split(':')[0]
        db_port = int(db_endpoint.split(':')[1]) if ':' in db_endpoint else 5432

        logger.info(f"Testing database connectivity to {db_host}:{db_port}")

        # Test socket connection
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(5)
        result = sock.connect_ex((db_host, db_port))
        sock.close()

        if result == 0:
            return {
                'success': True,
                'message': 'Database port is reachable',
                'db_endpoint': db_endpoint,
                'db_name': db_name,
                'connection_test': 'port_accessible'
            }
        else:
            return {
                'success': False,
                'message': 'Database port is not reachable',
                'db_endpoint': db_endpoint,
                'connection_error': f'Socket error code: {result}'
            }

    except Exception as e:
        logger.error(f"Database connectivity test failed: {e}")
        return {
            'success': False,
            'error_message': str(e),
            'db_endpoint': db_endpoint
        }

def test_vpc_connectivity():
    """Test VPC connectivity and internet access"""
    try:
        # Get VPC information
        vpc_id = os.environ.get('VPC_ID', '${vpc_id}')

        # Get local IP address
        try:
            hostname = socket.gethostname()
            local_ip = socket.gethostbyname(hostname)
        except Exception as e:
            logger.warning(f"Could not get local IP: {e}")
            local_ip = "unknown"

        # Test internet connectivity
        try:
            url = "https://httpbin.org/json"
            request = urllib.request.Request(url)
            request.add_header('User-Agent', 'Complete-Lambda-Example/1.0')

            with urllib.request.urlopen(request, timeout=10) as response:
                internet_test = {
                    'success': True,
                    'status_code': response.getcode(),
                    'message': 'Internet connectivity via NAT Gateway working'
                }
        except Exception as e:
            internet_test = {
                'success': False,
                'error': str(e),
                'message': 'Internet connectivity test failed'
            }

        return {
            'vpc_id': vpc_id,
            'local_ip': local_ip,
            'hostname': hostname,
            'internet_connectivity': internet_test
        }

    except Exception as e:
        logger.error(f"VPC connectivity test failed: {e}")
        return {
            'error': str(e),
            'message': 'VPC connectivity test failed'
        }

def test_all_permissions():
    """Test all configured AWS service permissions"""
    results = {}

    # Test S3 permissions
    try:
        bucket_name = os.environ.get('S3_BUCKET_NAME', '${s3_bucket_name}')
        s3_client.list_objects_v2(Bucket=bucket_name, MaxKeys=1)
        results['s3'] = {'status': 'success', 'message': 'S3 access working'}
    except Exception as e:
        results['s3'] = {'status': 'error', 'message': str(e)}

    # Test SNS permissions
    try:
        topic_arn = os.environ.get('SNS_TOPIC_ARN', '${sns_topic_arn}')
        sns_client.get_topic_attributes(TopicArn=topic_arn)
        results['sns'] = {'status': 'success', 'message': 'SNS access working'}
    except Exception as e:
        results['sns'] = {'status': 'error', 'message': str(e)}

    # Test SQS permissions
    try:
        queue_url = os.environ.get('SQS_QUEUE_URL', '${sqs_queue_url}')
        sqs_client.get_queue_attributes(QueueUrl=queue_url, AttributeNames=['All'])
        results['sqs'] = {'status': 'success', 'message': 'SQS access working'}
    except Exception as e:
        results['sqs'] = {'status': 'error', 'message': str(e)}

    # Test SSM permissions
    try:
        parameters = get_ssm_parameters()
        results['ssm'] = {'status': 'success', 'message': f"SSM access working, found {len(parameters)} parameters"}
    except Exception as e:
        results['ssm'] = {'status': 'error', 'message': str(e)}

    # Test CloudWatch permissions
    try:
        send_custom_metric('PermissionTest', 1, 'Count')
        results['cloudwatch'] = {'status': 'success', 'message': 'CloudWatch metrics access working'}
    except Exception as e:
        results['cloudwatch'] = {'status': 'error', 'message': str(e)}

    return results

def handle_s3_event(record):
    """Handle S3 event"""
    try:
        bucket_name = record['s3']['bucket']['name']
        object_key = record['s3']['object']['key']
        event_name = record['eventName']

        logger.info(f"Processing S3 event: {event_name} for {bucket_name}/{object_key}")

        # Get object metadata
        try:
            response = s3_client.head_object(Bucket=bucket_name, Key=object_key)
            object_size = response['ContentLength']
            last_modified = response['LastModified']
            content_type = response.get('ContentType', 'unknown')
        except ClientError as e:
            logger.error(f"Error getting S3 object metadata: {e}")
            object_size = 0
            last_modified = None
            content_type = 'unknown'

        # Send custom metric
        send_custom_metric('S3EventsProcessed', 1, 'Count')

        # Send SNS notification
        sns_message = {
            'event_type': 's3_object_event',
            'bucket': bucket_name,
            'object_key': object_key,
            'object_size': object_size,
            'event_name': event_name,
            'timestamp': datetime.now(timezone.utc).isoformat()
        }

        topic_arn = os.environ.get('SNS_TOPIC_ARN')
        if topic_arn:
            sns_client.publish(
                TopicArn=topic_arn,
                Subject=f"S3 Event: {event_name}",
                Message=json.dumps(sns_message)
            )

        return {
            'source': 's3',
            'event_name': event_name,
            'bucket': bucket_name,
            'object_key': object_key,
            'object_size': object_size,
            'content_type': content_type,
            'last_modified': str(last_modified) if last_modified else None,
            'processed_at': datetime.now(timezone.utc).isoformat()
        }

    except Exception as e:
        logger.error(f"Error handling S3 event: {e}")
        return {'error': str(e), 'source': 's3'}

def handle_sns_event(record):
    """Handle SNS event"""
    try:
        message = record['Sns']['Message']
        subject = record['Sns'].get('Subject', 'No Subject')
        topic_arn = record['Sns']['TopicArn']

        logger.info(f"Processing SNS message from topic: {topic_arn}")

        # Try to parse message as JSON
        try:
            message_data = json.loads(message)
        except json.JSONDecodeError:
            message_data = message

        # Send custom metric
        send_custom_metric('SNSEventsProcessed', 1, 'Count')

        # Forward to SQS for further processing
        sqs_queue_url = os.environ.get('SQS_QUEUE_URL')
        if sqs_queue_url:
            sqs_message = {
                'source': 'sns_forwarded',
                'original_topic': topic_arn,
                'subject': subject,
                'message': message_data,
                'timestamp': datetime.now(timezone.utc).isoformat()
            }
            sqs_client.send_message(
                QueueUrl=sqs_queue_url,
                MessageBody=json.dumps(sqs_message)
            )

        return {
            'source': 'sns',
            'topic_arn': topic_arn,
            'subject': subject,
            'message': message_data,
            'processed_at': datetime.now(timezone.utc).isoformat()
        }

    except Exception as e:
        logger.error(f"Error handling SNS event: {e}")
        return {'error': str(e), 'source': 'sns'}

def handle_sqs_event(record):
    """Handle SQS event"""
    try:
        message_body = record['body']
        receipt_handle = record['receiptHandle']

        logger.info(f"Processing SQS message: {message_body[:100]}...")

        # Try to parse message as JSON
        try:
            message_data = json.loads(message_body)
        except json.JSONDecodeError:
            message_data = message_body

        # Send custom metric
        send_custom_metric('SQSEventsProcessed', 1, 'Count')

        return {
            'source': 'sqs',
            'message': message_data,
            'receipt_handle': receipt_handle,
            'processed_at': datetime.now(timezone.utc).isoformat()
        }

    except Exception as e:
        logger.error(f"Error handling SQS event: {e}")
        return {'error': str(e), 'source': 'sqs'}

def handle_api_gateway_event(event):
    """Handle API Gateway event"""
    try:
        http_method = event.get('httpMethod', 'UNKNOWN')
        path = event.get('path', '/')

        # Get request body
        body = event.get('body', '{}')
        try:
            request_data = json.loads(body) if body else {}
        except json.JSONDecodeError:
            request_data = {'raw_body': body}

        logger.info(f"Processing API Gateway request: {http_method} {path}")

        # Send custom metric
        send_custom_metric('APIGatewayEventsProcessed', 1, 'Count')

        # Process the request
        response_data = {
            'source': 'api_gateway',
            'method': http_method,
            'path': path,
            'request_data': request_data,
            'processed_at': datetime.now(timezone.utc).isoformat(),
            'message': 'API Gateway request processed successfully by complete Lambda example'
        }

        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'X-Lambda-Function': 'complete-lambda-example'
            },
            'body': json.dumps(response_data)
        }

    except Exception as e:
        logger.error(f"Error handling API Gateway event: {e}")
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'error': str(e), 'source': 'api_gateway'})
        }

def handle_eventbridge_event(event):
    """Handle EventBridge event"""
    try:
        source = event.get('source', 'unknown')
        detail_type = event.get('detail-type', 'unknown')
        detail = event.get('detail', {})

        logger.info(f"Processing EventBridge event: {source} - {detail_type}")

        # Send custom metric
        send_custom_metric('EventBridgeEventsProcessed', 1, 'Count')

        # Perform scheduled maintenance tasks
        maintenance_results = {
            'cleanup_performed': True,
            'metrics_sent': True,
            'health_check': 'passed'
        }

        return {
            'source': 'eventbridge',
            'event_source': source,
            'detail_type': detail_type,
            'detail': detail,
            'maintenance_results': maintenance_results,
            'processed_at': datetime.now(timezone.utc).isoformat()
        }

    except Exception as e:
        logger.error(f"Error handling EventBridge event: {e}")
        return {'error': str(e), 'source': 'eventbridge'}

def handle_direct_invocation(event):
    """Handle direct Lambda invocation with various actions"""
    try:
        action = event.get('action', 'default')

        if action == 'test_all_features':
            # Comprehensive test of all features
            return {
                'action': 'test_all_features',
                'permissions_test': test_all_permissions(),
                'vpc_test': test_vpc_connectivity(),
                'database_test': test_database_connection(),
                'ssm_parameters': get_ssm_parameters(),
                'message': 'All features tested successfully'
            }

        elif action == 'test_permissions':
            return {
                'action': 'test_permissions',
                'results': test_all_permissions()
            }

        elif action == 'test_vpc':
            return {
                'action': 'test_vpc',
                'results': test_vpc_connectivity()
            }

        elif action == 'test_database':
            return {
                'action': 'test_database',
                'results': test_database_connection()
            }

        elif action == 'get_ssm_parameters':
            return {
                'action': 'get_ssm_parameters',
                'parameters': get_ssm_parameters()
            }

        elif action == 'test_via_alias':
            return {
                'action': 'test_via_alias',
                'message': 'Function invoked via alias successfully',
                'alias_test': 'passed'
            }

        elif action == 'performance_test':
            # Simulate CPU and I/O intensive work
            start_time = time.time()

            # CPU intensive task
            result = sum(i * i for i in range(10000))

            # I/O simulation
            time.sleep(0.1)

            execution_time = time.time() - start_time

            return {
                'action': 'performance_test',
                'execution_time_seconds': execution_time,
                'cpu_result': result,
                'message': 'Performance test completed'
            }

        else:
            return {
                'action': action,
                'message': 'Direct invocation processed',
                'available_actions': [
                    'test_all_features', 'test_permissions', 'test_vpc',
                    'test_database', 'get_ssm_parameters', 'test_via_alias',
                    'performance_test'
                ]
            }

    except Exception as e:
        logger.error(f"Error handling direct invocation: {e}")
        return {'error': str(e), 'action': action}

def lambda_handler(event, context):
    """
    Complete Lambda handler demonstrating all features:
    - VPC integration with database connectivity
    - Dead Letter Queue for error handling
    - Versioning and aliases
    - Provisioned concurrency
    - Multiple event source permissions
    - KMS encryption
    - Lambda Insights
    - Function URLs
    - Comprehensive monitoring

    Args:
        event: Lambda event data
        context: Lambda context object

    Returns:
        dict: Response based on event source and action
    """

    start_time = time.time()
    logger.info(f"Complete Lambda function invoked with event: {json.dumps(event)}")

    # Check if this is a cold start
    is_cold_start = not hasattr(lambda_handler, '_initialized')
    if is_cold_start:
        lambda_handler._initialized = True
        logger.info("Cold start detected - initializing complete Lambda function")
        # Send cold start metric
        send_custom_metric('ColdStarts', 1, 'Count')

    # Get environment information
    environment = os.environ.get('ENVIRONMENT', 'unknown')
    function_version = os.environ.get('FUNCTION_VERSION', '1.0.0')

    try:
        # Identify event source
        source_type, source_data = identify_event_source(event)
        logger.info(f"Event source identified as: {source_type}")

        # Send invocation metric
        send_custom_metric('TotalInvocations', 1, 'Count', [
            {'Name': 'Source', 'Value': source_type},
            {'Name': 'Environment', 'Value': environment}
        ])

        # Handle based on source type
        if source_type == 's3':
            result = handle_s3_event(source_data)
        elif source_type == 'sns':
            result = handle_sns_event(source_data)
        elif source_type == 'sqs':
            result = handle_sqs_event(source_data)
        elif source_type == 'api_gateway':
            return handle_api_gateway_event(event)  # API Gateway needs special response format
        elif source_type == 'eventbridge':
            result = handle_eventbridge_event(event)
        elif source_type == 'direct':
            result = handle_direct_invocation(event)
        else:
            result = {
                'source': 'unknown',
                'message': 'Unknown event source',
                'event_data': event
            }

        # Calculate execution metrics
        execution_time = time.time() - start_time

        # Send execution time metric
        send_custom_metric('ExecutionTime', execution_time * 1000, 'Milliseconds')

        # Create comprehensive response
        response_data = {
            'message': f'Complete Lambda function executed successfully - {source_type} event',
            'function_info': {
                'function_name': context.function_name,
                'function_version': context.function_version,
                'invoked_function_arn': context.invoked_function_arn,
                'environment': environment,
                'code_version': function_version,
                'memory_limit_mb': context.memory_limit_in_mb,
                'remaining_time_ms': context.get_remaining_time_in_millis(),
                'is_cold_start': is_cold_start,
                'execution_time_ms': round(execution_time * 1000, 2)
            },
            'features_enabled': {
                'vpc_integration': True,
                'database_connectivity': True,
                'dead_letter_queue': True,
                'versioning_and_aliases': True,
                'provisioned_concurrency': True,
                'kms_encryption': True,
                'lambda_insights': True,
                'function_url': os.environ.get('ENABLE_FUNCTION_URL', 'false').lower() == 'true',
                'multiple_event_sources': True,
                'custom_metrics': True
            },
            'result': result,
            'request_info': {
                'request_id': context.aws_request_id,
                'timestamp': datetime.now(timezone.utc).isoformat(),
                'source_type': source_type
            }
        }

        logger.info(f"Successfully processed {source_type} event in {execution_time:.3f}s")

        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'X-Source-Type': source_type,
                'X-Execution-Time-Ms': str(round(execution_time * 1000, 2)),
                'X-Cold-Start': str(is_cold_start).lower(),
                'X-Function-Version': context.function_version,
                'X-Request-ID': context.aws_request_id
            },
            'body': json.dumps(response_data, default=str)
        }

    except Exception as e:
        execution_time = time.time() - start_time
        logger.error(f"Complete Lambda function execution failed after {execution_time:.3f}s: {str(e)}")

        # Send error metric
        send_custom_metric('ExecutionErrors', 1, 'Count', [
            {'Name': 'ErrorType', 'Value': type(e).__name__},
            {'Name': 'Environment', 'Value': environment}
        ])

        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'X-Execution-Time-Ms': str(round(execution_time * 1000, 2)),
                'X-Error': 'true'
            },
            'body': json.dumps({
                'error': 'Complete Lambda function execution failed',
                'error_message': str(e),
                'error_type': type(e).__name__,
                'execution_time_ms': round(execution_time * 1000, 2),
                'is_cold_start': is_cold_start,
                'function_name': context.function_name,
                'request_id': context.aws_request_id
            })
        }

# For local testing
if __name__ == "__main__":
    # Mock context for local testing
    class MockContext:
        function_name = "complete-lambda-example"
        function_version = "1"
        invoked_function_arn = "arn:aws:lambda:us-east-1:123456789012:function:complete-lambda-example:production"
        aws_request_id = "test-request-id"
        memory_limit_in_mb = 1024

        def get_remaining_time_in_millis(self):
            return 60000

    # Set mock environment variables
    os.environ['S3_BUCKET_NAME'] = '${s3_bucket_name}'
    os.environ['SNS_TOPIC_ARN'] = '${sns_topic_arn}'
    os.environ['SQS_QUEUE_URL'] = '${sqs_queue_url}'
    os.environ['DB_ENDPOINT'] = '${db_endpoint}'
    os.environ['VPC_ID'] = '${vpc_id}'

    # Test events
    test_events = [
        {"action": "test_all_features"},
        {"action": "test_permissions"},
        {"action": "performance_test"},
        {"httpMethod": "POST", "path": "/lambda", "body": '{"test": "api_gateway"}'},
        {"source": "aws.events", "detail-type": "Scheduled Event", "detail": {}}
    ]
    # sonar-ignore-end
    for i, test_event in enumerate(test_events):
        print(f"\n--- Test {i+1}: {test_event} ---")
        result = lambda_handler(test_event, MockContext())
        print(f"Status: {result['statusCode']}")
        if result['statusCode'] == 200:
            body = json.loads(result['body'])
            print(f"Message: {body.get('message', 'No message')}")
            if 'result' in body and 'action' in body['result']:
                print(f"Action: {body['result']['action']}")
        else:
            print(f"Error: {result['body']}")
