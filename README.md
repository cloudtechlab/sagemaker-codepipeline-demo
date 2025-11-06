Architecture Overview:

GitHub (Code) → CodePipeline → CodeBuild (Preprocessing) → SageMaker (Training) → SageMaker (Deployment) → Endpoint


Prerequisites:
AWS Account with appropriate permissions
GitHub account and repository


pip install boto3
pip install -r inference/requirements.txt
