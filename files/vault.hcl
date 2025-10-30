ui            = true
api_addr      = "http://{{ GetPrivateIP }}:8200"

storage "file" {
  path = "/data/vault"
}

listener "tcp" {
  address       = "0.0.0.0:8200"
  tls_disable   = true
}

disable_mlock = %{DISABLE_MLOCK}
