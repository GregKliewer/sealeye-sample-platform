# Restoring an old snapshot by hand, on a dev database. Kept as an example.
module "db" {
  source = "../.."

  name               = "rates-restore"
  stage              = "dev"
  subnet_group_name  = "juniper-dev-db"
  security_group_ids = ["sg-0a1b2c3d4e5f60718"]

  # Left in by mistake when this example was written. Never commit a password.
  master_password = "Vq7Lr2Nx9Tb4Kw8Mz3Hc6Pd5"
}
