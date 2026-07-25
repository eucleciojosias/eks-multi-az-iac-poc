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

Reusable infrastructure lives in a module; each environment is a thin root that
instantiates it with its own values and its own isolated state. Adding
`production` is a folder copy, not a code change.

```
infra/
├── modules/eks-platform/   # the reusable composite: VPC + EKS + add-ons
└── envs/
    └── staging/            # one Terraform root per environment
        ├── backend.tf      # key = "staging/terraform.tfstate" ← isolates state
        ├── providers.tf    # the only place a provider is configured
        └── main.tf         # module "platform" + this env's values
infra/iam/                  # provisioner + CI role policies (templated)
.tflint.hcl                 # lint rules, shared by every env
Makefile                    # targets take ENV=<name>
plan.md                     # build plan and milestones
```

## Usage

Prerequisites: `awscli` v2, `terraform >= 1.11`, `kubectl`, `helm`, and an AWS
account. See [`infra/iam/README.md`](infra/iam/README.md) for the IAM policy the
Terraform principal needs.

Every target takes `ENV=<name>` and defaults to `staging`:

```bash
make init             # terraform init
make plan             # preview changes
make apply            # provision everything
make update-kubeconfig
kubectl get nodes -L topology.kubernetes.io/zone

make destroy          # tear it all down

make help             # all targets
make envs             # list available environments
make plan ENV=staging # target a specific env
```

> **Cost:** the EKS control plane and NAT gateway bill hourly even at zero nodes.
> Run `make destroy` when you're done. Delete any `type=LoadBalancer` Services and
> PVCs first — their ELB/EBS resources aren't managed by Terraform.

## CI

Every push and PR runs `terraform fmt` (recursive, so the shared module is covered
too), `tflint`, and a Trivy IaC scan (report-only) — all credential-free, so no AWS
secrets are needed. `init`/`validate`/`plan` then run against the environment root
using OIDC-federated credentials, but only on trusted refs (never a forked PR).

`apply` is manual-dispatch only and gated behind a GitHub Environment with required
reviewers; it consumes the exact plan artifact that was approved. The dispatch takes
an `environment` input selecting which `infra/envs/<name>` root to target.
See [`.github/workflows/iac-ci.yml`](.github/workflows/iac-ci.yml).

## License

MIT — see [LICENSE](LICENSE).
