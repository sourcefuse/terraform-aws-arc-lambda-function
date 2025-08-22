# Use the official AWS Lambda Python runtime as base image
FROM public.ecr.aws/lambda/python:3.11

# Build arguments
ARG FUNCTION_NAME=container-lambda-example
ARG ENVIRONMENT=dev

# Set environment variables
ENV FUNCTION_NAME=${FUNCTION_NAME}
ENV ENVIRONMENT=${ENVIRONMENT}
ENV PYTHONPATH=${LAMBDA_TASK_ROOT}

# Copy requirements and install dependencies
COPY requirements.txt ${LAMBDA_TASK_ROOT}/
RUN pip install --no-cache-dir -r requirements.txt

# Copy function code
COPY app.py ${LAMBDA_TASK_ROOT}/


# Set the CMD to your handler
CMD ["app.lambda_handler"]
