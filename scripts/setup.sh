#!/bin/bash

# This script sets up the SageMaker CI/CD pipeline

# Variables
STACK_NAME="sagemaker-pipeline-demo"
GITHUB_OWNER="cloudtechlab"
GITHUB_REPO="sagemaker-codepipeline-demo"
GITHUB_BRANCH="master"
GITHUB_TOKEN="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"
REGION="us-east-1"

# Check if GitHub token is provided
if [ "$GITHUB_TOKEN" = "your-github-token" ]; then
    echo "ERROR: Please update the GITHUB_TOKEN in setup.sh with your actual GitHub token"
    echo "You can create one at: https://github.com/settings/tokens"
    exit 1
fi

echo "Creating CloudFormation stack..."
aws cloudformation create-stack \
  --stack-name $STACK_NAME \
  --template-body file://pipeline.yml \
  --parameters \
      ParameterKey=GitHubOwner,ParameterValue=$GITHUB_OWNER \
      ParameterKey=GitHubRepo,ParameterValue=$GITHUB_REPO \
      ParameterKey=GitHubBranch,ParameterValue=$GITHUB_BRANCH \
      ParameterKey=GitHubToken,ParameterValue=$GITHUB_TOKEN \
  --capabilities CAPABILITY_IAM \
  --region $REGION

echo "Stack creation initiated..."
echo "Check status with: aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION"
echo "Once complete, push your code to GitHub to trigger the pipeline:"
echo "git add . && git commit -m 'Initial commit' && git push origin main"
