import json
import joblib
import os

def model_fn(model_dir):
    """Load the model from model_dir"""
    model_path = os.path.join(model_dir, 'model.joblib')
    model = joblib.load(model_path)
    return model

def input_fn(request_body, request_content_type):
    """Transform input data"""
    if request_content_type == 'application/json':
        input_data = json.loads(request_body)
        return input_data
    else:
        raise ValueError(f"Unsupported content type: {request_content_type}")

def predict_fn(input_data, model):
    """Make predictions"""
    prediction = model.predict(input_data)
    return prediction

def output_fn(prediction, content_type):
    """Transform output"""
    if content_type == 'application/json':
        return json.dumps({
            'prediction': prediction.tolist(),
            'message': 'Success'
        })
    else:
        raise ValueError(f"Unsupported content type: {content_type}")
