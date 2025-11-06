import boto3
import json
import time

def test_endpoint():
    # Initialize SageMaker runtime
    runtime = boto3.client('sagemaker-runtime')
    endpoint_name = "breast-cancer-endpoint"
    
    # Sample data from breast cancer dataset
    test_data = {
        "instances": [
            [17.99, 10.38, 122.8, 1001.0, 0.1184, 0.2776, 0.3001, 0.1471, 0.2419, 0.07871, 
             1.095, 0.9053, 8.589, 153.4, 0.006399, 0.04904, 0.05373, 0.01587, 0.03003, 
             0.006193, 25.38, 17.33, 184.6, 2019.0, 0.1622, 0.6656, 0.7119, 0.2654, 0.4601, 0.1189]
        ]
    }
    
    try:
        response = runtime.invoke_endpoint(
            EndpointName=endpoint_name,
            ContentType='application/json',
            Body=json.dumps(test_data)
        )
        
        result = json.loads(response['Body'].read().decode())
        print("✅ Prediction successful!")
        print(f"Result: {result}")
        return True
        
    except Exception as e:
        print(f"❌ Error testing endpoint: {e}")
        return False

if __name__ == "__main__":
    print("Testing SageMaker endpoint...")
    
    # Wait for endpoint to be ready
    print("Waiting for endpoint to be ready...")
    time.sleep(60)  # Wait 1 minute for deployment
    
    success = test_endpoint()
    if success:
        print("🎉 Pipeline test completed successfully!")
    else:
        print("💥 Pipeline test failed. Check CloudWatch logs for details.")
