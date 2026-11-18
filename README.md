# Modern Data Engineering Architecture — Terraform (AWS + GCP)

**Real production patterns, not marketing diagrams.**

This repo contains opinionated Terraform modules for building a modern data lakehouse on AWS and the equivalent on GCP.

## What's included

### AWS modules
| Module | Purpose |
|--------|---------|
| `s3-data-lake` | Medallion buckets (Raw / Cleaned / Curated) |
| `glue-catalog-etl` | Catalog, crawler, job roles |
| `redshift-serverless` | Warehouse + Spectrum-ready |
| `iam-data-roles` | Least-privilege lake access |
| `step-functions-orchestration` | Thin Glue orchestration |
| **`kinesis-firehose`** | Streams (optional) + Firehose → S3 |
| **`iceberg-tables`** | Glue Catalog Iceberg table defs |

### GCP modules
| Module | Purpose |
|--------|---------|
| `gcs-data-lake` | Landing / Processed / Curated |
| `bigquery-dataset` | Layered datasets |
| `iam-data-roles` | Pipeline SA |
| `composer-env` | Optional Airflow (off by default) |
| `dataflow-pipeline` | Batch Flex template skeleton |
| **`pubsub-streaming`** | Topic + sub + DLQ + optional streaming Dataflow |

### CI
`.github/workflows/terraform-plan.yml` — on PR: `terraform fmt` + `init -backend=false` + `validate` for AWS and GCP examples. Comments results on the PR. Real cloud `plan` is left as an OIDC template (never long-lived keys; never apply from PR).

## Hard lessons (short form)

- **Firehose over Streams** for most lake landing. Streams when you need fan-out. MSK only when Kafka is already a requirement.
- **Buffer 128MB / 300s** (or larger) on Firehose or you will drown in small files.
- **Iceberg by default** for tables you evolve or time-travel. Schedule compaction/snapshot expiry.
- **Pub/Sub without a DLQ** is production debt. Native Pub/Sub → BigQuery when schema is stable.
- **Streaming ≠ batch** for cost and ops. Don't treat them as the same product.

## Quick usage — streaming + Iceberg (AWS)

```hcl
module "streaming" {
  source                 = "../../modules/kinesis-firehose"
  project_name           = var.project_name
  environment            = var.environment
  destination_bucket_arn = module.data_lake.raw_bucket_arn
  create_kinesis_stream  = false
  buffering_size_mb      = 128
  buffering_interval_seconds = 300
}

module "iceberg" {
  source        = "../../modules/iceberg-tables"
  project_name  = var.project_name
  environment   = var.environment
  database_name = module.glue.glue_database_name
  tables = [{
    name     = "events_silver"
    location = "s3://${module.data_lake.cleaned_bucket_id}/events/"
    columns = [
      { name = "event_id", type = "string" },
      { name = "event_ts", type = "timestamp" }
    ]
    partition_keys = [{ name = "event_date", type = "date" }]
  }]
}
```

## Quick usage — streaming (GCP)

```hcl
module "streaming" {
  source       = "../../modules/pubsub-streaming"
  project_id   = var.project_id
  project_name = var.project_name
  environment  = var.environment
  region       = var.region
  # bigquery_table = "${var.project_id}.${module.bigquery.raw_dataset_id}.events"
  create_dataflow_streaming_job = false
}
```

## Docs

- `docs/REAL_WORLD_NOTES.md` — broader platform scars
- `docs/STREAMING_AND_ICEBERG.md` — operator notes for the new modules

## Still left out on purpose

- Full Lake Formation multi-account sharing
- Full MSK cluster module (org-specific networking/auth)
- Advanced DQ frameworks
- Multi-region active-active

---

Repo: https://github.com/Findefra/modern-data-engineering-terraform
