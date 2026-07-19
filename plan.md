# EKS Multi-AZ IaC POC — Infra Plan

Provision a multi-AZ Amazon EKS cluster with Terraform. Cheap to run, easy to
tear down. Part of a monorepo that will later add `api/` and `frontend/`.

## Decisions

- **IaC:** Terraform + `terraform-aws-modules/{vpc,eks}`
- **Network:** 3 AZs, public + private subnets, **single NAT** (cost saving)
- **Compute:** EKS managed node group, **SPOT**, t3.small, min 1 / desired 2 / max 3
- **State:** local first, then S3 backend with native lockfile (`use_lockfile`, no DynamoDB)

## Repo structure

```
eks-multi-az-iac-poc/
├── README.md                 # top-level: what the monorepo is
├── plan.md                   # this file
├── .gitignore                # monorepo-wide (commits the TF lock file)
├── Makefile                  # drives infra via `terraform -chdir=infra`
├── infra/                    # ← all IaC lives here
│   ├── README.md             # how to run, screenshots            (todo M6)
│   ├── versions.tf           # pinned providers + terraform version  ✅
│   ├── backend.tf            # S3 remote state, native lockfile       ✅
│   ├── providers.tf          # aws (kubernetes/helm added in M2/M3)   ✅
│   ├── variables.tf                                                # ✅
│   ├── vpc.tf                # VPC module + subnets + NAT             ✅
│   ├── eks.tf                # eks module + node group + core add-ons ✅
│   ├── eks_addons.tf         # ebs-csi driver + IRSA role         (M3, planned)
│   ├── outputs.tf            # cluster name/endpoint/region           ✅
│   ├── terraform.tfvars.example                                  # ✅
│   ├── .terraform.lock.hcl   # committed, for reproducible providers  ✅
│   ├── iam/                  # Terraform-principal least-priv policy  ✅
│   └── environments/         # (stretch) dev/staging overrides
├── api/                      # (future)
└── frontend/                 # (future)
```

Run everything from the repo root via `make` (`init`, `fmt`, `validate`, `plan`,
`apply`, `destroy`, `kubeconfig`); each target wraps `terraform -chdir=infra`.

## Prerequisites

`awscli` v2 (configured), `terraform` >= 1.9, `kubectl`, `helm`.

**Terraform principal permissions:** the IAM user/role running `apply` needs the
scoped policy in [`infra/iam/terraform-provisioner-policy.json`](infra/iam/terraform-provisioner-policy.json)
(least-privilege intent, not admin). See [`infra/iam/README.md`](infra/iam/README.md)
to attach it. The same policy (or a read-only variant for plan-only) is reused for
the CI/CD principal.

## Milestones

Each is a commit ending in a working, verifiable state.
**Status:** M0 ✅, M1 (VPC) ✅, M2 (EKS + spot nodes) ✅, M3 (add-ons: coredns/
kube-proxy/vpc-cni + ebs-csi w/ IRSA) ✅, M4 (smoke test — nginx + internet-facing
ELB, verified 200 OK externally, then torn down) ✅, M5 (remote state) ✅.
M6 (polish: README, LICENSE, tflint, Trivy scan, CI) ✅. Full lifecycle verified:
`apply` → working cluster → `destroy` → zero billable resources. Repo scrubbed of
the AWS account ID (files + history) and ready to publish.

- **M0 — Scaffolding:** ✅ **done** — root `.gitignore` + `Makefile`; `infra/`
  with `versions.tf` (TF >= 1.9, aws ~> 5.0), `providers.tf`, `variables.tf`.
  `make init && make validate` pass; committed `.terraform.lock.hcl`.
- **M1 — VPC:** `terraform-aws-modules/vpc`, 3 AZs, single NAT, k8s subnet tags.
  ✅ `apply` creates VPC/subnets/NAT.
- **M2 — EKS + nodes:** `terraform-aws-modules/eks`, pin `cluster_version`; spot
  managed node group in private subnets; `enable_irsa`; access entries for admin.
  ✅ `kubectl get nodes` shows Ready nodes across AZs.
- **M3 — Add-ons:** vpc-cni, coredns, kube-proxy, ebs-csi (IRSA).
  ✅ all pods Running; a test PVC binds.
- **M4 — Smoke test:** nginx Deployment + Service; confirm reachable. Screenshot,
  then delete.
- **M5 — Remote state:** ✅ **done (early)** — S3 bucket `eks-multi-az-iac-poc-tfstate`
  created manually (versioned, AES256, BPA on); `backend.tf` uses native lockfile
  (`use_lockfile`, no DynamoDB). `init` + `plan` clean. State object lands in S3
  on the first `apply` (M1).
- **M6 — Polish:** README with diagram + cost note; `tflint` + `trivy config`;
  (stretch) CI running `fmt`/`validate`/`plan` on PRs.

## Cost & teardown

- Single NAT + spot + t3.small are the big levers.
- **`terraform destroy` when done** — NAT + control plane bill even at 0 nodes.
- Delete any `type=LoadBalancer` Services and PVCs before destroy (orphan ELBs/EBS
  keep billing).

## Definition of done

`apply` from clean → healthy multi-AZ cluster; sample workload runs; remote S3
state; pinned versions; `destroy` leaves zero billable resources.

## Stretch (each a resume bullet)

Karpenter · AWS Load Balancer Controller + Ingress · IRSA S3 demo · Argo CD GitOps
· Prometheus/Grafana · deploy the `api/`+`frontend/` monolith to this cluster.
