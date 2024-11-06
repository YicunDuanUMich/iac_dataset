provider "aws" {
  region = "us-east-1"
  alias  = "useast1"
}

# Redshift Cluster in us-east-1
resource "aws_redshift_cluster" "primary_cluster" {
  provider = aws.useast1

  cluster_identifier  = "primary-cluster"
  database_name       = "mydatabase"
  master_username     = "myusername"
  master_password     = "Mypassword1"
  node_type           = "dc2.large"
  cluster_type        = "multi-node"
  number_of_nodes     = 2
  skip_final_snapshot = true

  snapshot_copy {
    destination_region = "us-east-2"
  }

}
