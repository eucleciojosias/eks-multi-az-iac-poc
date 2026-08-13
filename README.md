# EKS Multi-AZ IaC POC

Terraform infrastructure-as-code that provisions a production-shaped, multi-AZ
Amazon EKS cluster on AWS. Built as a hands-on portfolio project — cost-conscious
and easy to tear down.

## Stack

- **Terraform** with native `aws_*` resources only — no registry modules
- **Networking:** multi-AZ VPC, public + private subnets, single NAT gateway
- **Compute:** EKS managed node group on **spot** instances (private subnets),
  on a custom launch template: IMDSv2-only with hop limit 1, encrypted gp3 root
- **Security:** IRSA (OIDC), KMS secrets encryption, EKS access entries
- **Add-ons:** CoreDNS, kube-proxy, VPC CNI, EBS CSI driver
- **Ingress:** ingress-nginx behind one NLB — the cluster's single entry point,
  installed as a pinned Helm release by Terraform so `destroy` reclaims the LB
- **State:** S3 remote backend with native lockfile
- **App delivery:** lint → build → Trivy scan → ECR → `kubectl apply`, on OIDC

## Layout

Reusable infrastructure lives in a module; each environment is a thin root that
instantiates it with its own values and its own isolated state. Adding
`production` is a folder copy, not a code change.

```
api/                        # FastAPI app + Dockerfile — the deployed workload
k8s/                        # Deployment + Service manifests (<IMAGE> filled by CI)
infra/
├── Makefile                # targets take ENV=<name>
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
├── workflows/app-ci.yml    # app: lint, build, scan, push to ECR, deploy
├── actions/tf-setup/       # terraform + tflint + OIDC preamble
└── scripts/affected-envs.sh # which envs a change actually touches
.tflint.hcl                 # lint rules, shared by every env
```

## License

MIT — see [LICENSE](LICENSE).
