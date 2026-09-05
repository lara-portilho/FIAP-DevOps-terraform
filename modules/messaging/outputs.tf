output "queue_url" {
  value = aws_sqs_queue.analytics.url
}

output "queue_arn" {
  value = aws_sqs_queue.analytics.arn
}
