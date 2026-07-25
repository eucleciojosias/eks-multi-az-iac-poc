# IAM policies

| File | Attaches to | Purpose |
|---|---|---|
| `terraform-provisioner-policy.json` | local operator **and the CI _apply_ role** | Full create/update/delete across VPC, EKS, IAM, KMS, logs + state access |
| `ci-plan-policy.json` | CI **_plan_** role | Read-only inspection + state lock. No mutating actions |
| `github-oidc-trust-plan.json` | trust policy of the CI _plan_ role | GitHub OIDC, scoped to the repo's environments |
| `github-oidc-trust-apply.json` | trust policy of the CI _apply_ role | GitHub OIDC, scoped to the repo's environments |

**The apply role needs the full provisioner policy** — CI runs `terraform apply`,
so it must create, update and delete. That policy is proven: it completed a real
`apply` and a full `destroy`. Do not attach `ci-plan-policy.json` to the apply
role; it has no mutating permissions and every apply would fail.

## Placeholders

Every document in this directory is committed as a **boilerplate** — this repo is
public, so no real account ID, org or bucket name is checked in. Substitute before
creating the policy:

| Placeholder | Substitute with | Appears in |
|---|---|---|
| `<ACCOUNT_ID>` | your 12-digit AWS account ID | `terraform-provisioner-policy.json`, both trust policies |
| `<PROJECT>` | the state bucket prefix (`eks-multi-az-iac-poc`) | `ci-plan-policy.json` |
| `<OWNER>@<OWNER_ID>` | GitHub org/user login and its numeric ID | both trust policies |
| `<REPO>@<REPO_ID>` | repository name and its numeric ID | both trust policies |

The trust policies use GitHub's **immutable-ID `sub` format**
(`repo:<OWNER>@<OWNER_ID>/<REPO>@<REPO_ID>:…`), so renaming the org or repo can't
hand the role to someone who claims the freed name. This claim format is opt-in —
if your repo still issues the plain `repo:OWNER/REPO:…` subject, drop the `@<ID>`
segments to match, or the role can never be assumed.

---

# How CI assumes these roles

Both roles are reached through GitHub Actions OIDC — no long-lived access keys.
The role ARNs come from environment-scoped Actions **variables**:

| Job | Workflow | GH environment | Variable | `sub` claim GitHub sends |
|---|---|---|---|---|
| plan | `tf-plan.yml` (called per env by the CI matrix) | `staging` | `AWS_PLAN_ROLE_ARN` | `…:environment:staging` |
| apply | `iac-ci.yml` | `staging-apply` | `AWS_APPLY_ROLE_ARN` | `…:environment:staging-apply` |

Because every credentialed job declares an `environment:`, the subject is always
the `environment:` form — never `pull_request` or `ref:refs/heads/main`. The
separate `-apply` environment is what carries the required-reviewer gate, so
approval happens before the apply role is ever assumed.

`tf-plan.yml` also refuses to request credentials at all for a **forked** PR
(the `IS_TRUSTED` guard) — lint still runs, but init/validate/plan are skipped.

> **Known issue — `github-oidc-trust-plan.json`:** it currently puts `sub` under
> both a `StringLike` (`…:environment:*`) and a `StringEquals`
> (`…:pull_request`, `…:ref:refs/heads/main`). IAM **ANDs** conditions on the
> same key across operators, and no single subject can satisfy both, so as
> committed this trust policy denies every assume-role. Keep only the
> `StringLike` on `sub` (matching the apply trust policy, which is correct) and
> leave `aud` under `StringEquals`.

---

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
| `IamGetServiceLinkedRoles` | read back service-linked roles | `role/aws-service-role/*` |
| `ControlPlaneLogging` | CloudWatch log groups | **only** `/aws/eks/*` |
| `LogsDescribe` | `logs:Describe*` (no resource-level scoping) | `*` |
| `KmsForEksSecretsEncryption` | create/manage/rotate the KMS key that encrypts EKS secrets | `*` (keys are created dynamically; can't pre-scope by ARN) |

## The plan policy

`ci-plan-policy.json` is the read-only counterpart, deliberately narrow:

- `ReadInfrastructureForPlan` — `Describe*` / `Get*` / `List*` across ec2, eks,
  iam, logs, kms, elasticloadbalancing and autoscaling. Nothing mutating.
- `StateBucketList` + `StateRead` — list the bucket, read
  `*/terraform.tfstate`.
- `StateLockOnly` — the one write it needs: `PutObject`/`DeleteObject` scoped to
  `*/terraform.tfstate.tflock`. S3-native state locking means the plan role can
  take and release a lock without being able to touch the state file itself.

## Attach it (run as an admin principal — the limited user can't grant itself)

```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Inject your account ID into a temp copy
sed "s/<ACCOUNT_ID>/${ACCOUNT_ID}/g" infra/iam/terraform-provisioner-policy.json > /tmp/tf-policy.json

aws iam create-policy \
  --policy-name eks-multi-az-iac-poc-terraform \
  --policy-document file:///tmp/tf-policy.json \
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

## Create the CI roles

Same idea, but the document goes in as a **trust** policy and the permission
policy is attached separately. Substitute the placeholders first (see above).

```bash
# plan role — read-only + state lock
aws iam create-role \
  --role-name eks-multi-az-iac-poc-ci-plan \
  --assume-role-policy-document file:///tmp/trust-plan.json \
  --profile <admin>

aws iam put-role-policy \
  --role-name eks-multi-az-iac-poc-ci-plan \
  --policy-name ci-plan \
  --policy-document file:///tmp/ci-plan-policy.json \
  --profile <admin>

# apply role — same trust shape, full provisioner policy attached
aws iam create-role \
  --role-name eks-multi-az-iac-poc-ci-apply \
  --assume-role-policy-document file:///tmp/trust-apply.json \
  --profile <admin>

aws iam attach-role-policy \
  --role-name eks-multi-az-iac-poc-ci-apply \
  --policy-arn arn:aws:iam::${ACCOUNT_ID}:policy/eks-multi-az-iac-poc-terraform \
  --profile <admin>
```

Then set `AWS_PLAN_ROLE_ARN` / `AWS_APPLY_ROLE_ARN` as Actions variables on the
matching GitHub environments, along with `AWS_REGION`.

## Notes / expected drift

- If a specific `apply` fails on a single missing action (e.g. a new ec2 verb),
  add just that action to the relevant statement — that's the least-privilege
  maintenance loop, and better than falling back to `AdministratorAccess`.
- **KMS** covers EKS secrets envelope encryption (enabled in `eks.tf` via
  `create_kms_key = true`). It's `Resource: "*"` because the key doesn't exist
  when `kms:CreateKey` runs; the remaining actions manage/rotate/schedule-delete
  that key. To drop encryption, revert `eks.tf` and remove this statement.
- Adding an environment under `infra/envs/` means a new GitHub environment (plus
  its `-apply` twin) and its own `AWS_*_ROLE_ARN` variables. The trust policies
  already allow `environment:*`, so they don't need editing — but that wildcard
  is the reason the *permission* policies, not the trust policies, are what keep
  the plan role harmless.
