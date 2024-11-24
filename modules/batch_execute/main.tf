resource "aws_iam_role" "batch" {
  name_prefix        = "BatchServiceRole_"
  description        = "Role that allows AWS Batch to call other AWS services on your behalf."
  assume_role_policy = data.aws_iam_policy_document.batch_trust_policy.json
  tags               = var.aws_tags
}

resource "aws_iam_role_policy_attachment" "batch" {
  role       = aws_iam_role.batch_svc_role.name
  policy_arn = data.aws_iam_policy.batch_service_policy.arn
}

resource "aws_batch_compute_environment" "batch" {
  compute_environment_name = "${var.id}-batch-compute-environment"
  service_role             = aws_iam_role.batch.arn
  type                     = "MANAGED"
  tags                     = var.aws_tags
  compute_resources {
    max_vcpus          = var.batch_compute.max_vcpus
    type               = var.batch_compute.type
    subnets            = keys(data.aws_subnet.vpc_private_subnets)
    security_group_ids = [data.aws_security_group.cluster.id]
    tags               = var.aws_tags
  }
  depends_on = [aws_iam_role_policy_attachment.batch_svc_policy_attachment]
}
