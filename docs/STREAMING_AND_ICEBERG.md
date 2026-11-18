# Streaming + Iceberg — operator notes

## AWS: Kinesis / Firehose

| Path | When to use |
|------|-------------|
| Firehose Direct PUT → S3 | Default for "events into the lake". Simplest ops. |
| Kinesis Streams → Firehose → S3 | Need fan-out, multiple consumers, or replay from stream retention. |
| MSK → custom consumer / Firehose | Existing Kafka estate, exactly-once, multi-team topics. |

**Small files:** buffer 128 MB / 300 s (or larger) before going to Parquet/Iceberg. Firehose with tiny buffers is a leading cause of Athena cost spikes.

**Errors:** always set `error_output_prefix` and watch the CloudWatch log group. Silent failed delivery is worse than a loud failure.

**MSK:** not in this repo as a full module on purpose. Standing up MSK well needs networking, auth (IAM/SASL), and capacity planning that is org-specific. Prefer Firehose until Kafka is a real requirement.

## AWS: Iceberg

- Register tables in Glue with `table_type = ICEBERG` and correct storage descriptor formats.
- Writers (Glue Spark, EMR, Athena CTAS) must use the Iceberg catalog, not "plain Parquet overwrite".
- Schedule snapshot expiration and compaction. Metadata growth is real and shows up as slow planning.
- Put table data under Cleaned/Curated, not Raw. Raw stays immutable landing.

## GCP: Pub/Sub streaming

- Always create a DLQ topic and attach `dead_letter_policy` on the subscription.
- Prefer Pub/Sub → BigQuery (native) when the schema is stable and transforms are light.
- Use Dataflow streaming when you need Beam, windowing, or complex enrichment.
- Streaming Dataflow jobs run forever — treat cost and max_workers as first-class design inputs.

## CI

- PR checks: `fmt` + `validate` are mandatory and free of cloud credentials.
- Real `plan` only with OIDC/WIF and an environment-scoped role. Never long-lived keys in Actions.
- Never `apply` from a PR workflow.
