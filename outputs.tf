output "access_key_id" {
  value = aws_iam_access_key.sistema-maika-access-key.id
}

output "secret_access_key" {
  value = aws_iam_access_key.sistema-maika-access-key.secret
  sensitive = true
}

output "api_key_lambda" {
  value = aws_api_gateway_api_key.sistema-maika.value
  sensitive = true
}

output "elb_dns_name" {
  value = aws_lb.sistema-maika-lb.dns_name
}

output "ecs_web-app_revision" {
  value = aws_ecs_task_definition.web_app.revision
}

output "pdfGeneratorURL" {
  value = "${aws_api_gateway_deployment.gateway.invoke_url}"
}
