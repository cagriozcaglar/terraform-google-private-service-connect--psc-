output "producer_service_attachment" {
  description = "The service attachment created by the producer module."
  value       = module.psc_producer.service_attachment
}

output "consumer_psc_endpoint_ip_address" {
  description = "The IP address of the consumer's PSC endpoint, used to access the producer service."
  value       = module.psc_consumer.psc_endpoint_ip_address
}

output "test_command" {
  description = "A curl command to test the connection from a VM within the consumer VPC."
  value       = "gcloud compute ssh <YOUR-VM-NAME> --zone <YOUR-VM-ZONE> --project ${var.project_id} --command 'curl ${module.psc_consumer.psc_endpoint_ip_address}'"
}
