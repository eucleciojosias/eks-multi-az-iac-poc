# EKS Multi-AZ IaC POC

Terraform infrastructure-as-code that provisions a production-shaped, multi-AZ
Amazon EKS cluster on AWS. Built as a hands-on portfolio project — cost-conscious
and easy to tear down.

## Stack

- **Terraform** with `terraform-aws-modules/{vpc,eks}`
- **Networking:** multi-AZ VPC, public + private subnets, single NAT gateway
- **Compute:** EKS managed node group on **spot** instances (private subnets)
- **Security:** IRSA (OIDC), KMS secrets encryption, EKS access entries
- **Add-ons:** CoreDNS, kube-proxy, VPC CNI, EBS CSI driver
- **State:** S3 remote backend with native lockfile

## Layout

```
infra/          # all Terraform (VPC, EKS, add-ons, IAM policy)
Makefile        # init / plan / apply / destroy / kubeconfig
plan.md         # build plan and milestones
```

## Usage

Prerequisites: `awscli` v2, `terraform >= 1.11`, `kubectl`, `helm`, and an AWS
account. See [`infra/iam/README.md`](infra/iam/README.md) for the IAM policy the
Terraform principal needs.

```bash
make init      # terraform init
make plan      # preview changes
make apply     # provision everything
make kubeconfig
kubectl get nodes

make destroy   # tear it all down
```

> **Cost:** the EKS control plane and NAT gateway bill hourly even at zero nodes.
> Run `make destroy` when you're done. Delete any `type=LoadBalancer` Services and
> PVCs first — their ELB/EBS resources aren't managed by Terraform.

## CI

Every push and PR runs `terraform fmt`, `validate`, `tflint`, and a Trivy IaC
security scan (report-only) — all credential-free, so no AWS secrets are needed.
See [`.github/workflows/iac-ci.yml`](.github/workflows/iac-ci.yml).

## License

MIT — see [LICENSE](LICENSE).
