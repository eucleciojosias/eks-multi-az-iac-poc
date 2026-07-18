# IAM for the Terraform principal

`terraform-provisioner-policy.json` is the permission set the principal running
`terraform apply` needs to provision everything in this repo (VPC, EKS, managed
node groups, add-ons, IRSA/OIDC, control-plane logs) plus read/write the S3 state
backend.

It is **scoped least-privilege intent**, not a blank `*:*`:

| Statement (Sid) | What it allows | Scoping |
|---|---|---|
| `TerraformStateBackend` | S3 read/write state + lockfile | **only** the `eks-multi-az-iac-poc-tfstate` bucket |
| `VpcNetworking` | VPC, subnets, route tables, IGW, NAT, EIP, SGs, launch templates + `ec2:Describe*` | `*` (ec2 create actions have no resource-level scoping) |
| `Eks` | cluster, node groups, add-ons, access entries | `*` |
| `IamRolesAndPoliciesForEks` | create/manage roles & policies | **prefix** `eks-multi-az-iac-poc-*` |
| `IamPassRoleToEksAndEc2` | `iam:PassRole` | conditioned to `eks`/`ec2` services |
| `IamOidcForIrsa` | OIDC provider (IRSA) | `oidc-provider/*` |
| `IamServiceLinkedRoles` | service-linked roles | conditioned to EKS services |
| `ControlPlaneLogging` | CloudWatch log groups | **only** `/aws/eks/*` |
| `KmsForEksSecretsEncryption` | create/manage/rotate the KMS key that encrypts EKS secrets | `*` (keys are created dynamically; can't pre-scope by ARN) |

## Attach it (run as an admin principal — the limited user can't grant itself)

```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
aws iam create-policy \
  --policy-name eks-multi-az-iac-poc-terraform \
  --policy-document file://infra/iam/terraform-provisioner-policy.json \
  --profile <admin>

aws iam attach-user-policy \
  --user-name eks-m-az-iac-poc \
  --policy-arn arn:aws:iam::${ACCOUNT_ID}:policy/eks-multi-az-iac-poc-terraform \
  --profile <admin>
```

Verify:
```bash
aws ec2 describe-availability-zones --region us-east-1 >/dev/null && echo "ec2 ok"
```

## Notes / expected drift

- If a specific `apply` fails on a single missing action (e.g. a new ec2 verb),
  add just that action to the relevant statement — that's the least-privilege
  maintenance loop, and better than falling back to `AdministratorAccess`.
- **KMS** covers EKS secrets envelope encryption (enabled in `eks.tf` via
  `create_kms_key = true`). It's `Resource: "*"` because the key doesn't exist
  when `kms:CreateKey` runs; the remaining actions manage/rotate/schedule-delete
  that key. To drop encryption, revert `eks.tf` and remove this statement.
- **CI/CD principal:** attach this same policy to the CI role/user for `apply`.
  For a **plan-only** CI stage, a read-only variant is enough — the `Describe*` /
  `Get*` / `List*` actions here plus S3 `GetObject`/`ListBucket` (drop the
  create/delete/update actions). Prefer an OIDC-federated role over a long-lived
  access key for CI.
