# EKS Multi-AZ IaC POC — Infra Plan

Provision a multi-AZ Amazon EKS cluster with Terraform. Cheap to run, easy to
tear down. Part of a monorepo that will later add `api/` and `frontend/`.

## Decisions

- **IaC:** Terraform + `terraform-aws-modules/{vpc,eks}`
- **Network:** 3 AZs, public + private subnets, **single NAT** (cost saving)
- **Compute:** EKS managed node group, **SPOT**, t3.small, min 1 / desired 2 / max 3
- **State:** local first, then S3 backend with native locking

## Repo structure

```
eks-multi-az-iac-poc/
├── README.md                 # top-level: what the monorepo is
├── plan.md                   # this file
├── .gitignore                # monorepo-wide (commits the TF lock file)
├── Makefile                  # drives infra via `terraform -chdir=infra`
├── infra/                    # ← all IaC lives here
│   ├── README.md             # how to run, screenshots
│   ├── versions.tf           # pinned providers + terraform version
│   ├── backend.tf            # S3 backend (added in M5)
│   ├── providers.tf          # aws + kubernetes/helm
│   ├── variables.tf
│   ├── main.tf               # vpc + eks + add-ons
│   ├── outputs.tf
│   ├── terraform.tfvars.example
│   ├── .terraform.lock.hcl   # committed, for reproducible providers
│   ├── bootstrap/            # tiny root to create the S3 state bucket (M5)
│   └── environments/         # (stretch) dev/staging overrides
├── api/                      # (future)
└── frontend/                 # (future)
```

Run everything from the repo root via `make` (`init`, `fmt`, `validate`, `plan`,
`apply`, `destroy`, `kubeconfig`); each target wraps `terraform -chdir=infra`.

## Prerequisites

`awscli` v2 (configured), `terraform` >= 1.9, `kubectl`, `helm`.

## Milestones

Each is a commit ending in a working, verifiable state.

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
- **M5 — Remote state:** S3 bucket via `bootstrap/`, `init -migrate-state`.
  ✅ state in S3, `plan` clean.
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
