# Modern Data Engineering Architecture — Terraform (AWS + GCP)

**Real production patterns, not marketing diagrams.**

This repo contains opinionated Terraform modules for building a modern data lakehouse on AWS and the equivalent on GCP.  
It is written from the perspective of someone who has lived through the pain of small-file explosions, Glue job bookmark edge cases, Redshift resize nightmares, Composer cost surprises, and Lake Formation permission hell.

## Why this exists

Most "data platform" Terraform repos are either:
- Toy examples that fall over the first time real volume hits, or
- Enterprise over-engineering that takes 6 months to deploy and is still incomplete.

This one aims for the middle: **enough structure to be production-ready, enough pragmatism that a small team can actually ship it**.

### Hard lessons baked in

**AWS**
- Separate S3 buckets (or very strict prefix + lifecycle) for Raw / Cleaned / Curated. Mixing retention and access patterns in one bucket is a common source of pain later.
- Iceberg (via Glue or S3 Tables) is the default table format for anything new. Hive-style Parquet + MSCK REPAIR is technical debt.
- Prefer Redshift Serverless unless you have predictable, high, sustained load. Provisioned clusters still win for some heavy BI workloads, but the operational tax is real.
- Lake Formation is powerful and also the #1 reason new data platforms get stuck for weeks. Start with Glue Catalog + IAM, add LF later if you actually need column/row security or cross-account sharing.
- Glue job bookmarks + small files = pain. Compaction is not optional at scale.
- Step Functions > Glue Workflows for anything non-trivial. Glue Workflows are fine for simple linear jobs; Step Functions give you proper error handling, parallel branches, and visibility.

**GCP**
- BigQuery is the center of gravity. Design around it, not around "we need a lake first".
- Cloud Composer is convenient and expensive. Many teams end up with Cloud Workflows + Dataflow or just Cloud Scheduler + Cloud Functions for simpler pipelines. Use Composer when you truly need Airflow.
- Prefer BigLake / external tables + BigQuery storage where possible. Materializing everything into BigQuery native tables is often unnecessary and costly.
- Dataflow Flex Templates > classic templates for new work.
- GCS lifecycle + Object Versioning + soft delete are your friends. Treat the landing bucket as append-only.

## Repository Structure

```
.
├── aws/
│   ├── modules/
│   │   ├── s3-data-lake/          # Medallion buckets + lifecycle + encryption
│   │   ├── glue-catalog-etl/      # Database, crawlers, jobs, IAM roles
│   │   ├── redshift-serverless/   # Namespace + workgroup + Spectrum
│   │   ├── iam-data-roles/        # Least-privilege roles for Glue/Redshift/Athena
│   │   └── step-functions-orchestration/
│   └── examples/complete/         # Full working example
├── gcp/
│   ├── modules/
│   │   ├── gcs-data-lake/         # Landing / Processed / Curated buckets
│   │   ├── bigquery-dataset/      # Datasets + tables + external tables
│   │   ├── composer-env/          # Optional managed Airflow
│   │   ├── dataflow-pipeline/     # Flex template + service account
│   │   └── iam-data-roles/
│   └── examples/complete/
└── docs/
```

## Quick Start (AWS)

```bash
cd aws/examples/complete
cp terraform.tfvars.example terraform.tfvars
# edit project, environment, region, etc.
terraform init
terraform plan
terraform apply
```

## Quick Start (GCP)

```bash
cd gcp/examples/complete
# set project_id, region, etc.
terraform init
terraform plan
terraform apply
```

## Design Principles Used Here

1. **Modules are composition units, not thin wrappers.** A module should own a coherent piece of the platform (data lake storage, catalog + ETL, warehouse, orchestration).
2. **Environment isolation by design.** Separate state, separate buckets/datasets, separate workgroups. Shared "dev/prod" resources are a recurring source of incidents.
3. **Encryption and logging on by default.** You can turn things down; you should not have to remember to turn them on.
4. **Explicit over clever.** No dynamic module generation magic that makes `terraform plan` unreadable.
5. **Idempotent and re-runnable.** Jobs and pipelines should be safe to re-execute.

## What is intentionally left out (for now)

- Full Lake Formation multi-account sharing (add when you need it)
- Streaming (Kinesis / Pub/Sub + Flink / Dataflow streaming) — modules can be extended
- Advanced data quality frameworks (Great Expectations / Soda / Glue DQ) — wire them in as jobs
- Multi-region active-active

These are real gaps. Document them in your own ADRs so future you doesn't pretend they were never considered.

## Contributing / Extending

If you add a module, include:
- A working `examples/` usage
- Clear inputs/outputs
- Notes on cost and failure modes

---

Built for people who have to operate this stuff at 2 a.m.
