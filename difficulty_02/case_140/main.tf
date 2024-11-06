resource "aws_redshift_cluster" "example" {
  cluster_identifier = "redshift-cluster-1"
  node_type          = "dc2.large"
  number_of_nodes    = 2

  database_name = "mydb"
  master_username = "foo"
  master_password = "Mustbe8characters"

  skip_final_snapshot = true
}

resource "aws_redshift_usage_limit" "example" {
  cluster_identifier = aws_redshift_cluster.example.id
  feature_type       = "concurrency-scaling"
  limit_type         = "time"
  amount             = 60
}