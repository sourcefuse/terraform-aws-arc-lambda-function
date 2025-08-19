import json
import boto3
import logging
import os
import urllib.parse
from datetime import datetime
from typing import Dict, Any, List, Optional
from datetime import datetime, timezone

# Configure logging
# sonarignore:start
log_level = os.environ.get('LOG_LEVEL', 'INFO')
logging.basicConfig(level=getattr(logging, log_level))
logger = logging.getLogger(__name__)

# Initialize AWS clients
s3_client = boto3.client('s3')

# Environment variables
SOURCE_BUCKET = os.environ.get('SOURCE_BUCKET', '${source_bucket}')
DESTINATION_BUCKET = os.environ.get('DESTINATION_BUCKET', '${destination_bucket}')
DEPLOYMENT_BUCKET = os.environ.get('DEPLOYMENT_BUCKET', '')
PROCESSING_PREFIX = os.environ.get('PROCESSING_PREFIX', 'incoming/')
ENVIRONMENT = os.environ.get('ENVIRONMENT', 'dev')


def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Advanced S3 file processor Lambda function.

    This function can handle:
    1. S3 event-triggered processing
    2. Manual invocations with custom actions
    3. Batch processing operations
    4. File transformations and metadata operations
    """

    request_id = context.aws_request_id
    function_name = context.function_name
    function_version = context.function_version

    logger.info(f"Processing request {request_id} in function {function_name} v{function_version}")
    logger.info(f"Event received: {json.dumps(event, default=str)}")

    try:
        # Determine the type of invocation
        if 'Records' in event:
            # S3 event-triggered invocation
            return handle_s3_event(event, context)
        elif 'action' in event:
            # Manual invocation with specific action
            return handle_manual_action(event, context)
        else:
            # Default behavior - list and process files
            return handle_default_processing(event, context)

    except Exception as e:
        logger.error(f"Error processing request: {str(e)}", exc_info=True)
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'error': 'Internal server error',
                'message': str(e),
                'request_id': request_id,
                'function_name': function_name,
                'function_version': function_version
            })
        }


def handle_s3_event(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """Handle S3 event-triggered processing."""

    processed_files = []
    errors = []

    for record in event['Records']:
        try:
            # Extract S3 event information
            bucket_name = record['s3']['bucket']['name']
            object_key = urllib.parse.unquote_plus(record['s3']['object']['key'])
            event_name = record['eventName']

            logger.info(f"Processing S3 event: {event_name} for {bucket_name}/{object_key}")

            if event_name.startswith('ObjectCreated'):
                result = process_uploaded_file(bucket_name, object_key)
                processed_files.append(result)
            elif event_name.startswith('ObjectRemoved'):
                result = handle_file_deletion(bucket_name, object_key)
                processed_files.append(result)
            else:
                logger.warning(f"Unhandled event type: {event_name}")

        except Exception as e:
            error_msg = f"Error processing record: {str(e)}"
            logger.error(error_msg, exc_info=True)
            errors.append(error_msg)

    return {
        'statusCode': 200 if not errors else 207,  # 207 for partial success
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps({
            'message': 'S3 event processing completed',
            'processed_files': len(processed_files),
            'errors': len(errors),
            'results': processed_files,
            'error_details': errors,
            'request_id': context.aws_request_id,
            'function_name': context.function_name,
            'timestamp': datetime.now(timezone.utc).isoformat()
        })
    }


def handle_manual_action(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """Handle manual invocations with specific actions."""

    action = event.get('action', '').lower()

    if action == 'list_buckets':
        return list_all_buckets(event, context)
    elif action == 'list_objects':
        return list_bucket_objects(event, context)
    elif action == 'process_batch':
        return process_batch_files(event, context)
    elif action == 'cleanup':
        return cleanup_processed_files(event, context)
    elif action == 'health_check':
        return perform_health_check(event, context)
    elif action == 'copy_file':
        return copy_file_between_buckets(event, context)
    else:
        return {
            'statusCode': 400,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'error': 'Invalid action',
                'message': f'Unknown action: {action}',
                'available_actions': [
                    'list_buckets', 'list_objects', 'process_batch',
                    'cleanup', 'health_check', 'copy_file'
                ],
                'request_id': context.aws_request_id
            })
        }


def handle_default_processing(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """Handle default processing - list and process pending files."""

    try:
        # List objects in the source bucket with the processing prefix
        response = s3_client.list_objects_v2(
            Bucket=SOURCE_BUCKET,
            Prefix=PROCESSING_PREFIX,
            MaxKeys=10
        )

        objects = response.get('Contents', [])
        processed_files = []

        for obj in objects:
            try:
                result = process_uploaded_file(SOURCE_BUCKET, obj['Key'])
                processed_files.append(result)
            except Exception as e:
                logger.error(f"Error processing {obj['Key']}: {str(e)}")

        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'message': 'Default processing completed',
                'environment': ENVIRONMENT,
                'function_name': context.function_name,
                'function_version': context.function_version,
                'request_id': context.aws_request_id,
                'source_bucket': SOURCE_BUCKET,
                'destination_bucket': DESTINATION_BUCKET,
                'objects_found': len(objects),
                'objects_processed': len(processed_files),
                'processed_files': processed_files,
                'timestamp': datetime.now(timezone.utc).isoformat()
            })
        }

    except Exception as e:
        logger.error(f"Error in default processing: {str(e)}", exc_info=True)
        raise


def process_uploaded_file(bucket_name: str, object_key: str) -> Dict[str, Any]:
    """Process an uploaded file from S3."""

    logger.info(f"Processing file: {bucket_name}/{object_key}")

    # Get object metadata
    head_response = s3_client.head_object(Bucket=bucket_name, Key=object_key)
    file_size = head_response['ContentLength']
    last_modified = head_response['LastModified']
    content_type = head_response.get('ContentType', 'unknown')

    # Read the file content
    get_response = s3_client.get_object(Bucket=bucket_name, Key=object_key)
    content = get_response['Body'].read()

    # Process the content (example: convert to uppercase for text files)
    if content_type.startswith('text/') or object_key.endswith('.txt'):
        processed_content = content.decode('utf-8').upper()
        processed_content_bytes = processed_content.encode('utf-8')
    else:
        # For non-text files, just copy as-is
        processed_content_bytes = content

    # Generate destination key
    destination_key = object_key.replace(PROCESSING_PREFIX, 'processed/')
    if not destination_key.startswith('processed/'):
        destination_key = f"processed/{destination_key}"

    # Upload processed file to destination bucket
    s3_client.put_object(
        Bucket=DESTINATION_BUCKET,
        Key=destination_key,
        Body=processed_content_bytes,
        ContentType=content_type,
        Metadata={
            'original-bucket': bucket_name,
            'original-key': object_key,
            'processed-by': 'lambda-s3-processor',
            'processed-at': datetime.now(timezone.utc).isoformat(),
            'environment': ENVIRONMENT
        },
        Tagging=f'Environment={ENVIRONMENT}&ProcessedBy=lambda&OriginalBucket={bucket_name}'
    )

    logger.info(f"File processed and saved to: {DESTINATION_BUCKET}/{destination_key}")

    return {
        'original_file': f"{bucket_name}/{object_key}",
        'processed_file': f"{DESTINATION_BUCKET}/{destination_key}",
        'file_size': file_size,
        'content_type': content_type,
        'last_modified': last_modified.isoformat(),
        'processing_time': datetime.now(timezone.utc).isoformat()
    }


def handle_file_deletion(bucket_name: str, object_key: str) -> Dict[str, Any]:
    """Handle file deletion events."""

    logger.info(f"Handling deletion of: {bucket_name}/{object_key}")

    # Optionally clean up corresponding processed file
    destination_key = object_key.replace(PROCESSING_PREFIX, 'processed/')
    if not destination_key.startswith('processed/'):
        destination_key = f"processed/{destination_key}"

    try:
        s3_client.delete_object(Bucket=DESTINATION_BUCKET, Key=destination_key)
        logger.info(f"Cleaned up processed file: {DESTINATION_BUCKET}/{destination_key}")
        cleanup_performed = True
    except Exception as e:
        logger.warning(f"Could not clean up processed file: {str(e)}")
        cleanup_performed = False

    return {
        'deleted_file': f"{bucket_name}/{object_key}",
        'cleanup_performed': cleanup_performed,
        'cleanup_target': f"{DESTINATION_BUCKET}/{destination_key}",
        'timestamp': datetime.utcnow().isoformat()
    }


def list_all_buckets(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """List all accessible S3 buckets."""

    try:
        response = s3_client.list_buckets()
        buckets = [
            {
                'name': bucket['Name'],
                'creation_date': bucket['CreationDate'].isoformat()
            }
            for bucket in response['Buckets']
        ]

        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'message': 'Buckets listed successfully',
                'bucket_count': len(buckets),
                'buckets': buckets,
                'configured_buckets': {
                    'source': SOURCE_BUCKET,
                    'destination': DESTINATION_BUCKET,
                    'deployment': DEPLOYMENT_BUCKET
                },
                'request_id': context.aws_request_id,
                'timestamp': datetime.utcnow().isoformat()
            })
        }

    except Exception as e:
        logger.error(f"Error listing buckets: {str(e)}", exc_info=True)
        raise


def list_bucket_objects(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """List objects in specified bucket or default buckets."""

    bucket_name = event.get('bucket', SOURCE_BUCKET)
    prefix = event.get('prefix', '')
    max_keys = min(event.get('max_keys', 10), 100)  # Limit to 100

    try:
        response = s3_client.list_objects_v2(
            Bucket=bucket_name,
            Prefix=prefix,
            MaxKeys=max_keys
        )

        objects = [
            {
                'key': obj['Key'],
                'size': obj['Size'],
                'last_modified': obj['LastModified'].isoformat(),
                'etag': obj['ETag'].strip('"')
            }
            for obj in response.get('Contents', [])
        ]

        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'message': 'Objects listed successfully',
                'bucket': bucket_name,
                'prefix': prefix,
                'object_count': len(objects),
                'is_truncated': response.get('IsTruncated', False),
                'objects': objects,
                'request_id': context.aws_request_id,
                'timestamp': datetime.utcnow().isoformat()
            })
        }

    except Exception as e:
        logger.error(f"Error listing objects in {bucket_name}: {str(e)}", exc_info=True)
        raise


def process_batch_files(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """Process multiple files in batch."""

    file_keys = event.get('file_keys', [])
    bucket_name = event.get('bucket', SOURCE_BUCKET)

    if not file_keys:
        # If no specific files provided, process all files with the prefix
        response = s3_client.list_objects_v2(
            Bucket=bucket_name,
            Prefix=PROCESSING_PREFIX,
            MaxKeys=50  # Limit batch size
        )
        file_keys = [obj['Key'] for obj in response.get('Contents', [])]

    processed_files = []
    errors = []

    for file_key in file_keys:
        try:
            result = process_uploaded_file(bucket_name, file_key)
            processed_files.append(result)
        except Exception as e:
            error_msg = f"Error processing {file_key}: {str(e)}"
            logger.error(error_msg)
            errors.append(error_msg)

    return {
        'statusCode': 200 if not errors else 207,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps({
            'message': 'Batch processing completed',
            'total_files': len(file_keys),
            'processed_successfully': len(processed_files),
            'errors': len(errors),
            'processed_files': processed_files,
            'error_details': errors,
            'request_id': context.aws_request_id,
            'timestamp': datetime.utcnow().isoformat()
        })
    }


def cleanup_processed_files(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """Clean up old processed files."""

    days_old = event.get('days_old', 7)
    dry_run = event.get('dry_run', True)

    try:
        # List objects in destination bucket
        response = s3_client.list_objects_v2(
            Bucket=DESTINATION_BUCKET,
            Prefix='processed/'
        )

        objects_to_delete = []
        cutoff_date = datetime.now(timezone.utc).timestamp() - (days_old * 24 * 60 * 60)

        for obj in response.get('Contents', []):
            if obj['LastModified'].timestamp() < cutoff_date:
                objects_to_delete.append(obj['Key'])

        deleted_count = 0
        if not dry_run and objects_to_delete:
            # Delete objects in batches
            for i in range(0, len(objects_to_delete), 1000):
                batch = objects_to_delete[i:i+1000]
                delete_objects = [{'Key': key} for key in batch]

                s3_client.delete_objects(
                    Bucket=DESTINATION_BUCKET,
                    Delete={'Objects': delete_objects}
                )
                deleted_count += len(batch)

        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'message': 'Cleanup completed',
                'dry_run': dry_run,
                'days_old_threshold': days_old,
                'objects_found': len(objects_to_delete),
                'objects_deleted': deleted_count if not dry_run else 0,
                'objects_to_delete': objects_to_delete[:10],  # Show first 10
                'request_id': context.aws_request_id,
                'timestamp': datetime.utcnow().isoformat()
            })
        }

    except Exception as e:
        logger.error(f"Error during cleanup: {str(e)}", exc_info=True)
        raise


def copy_file_between_buckets(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """Copy file between buckets."""

    source_bucket = event.get('source_bucket', SOURCE_BUCKET)
    source_key = event.get('source_key')
    dest_bucket = event.get('dest_bucket', DESTINATION_BUCKET)
    dest_key = event.get('dest_key', source_key)

    if not source_key:
        return {
            'statusCode': 400,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'error': 'Missing required parameter',
                'message': 'source_key is required',
                'request_id': context.aws_request_id
            })
        }

    try:
        copy_source = {'Bucket': source_bucket, 'Key': source_key}

        s3_client.copy_object(
            CopySource=copy_source,
            Bucket=dest_bucket,
            Key=dest_key,
            MetadataDirective='REPLACE',
            Metadata={
                'copied-by': 'lambda-s3-processor',
                'copied-at': datetime.utcnow().isoformat(),
                'original-bucket': source_bucket,
                'original-key': source_key
            }
        )

        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'message': 'File copied successfully',
                'source': f"{source_bucket}/{source_key}",
                'destination': f"{dest_bucket}/{dest_key}",
                'request_id': context.aws_request_id,
                'timestamp': datetime.utcnow().isoformat()
            })
        }

    except Exception as e:
        logger.error(f"Error copying file: {str(e)}", exc_info=True)
        raise


def perform_health_check(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """Perform health check on the Lambda function and S3 access."""

    health_status = {
        'lambda_function': 'healthy',
        'source_bucket_access': 'unknown',
        'destination_bucket_access': 'unknown',
        'deployment_bucket_access': 'unknown'
    }

    # Test source bucket access
    try:
        s3_client.head_bucket(Bucket=SOURCE_BUCKET)
        health_status['source_bucket_access'] = 'healthy'
    except Exception as e:
        health_status['source_bucket_access'] = f'error: {str(e)}'

    # Test destination bucket access
    try:
        s3_client.head_bucket(Bucket=DESTINATION_BUCKET)
        health_status['destination_bucket_access'] = 'healthy'
    except Exception as e:
        health_status['destination_bucket_access'] = f'error: {str(e)}'

    # Test deployment bucket access (if configured)
    if DEPLOYMENT_BUCKET:
        try:
            s3_client.head_bucket(Bucket=DEPLOYMENT_BUCKET)
            health_status['deployment_bucket_access'] = 'healthy'
        except Exception as e:
            health_status['deployment_bucket_access'] = f'error: {str(e)}'

    overall_health = 'healthy' if all(
        status == 'healthy' for status in health_status.values()
        if not status.startswith('error')
    ) else 'degraded'

    return {
        'statusCode': 200 if overall_health == 'healthy' else 503,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        # sonarignore:end
        'body': json.dumps({
            'message': 'Health check completed',
            'overall_health': overall_health,
            'function_name': context.function_name,
            'function_version': context.function_version,
            'environment': ENVIRONMENT,
            'health_details': health_status,
            'configured_buckets': {
                'source': SOURCE_BUCKET,
                'destination': DESTINATION_BUCKET,
                'deployment': DEPLOYMENT_BUCKET
            },
            'request_id': context.aws_request_id,
            'timestamp': datetime.utcnow().isoformat()
        })
    }
