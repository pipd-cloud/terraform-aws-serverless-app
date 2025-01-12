output "task_role" {
    description = "The IAM role for Batch tasks."
    value = aws_iam_role.task
}

output "compute_environment" {
    description = "The Batch compute environment."
    value = aws_batch_compute_environment.batch
}

output "job_queue" {
    description = "The Batch job queue."
    value = aws_batch_job_queue.batch
}
