output "basic_auth_credentials" {
  value = {for k,v in module.lambda_viewer_request : k => v.basic_auth_credentials}
}
