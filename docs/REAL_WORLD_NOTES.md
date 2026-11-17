# Real-World Notes (from production scars)

## AWS

### S3 layout
- One mega-bucket with `raw/`, `cleaned/`, `curated/` prefixes works until retention, encryption, or access control diverge. Separate buckets are more boring and more reliable.
- Small files kill you. Compaction (or Iceberg/Delta rewrite) is not optional once you pass a few hundred million objects.
- Lifecycle rules written on day 1 are almost always wrong after 90 days of real traffic. Revisit them.

### Glue
- Job bookmarks + late-arriving data = subtle bugs. Always have a reprocess path.
- G.1X / G.2X choice matters more than people admit. Over-provisioning workers is a silent cost leak.
- Prefer writing Iceberg tables from the job rather than crawling every night and hoping the schema stays stable.

### Redshift
- Serverless is the right default for most new platforms. Provisioned still wins for steady, high-concurrency BI with predictable load.
- Spectrum is powerful and also a performance/cost foot-gun if used as "just query the lake for everything".
- Never leave admin passwords in plain Terraform state if you can avoid it. Use Secrets Manager + random providers carefully.

### Lake Formation
- Do not turn it on on day one unless you already understand LF-Tags, hybrid access mode, and the difference between IAM and LF permissions. Many platforms stall for weeks here.
- Start with Glue Catalog + tight IAM. Add LF when you need column-level or clean cross-account sharing.

### Orchestration
- Step Functions for control plane, Glue for the heavy lifting. Keep the state machine thin.
- MWAA is fine when the team already lives in Airflow. Otherwise the operational overhead is real.

## GCP

### GCS + BigQuery
- BigQuery is the product. Design the lake around what will actually be queried, not around "we must have a lake first".
- External tables / BigLake reduce premature materialization. Use them.
- Soft delete + versioning on landing has saved more than one team from a bad deploy.

### Composer vs alternatives
- Composer environments are slow to create and non-trivial to cost-optimize. Many successful teams run Cloud Workflows + Dataflow or even Cloud Scheduler + Cloud Functions for simpler pipelines.
- Only commit to Composer when Airflow is a real requirement, not a default.

### Dataflow
- Flex Templates. Pin versions. Use a dedicated service account.
- Streaming jobs have very different cost and failure modes from batch. Treat them as different products.

### IAM
- Project-level `roles/storage.objectAdmin` is convenient and often too broad. Prefer bucket-level IAM once the platform stabilizes.

## Cross-cloud

- Terraform modules should be boring. Clever dynamic module generation makes plan output unreadable and on-call harder.
- Environment isolation (separate state, separate buckets/datasets, separate workgroups) prevents more incidents than any monitoring dashboard.
- Document the gaps you deliberately left (streaming, multi-region, advanced DQ). Future you will thank present you.
