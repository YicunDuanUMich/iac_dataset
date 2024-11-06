terraform {
required_providers {
aws = {
source = "hashicorp/aws"
version = "~> 5.0"
}
}
}

# Configure the AWS Provider
provider "aws" {
region = "us-east-1"
}

resource "aws_vpc" "vpc" {
cidr_block = "192.168.0.0/22"
}

data "aws_availability_zones" "azs" {
state = "available"
}

resource "aws_subnet" "subnet_az1" {
availability_zone = data.aws_availability_zones.azs.names[0]
cidr_block = "192.168.0.0/24"
vpc_id = aws_vpc.vpc.id
}

resource "aws_subnet" "subnet_az2" {
availability_zone = data.aws_availability_zones.azs.names[1]
cidr_block = "192.168.1.0/24"
vpc_id = aws_vpc.vpc.id
}

resource "aws_subnet" "subnet_az3" {
availability_zone = data.aws_availability_zones.azs.names[2]
cidr_block = "192.168.2.0/24"
vpc_id = aws_vpc.vpc.id
}

resource "aws_security_group" "sg" {
vpc_id = aws_vpc.vpc.id
}

resource "aws_kms_key" "kms" {
description = "example"
}

resource "aws_cloudwatch_log_group" "test" {
name = "msk_broker_logs"
}

resource "aws_s3_bucket" "bucket" {
bucket = "msk-broker-logs-bucket-123"
}

resource "aws_s3_bucket_ownership_controls" "example" {
bucket = aws_s3_bucket.bucket.id
rule {
object_ownership = "BucketOwnerPreferred"
}
}

resource "aws_s3_bucket_acl" "example" {
depends_on = [aws_s3_bucket_ownership_controls.example]

bucket = aws_s3_bucket.bucket.id
acl = "private"
}

data "aws_iam_policy_document" "assume_role" {
statement {
effect = "Allow"

principals {
type = "Service"
identifiers = ["firehose.amazonaws.com"]
}

actions = ["sts:AssumeRole"]
}
}

resource "aws_iam_role" "firehose_role" {
name = "firehose_test_role"
assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_kinesis_firehose_delivery_stream" "test_stream" {
name = "terraform-kinesis-firehose-msk-broker-logs-stream"
destination = "extended_s3"

extended_s3_configuration {
role_arn = aws_iam_role.firehose_role.arn
bucket_arn = aws_s3_bucket.bucket.arn
}

tags = {
LogDeliveryEnabled = "placeholder"
}

lifecycle {
ignore_changes = [
tags["LogDeliveryEnabled"],
]
}
}

resource "aws_msk_cluster" "example" {
cluster_name = "example"
kafka_version = "3.2.0"
number_of_broker_nodes = 3

broker_node_group_info {
instance_type = "kafka.t3.small"
client_subnets = [
aws_subnet.subnet_az1.id,
aws_subnet.subnet_az2.id,
aws_subnet.subnet_az3.id,
]
storage_info {
ebs_storage_info {
volume_size = 1000
}
}
security_groups = [aws_security_group.sg.id]
}

encryption_info {
encryption_at_rest_kms_key_arn = aws_kms_key.kms.arn
}

open_monitoring {
prometheus {
jmx_exporter {
enabled_in_broker = true
}
node_exporter {
enabled_in_broker = true
}
}
}

logging_info {
broker_logs {
cloudwatch_logs {
enabled = true
log_group = aws_cloudwatch_log_group.test.name
}
firehose {
enabled = true
delivery_stream = aws_kinesis_firehose_delivery_stream.test_stream.name
}
s3 {
enabled = true
bucket = aws_s3_bucket.bucket.id
prefix = "logs/msk-"
}
}
}

tags = {
foo = "bar"
}
}

output "zookeeper_connect_string" {
value = aws_msk_cluster.example.zookeeper_connect_string
}

output "bootstrap_brokers_tls" {
description = "TLS connection host:port pairs"
value = aws_msk_cluster.example.bootstrap_brokers_tls
}

resource "aws_s3_bucket" "example" {
# bucket = "temporary_debezium_bucket_testing_123432423"
}

resource "aws_s3_object" "example" {
bucket = aws_s3_bucket.example.id
key = "debezium.zip"
source = "debezium-connector-mysql-2.0.1.Final-plugin.zip"
}

resource "aws_mskconnect_custom_plugin" "example" {
name = "debezium-example"
content_type = "ZIP"
location {
s3 {
bucket_arn = aws_s3_bucket.example.arn
file_key = aws_s3_object.example.key
}
}
}

resource "aws_iam_role" "aws_msk_role" {
name = "test_role"

assume_role_policy = jsonencode({
Version = "2012-10-17"
Statement = [
{
Effect = "Allow",
Principal = {
Service = "kafkaconnect.amazonaws.com"
},
Action = "sts:AssumeRole",
Condition = {
StringEquals = {
"aws:SourceAccount" : "Account-ID"
},
}
}
]
})
}

resource "aws_mskconnect_connector" "example_connector" {
name = "example"

kafkaconnect_version = "2.7.1"

capacity {
autoscaling {
mcu_count = 1
min_worker_count = 1
max_worker_count = 2

scale_in_policy {
cpu_utilization_percentage = 20
}

scale_out_policy {
cpu_utilization_percentage = 80
}
}
}

connector_configuration = {
"connector.class" = "com.github.jcustenborder.kafka.connect.simulator.SimulatorSinkConnector"
"tasks.max" = "1"
"topics" = "example"
}

kafka_cluster {
apache_kafka_cluster {
bootstrap_servers = aws_msk_cluster.example.bootstrap_brokers_tls

vpc {
security_groups = [aws_security_group.sg.id]
subnets = [aws_subnet.subnet_az1.id, aws_subnet.subnet_az2.id, aws_subnet.subnet_az3.id]
}
}
}

kafka_cluster_client_authentication {
authentication_type = "NONE"
}

kafka_cluster_encryption_in_transit {
encryption_type = "TLS"
}

plugin {
custom_plugin {
arn = aws_mskconnect_custom_plugin.example.arn
revision = aws_mskconnect_custom_plugin.example.latest_revision
}
}

service_execution_role_arn = aws_iam_role.aws_msk_role.arn
}
