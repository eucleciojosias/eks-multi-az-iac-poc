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
.github/
├── workflows/iac-ci.yml    # orchestration only
├── workflows/tf-plan.yml   # reusable: lint/validate/plan one env
├── workflows/tf-cost.yml   # reusable: infracost diff for one env
├── actions/tf-setup/       # terraform + tflint + OIDC preamble
└── scripts/affected-envs.sh # which envs a change actually touches
.tflint.hcl                 # lint rules, shared by every env
Makefile                    # targets take ENV=<name>
```

## Usage

Prerequisites: `awscli` v2, `terraform >= 1.11`, `kubectl`, `helm`, and an AWS
account. See [`infra/iam/README.md`](infra/iam/README.md) for the IAM policy the
Terraform principal needs.

First, set the CIDRs allowed to reach the EKS API endpoint. This is required and
has no default — an unset value fails the plan rather than quietly leaving the
endpoint open to the internet:

```bash
cd infra/envs/staging
cp terraform.tfvars.example terraform.tfvars   # gitignored
curl -s https://checkip.amazonaws.com          # your IP, to put in it
```

CI doesn't use that file — it injects `TF_VAR_cluster_endpoint_public_access_cidrs`
from the GitHub Environment's variables, so no real IP is ever committed.

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

[`iac-ci.yml`](.github/workflows/iac-ci.yml) is orchestration only — each stage is a
reusable workflow or a composite action, so adding an environment costs no pipeline
code.

**1. Detect affected environments.** [`affected-envs.sh`](.github/scripts/affected-envs.sh)
diffs the changed paths against `infra/envs/<name>/` and emits a JSON matrix, so a
change to one env never spends CI minutes planning the others. A dispatch just uses
its `environment` input. The resolved list is echoed into the job log, so you can see
which envs a run picked up without digging into the step outputs. If nothing under
`infra/envs/` changed, the plan and cost stages are skipped entirely.

**2. Format & scan.** `terraform fmt` (recursive, so the shared module is covered
too), `tflint`, and a Trivy IaC scan (report-only). All credential-free — no AWS
secrets needed, so it runs on forked PRs too.

**3. Plan, one job per affected env** ([`tf-plan.yml`](.github/workflows/tf-plan.yml)),
fanned out in parallel with `fail-fast: false` so one env's failure doesn't hide
another's plan. `init`/`validate`/`plan` use OIDC-federated credentials — never a
long-lived key — and only on trusted refs; a forked PR still gets linted but is never
issued credentials.

**4. Cost diff** ([`tf-cost.yml`](.github/workflows/tf-cost.yml)) posts an Infracost
diff on same-repo PRs, which is why the workflow grants `pull-requests: write`
alongside the `id-token: write` that OIDC needs.

**5. Apply** is manual-dispatch only — merging never deploys. It's gated behind a
separate `<env>-apply` GitHub Environment with required reviewers, and consumes the
exact plan artifact that was approved. A `concurrency` group keeps applies from
racing per environment.

Each environment's `TF_VAR_*` values come from its GitHub Environment variables, and
the plan/apply role ARNs (`AWS_PLAN_ROLE_ARN` / `AWS_APPLY_ROLE_ARN`) are scoped the
same way. See [`infra/iam/README.md`](infra/iam/README.md) for the two CI roles and
their trust policies.

## License

MIT — see [LICENSE](LICENSE).
