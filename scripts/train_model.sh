#!/bin/bash

# Script to trigger SageMaker training job
set -e

echo "Starting SageMaker training job..."

# Get region from environment or use default
REGION=${AWS_REGION:-us-east-1}
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)
JOB_NAME="breast-cancer-model-${TIMESTAMP}"

# Create training job configuration
cat > /tmp/training-job.json << EOF
{
    "TrainingJobName": "${JOB_NAME}",
    "RoleArn": "${SAGEMAKER_ROLE}",
    "AlgorithmSpecification": {
        "TrainingImage": "683313688378.dkr.ecr.${REGION}.amazonaws.com/sagemaker-scikit-learn:0.23-1-cpu-py3",
        "TrainingInputMode": "File"
    },
    "InputDataConfig": [
        {
            "ChannelName": "training",
            "DataSource": {
                "S3DataSource": {
                    "S3DataType": "S3Prefix",
                    "S3Uri": "s3://${ARTIFACT_BUCKET}/source/",
                    "S3DataDistributionType": "FullyReplicated"
                }
            },
            "ContentType": "text/csv"
        }
    ],
    "OutputDataConfig": {
        "S3OutputPath": "s3://${ARTIFACT_BUCKET}/models/"
    },
    "ResourceConfig": {
        "InstanceType": "ml.m5.large",
        "InstanceCount": 1,
        "VolumeSizeInGB": 30
    },
    "StoppingCondition": {
        "MaxRuntimeInSeconds": 3600
    },
    "HyperParameters": {
        "sagemaker_program": "train.py",
        "sagemaker_submit_directory": "s3://${ARTIFACT_BUCKET}/source/training/",
        "sagemaker_container_log_level": "20"
    }
}
EOF

echo "Starting training job: ${JOB_NAME}"
aws sagemaker create-training-job --cli-input-json file:///tmp/training-job.json

# Wait for training job to complete
echo "Waiting for training job to complete..."
aws sagemaker wait training-job-completed-or-stopped --training-job-name "${JOB_NAME}"

# Get training job status
JOB_STATUS=$(aws sagemaker describe-training-job --training-job-name "${JOB_NAME}" --query 'TrainingJobStatus' --output text)

if [ "$JOB_STATUS" = "Completed" ]; then
    echo "Training job completed successfully!"
    
    # Get model artifacts
    MODEL_ARTIFACTS=$(aws sagemaker describe-training-job --training-job-name "${JOB_NAME}" --query 'ModelArtifacts.S3ModelArtifacts' --output text)
    echo "Model artifacts: ${MODEL_ARTIFACTS}"
    
    # Create model in SageMaker
    MODEL_NAME="breast-cancer-model-${TIMESTAMP}"
    
    cat > /tmp/create-model.json << EOF
{
    "ModelName": "${MODEL_NAME}",
    "ExecutionRoleArn": "${SAGEMAKER_ROLE}",
    "PrimaryContainer": {
        "Image": "683313688378.dkr.ecr.${REGION}.amazonaws.com/sagemaker-scikit-learn:0.23-1-cpu-py3",
        "ModelDataUrl": "${MODEL_ARTIFACTS}"
    }
}
EOF
    
    aws sagemaker create-model --cli-input-json file:///tmp/create-model.json
    echo "Model created: ${MODEL_NAME}"
    
    # Create endpoint configuration
    ENDPOINT_CONFIG_NAME="breast-cancer-config-${TIMESTAMP}"
    
    cat > /tmp/endpoint-config.json << EOF
{
    "EndpointConfigName": "${ENDPOINT_CONFIG_NAME}",
    "ProductionVariants": [
        {
            "VariantName": "primary",
            "ModelName": "${MODEL_NAME}",
            "InitialInstanceCount": 1,
            "InstanceType": "ml.t2.medium",
            "InitialVariantWeight": 1.0
        }
    ]
}
EOF
    
    aws sagemaker create-endpoint-config --cli-input-json file:///tmp/endpoint-config.json
    echo "Endpoint configuration created: ${ENDPOINT_CONFIG_NAME}"
    
    # Create or update endpoint
    ENDPOINT_NAME="breast-cancer-endpoint"
    
    # Check if endpoint exists
    if aws sagemaker describe-endpoint --endpoint-name "${ENDPOINT_NAME}" > /dev/null 2>&1; then
        echo "Updating existing endpoint..."
        aws sagemaker update-endpoint --endpoint-name "${ENDPOINT_NAME}" --endpoint-config-name "${ENDPOINT_CONFIG_NAME}"
    else
        echo "Creating new endpoint..."
        aws sagemaker create-endpoint --endpoint-name "${ENDPOINT_NAME}" --endpoint-config-name "${ENDPOINT_CONFIG_NAME}"
    fi
    
    echo "Endpoint deployment initiated: ${ENDPOINT_NAME}"
    
else
    echo "Training job failed with status: ${JOB_STATUS}"
    exit 1
fi
