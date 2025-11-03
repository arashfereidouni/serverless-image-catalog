import json
import boto3
import os
from urllib.parse import unquote_plus

rekognition = boto3.client('rekognition')
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['DYNAMODB_TABLE'])

def lambda_handler(event, context):
    for record in event['Records']:
        bucket = record['s3']['bucket']['name']
        key = unquote_plus(record['s3']['object']['key'])
        
        # Analyze image with Rekognition
        response = rekognition.detect_labels(
            Image={'S3Object': {'Bucket': bucket, 'Name': key}},
            MaxLabels=10,
            MinConfidence=80
        )
        
        labels = [label['Name'] for label in response['Labels']]
        
        # Store in DynamoDB
        table.put_item(
            Item={
                'image_id': key,
                'image_url': f's3://{bucket}/{key}',
                'labels': labels,
                'confidence_scores': {label['Name']: label['Confidence'] for label in response['Labels']}
            }
        )
    
    return {'statusCode': 200, 'body': json.dumps('Success')}