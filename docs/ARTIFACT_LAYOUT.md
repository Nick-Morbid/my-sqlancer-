# Artifact layout

Each `epoch-NN` contains byte-exact SQLancer logs, PostgreSQL CSV audit-log
chunks, runtime stdout, feedback statistics, success metrics, cumulative raw
lcov data (line/function/branch), compressed copies, checksums and upload
timing. `final-artifacts` captures timeout-boundary bytes and exit status.
`final-coverage` is collected after a graceful PostgreSQL stop to flush gcov.

An epoch is published only after SHA-256 verification on NFS and creation of a
`COMPLETE` marker. Local rotated PostgreSQL and SQLancer logs are removed only
after that commit and only when their captured files did not grow during the
upload.
`finalize_replay.sh` reconstructs the exact server-observed statement stream.
