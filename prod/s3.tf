
resource "aws_s3_bucket" "tf_backend" {
  bucket = "zico-dev-tf-backend"

  versioning {
    enabled = true
  }

  tags = {
    Name = "tf-backend"
  }
}