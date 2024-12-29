import json
import boto3
import os

def handler(event, context):
    return {
        "statusCode": 405,
        "body": json.dumps({"message": "Success"}),
        "headers": {
            "Content-Type": "application/json"
        }
    }