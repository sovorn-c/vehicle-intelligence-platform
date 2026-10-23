# vehicle-intelligence-platform

Terraform and GitHub Actions workflows that deploy three services to Azure Container Apps as a short-lived demo. The repository holds infrastructure and deploy automation only. Application code lives in its own repositories.

Azure deployment: not yet verified.

Try it now: the free, always-on MCP endpoint is `https://vehicle-mcp.chhlatbot.com/mcp`. It is not hosted by this repository.

## What it deploys

- Three services on Azure Container Apps: the data pipeline (internal ingress only), the MCP server, and the risk agent.
- Azure Database for PostgreSQL Flexible Server 16 with the pgvector extension, and two databases, `pipeline` and `agent`.
- Azure Key Vault holding the database URLs and other app secrets.
- An Azure OpenAI account with one `chat` model deployment, used by the agent.
- Four Container Apps jobs: pipeline migrate, pipeline seed, agent seed, and agent post-deploy eval.
- A monthly subscription budget that sends alerts (created by the bootstrap root).

The application repositories:

- [`vehicle-mcp-server`](https://github.com/sovorn-c/vehicle-mcp-server)
- [`vehicle-risk-agent`](https://github.com/sovorn-c/vehicle-risk-agent)
- [`nz-vehicle-data-pipeline`](https://github.com/sovorn-c/nz-vehicle-data-pipeline)

This repository is separate so that applications ship and are tested without cloud credentials, and so that the one place with permission to change Azure is small and reviewable. It consumes released, attested images from GHCR. It builds only the pipeline image, from a pinned commit of the pipeline repository, because that repository publishes none.

## Layout

| Path | Purpose |
| --- | --- |
| `terraform/bootstrap` | Applied once from a laptop with local state. Creates the Terraform state storage, the GitHub OIDC deployer identity, and the budget. |
| `terraform/stack` | Applied and destroyed by the workflows with remote state. Creates the network, Postgres, Key Vault, Azure OpenAI, the Container Apps environment, apps, and jobs. |
| `.github/workflows` | `ci.yml`, `pipeline-image.yml`, `demo-up.yml`, `demo-down.yml`. |
| `scripts` | `check.sh` (local preflight), `run-aca-job.sh` (start a job and wait for its result), `previous-images.sh` (read the last deployed images for rollback). |

## Deploy flow

`demo-up` is started by hand with the inputs `mcp_version`, `agent_version`, and `force_gate_failure`. Only the `deploy` job runs behind the `azure` environment, so there is one approval, and a rollback never waits on a person.

```mermaid
flowchart TD
    A[gate: agent pre-deploy eval] --> B[pipeline-image: build and attest]
    B --> C[deploy: approval on environment azure]
    C --> D[resolve digests and verify attestations]
    D --> E[save previous images from Terraform outputs]
    E --> F[terraform apply]
    F --> G[run migrate and seed jobs]
    G --> H[smoke test the public MCP URL]
    H --> I[post-deploy eval job]
    I -->|both pass| J[job summary with digests and MCP URL]
    H -->|fail| K[rollback]
    I -->|fail| K
    K -->|previous images exist| L[terraform apply with previous images, then fail]
    K -->|first deploy| M[fail with message: run demo-down]
```

Database migrations are not reversed by a rollback.

`demo-down` runs `terraform destroy` and then checks that the resource group no longer exists. It requires the input `confirm` to equal `destroy-azure-demo`.

## Security posture

- Azure login uses GitHub OIDC only. No cloud credential is stored in GitHub. The federated subject is `repo:sovorn-c/vehicle-intelligence-platform:environment:azure`, so only workflows in the `azure` environment can assume the deployer identity.
- The `AZURE_*` and `TFSTATE_*` values are environment variables, not secrets.
- Every image the stack accepts must be pinned by digest. Variable validation rejects tags and `latest` before anything is planned. Before apply, the workflow verifies the build attestation of all three images with `gh attestation verify`.
- Apps read secrets from Key Vault through user-assigned managed identities. Each identity has only the roles it needs: the MCP server reads no secrets, and only the agent can call Azure OpenAI. Azure OpenAI local key auth is disabled.
- Postgres has public network access disabled and is reachable only from the VNet through a private DNS zone.
- Every app and job is capped at one replica, and apps scale to zero when idle.
- The Terraform state account disallows shared keys and public blobs.

## Local validation

`scripts/check.sh` runs `terraform fmt -check`, `terraform init -backend=false` and `validate` for both roots, `tflint`, `terraform test` (mocked providers, no Azure access), `actionlint`, `shellcheck`, and the `tests/*.test.sh` scripts. It stops at the first failure.

Tools it needs on `PATH`: `terraform` 1.9 or later, `tflint`, `actionlint`, `shellcheck`, `bash`, and `jq`. `tflint --init` downloads the azurerm ruleset, so the first run needs network access. None of it needs an Azure account. CI runs the same script on every pull request and push to `main`.

## Deploy it yourself

1. **Prerequisites.** An Azure subscription where you hold Owner, the tools `terraform`, `az`, and `gh`, and a fork or copy of this repository. The apps pull images from GHCR without registry credentials, so all three packages must be public. The `vehicle-mcp-server` package is public (an anonymous manifest pull returned 200 on 2026-10-23). The agent and pipeline packages do not exist yet. The owner makes them public when they are first published.
2. **Cost.** The stack bills while it is up. The budget (default 25, set by `budget_amount`) only sends alerts. It does not cap spend. Run `demo-down` when you finish.
3. **Bootstrap, once.** Run `az login`, then `terraform -chdir=terraform/bootstrap init` and `terraform -chdir=terraform/bootstrap apply` with `budget_contact_email` and `budget_start_date` (the first day of a month, for example `2026-11-01T00:00:00Z`). Keep the local state file safe.
4. **GitHub environment.** Create the environment `azure` with yourself as required reviewer. Add one environment variable per bootstrap output, named as the output in upper case: `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`, `TFSTATE_RESOURCE_GROUP`, and `TFSTATE_STORAGE_ACCOUNT`. If you fork, change `github_repository` so the OIDC subject matches your fork.
5. **Deploy.** Run `demo-up` with `mcp_version` and `agent_version`, then approve the `deploy` job. The job summary shows the MCP URL.
6. **Tear down.** Run `demo-down` with `confirm = destroy-azure-demo`. Bootstrap and the budget stay. Remove them with `terraform -chdir=terraform/bootstrap destroy`.
