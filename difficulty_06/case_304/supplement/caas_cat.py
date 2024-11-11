import json
import boto3
import os

def handler(event, context):
    http_method = event["httpMethod"]
    if http_method == "GET":
        return handle_get(event)
    elif http_method == "PUT":
        return handle_put(event)
    else:
        return {
            "statusCode": 405,
            "body": json.dumps({"message": "Method not allowed"}),
            "headers": {
                "Content-Type": "application/json"
            }
        }

def handle_get(event):
    return {
        "statusCode": 200,
        "body": json.dumps({"message": "Get object successfully"}),
        "headers": {
            "Content-Type": "application/json"
        }
    }

def handle_put(event):
    return {
        "statusCode": 200,
        "body": json.dumps({"message": "Put object successfully"}),
        "headers": {
            "Content-Type": "application/json"
        }
    }