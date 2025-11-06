import pandas as pd
import numpy as np
import argparse
import os
import json
import boto3
from sklearn.datasets import load_breast_cancer
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score, classification_report
import joblib

def generate_training_data():
    """Generate and save training data"""
    data = load_breast_cancer()
    X = pd.DataFrame(data.data, columns=data.feature_names)
    y = pd.Series(data.target)
    
    # Combine features and target
    df = X.copy()
    df['target'] = y
    
    # Save to CSV
    training_dir = '/opt/ml/input/data/training'
    os.makedirs(training_dir, exist_ok=True)
    
    training_path = os.path.join(training_dir, 'training_data.csv')
    df.to_csv(training_path, index=False)
    
    return X, y

def train():
    print("Starting model training...")
    
    # Generate training data
    X, y = generate_training_data()
    
    # Split data
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42
    )
    
    print(f"Training set size: {X_train.shape[0]}")
    print(f"Test set size: {X_test.shape[0]}")
    
    # Train model
    model = RandomForestClassifier(n_estimators=100, random_state=42)
    model.fit(X_train, y_train)
    
    # Evaluate model
    y_pred = model.predict(X_test)
    accuracy = accuracy_score(y_test, y_pred)
    
    print(f"Model accuracy: {accuracy:.4f}")
    print(classification_report(y_test, y_pred))
    
    # Save model
    model_dir = os.environ.get('SM_MODEL_DIR', '/opt/ml/model')
    os.makedirs(model_dir, exist_ok=True)
    
    model_path = os.path.join(model_dir, 'model.joblib')
    joblib.dump(model, model_path)
    
    # Save metrics
    metrics = {
        'accuracy': float(accuracy),
        'model_type': 'RandomForest',
        'dataset': 'breast_cancer',
        'training_samples': X_train.shape[0],
        'test_samples': X_test.shape[0]
    }
    
    # For SageMaker to capture metrics
    for key, value in metrics.items():
        print(f"{key}: {value}")
    
    # Save metrics file
    with open(os.path.join(model_dir, 'metrics.json'), 'w') as f:
        json.dump(metrics, f)
    
    print("Model training completed successfully!")

if __name__ == '__main__':
    train()
