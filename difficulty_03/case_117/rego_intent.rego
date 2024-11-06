package terraform.validation

default has_aws_iam_policy_document_topic = false
default has_aws_sns_topic = false
default has_aws_s3_bucket = false
default has_aws_s3_bucket_notification = false

has_aws_iam_policy_document_topic {
    policy := input.planned_values.root_module.resources[_]
    policy.type == "aws_iam_policy_document"
}

has_aws_sns_topic {
    topic := input.planned_values.root_module.resources[_]
    topic.type == "aws_sns_topic"
    topic.name == "topic"
    topic.values.name == "s3-event-notification-topic"
    topic.values.policy == input.planned_values.root_module.resources[_].values.json  # Validate policy is correctly used from data source
}

has_aws_s3_bucket {
    bucket := input.planned_values.root_module.resources[_]
    bucket.type == "aws_s3_bucket"
    bucket.name == "bucket"
    bucket.values.bucket == "your-bucket-name"
}

has_aws_s3_bucket_notification {
    notification := input.planned_values.root_module.resources[_]
    notification.type == "aws_s3_bucket_notification"
    notification.name == "bucket_notification"
    notification.values.bucket == input.planned_values.root_module.resources[_].values.id  # Correct bucket ID reference
    notification.values.topic.topic_arn == input.planned_values.root_module.resources[_].values.arn  # Correct topic ARN reference
    notification.values.topic.events[0] == "s3:ObjectCreated:*"
    notification.values.topic.filter_suffix == ".log"
}

valid_configuration {
    has_aws_iam_policy_document_topic
    has_aws_sns_topic
    has_aws_s3_bucket
    has_aws_s3_bucket_notification
}
