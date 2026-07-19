# tflint exits non-zero when it finds issues, so any finding fails the CI job.

plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

# Provider-specific checks: invalid instance types, malformed ARNs, deprecated
# arguments, missing required attributes. Pin the version — `tflint --init`
# fails on a version that doesn't exist.
# Latest releases: https://github.com/terraform-linters/tflint-ruleset-aws/releases
plugin "aws" {
  enabled = true
  version = "0.48.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}
