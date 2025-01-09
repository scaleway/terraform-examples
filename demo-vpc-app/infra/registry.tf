resource "scaleway_registry_namespace" "ns01" {
  name      = "ns-${var.app_name}"
  is_public = true
}

resource "null_resource" "build_and_push_image" {
  depends_on = [scaleway_registry_namespace.ns01]

  triggers = {
    registry_endpoint = scaleway_registry_namespace.ns01.endpoint
    secret_key        = var.secret_key
  }

  provisioner "local-exec" {
    command = <<EOT
      # Login to Scaleway registry
      echo "${self.triggers.secret_key}" | docker login ${self.triggers.registry_endpoint} --username nologin --password-stdin

      # Build the Docker image
      cd ..
      docker build -t ${self.triggers.registry_endpoint}/app:latest -f task-tracker/Dockerfile task-tracker

      # Push the Docker image
      docker push ${self.triggers.registry_endpoint}/app:latest
    EOT
  }
}

