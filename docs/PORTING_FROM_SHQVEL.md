# Reused and changed from the ShQveL 24h harness

Reused: isolated coverage PostgreSQL, target identity checks, hourly rotation,
byte chunks, NFS atomic commit, raw coverage, replay extraction, disk pruning,
process-group cleanup, retry logic and fault-audit principles.

Removed: LLM configuration, documentation retrieval, token accounting and
learned-fragment checkpoints.

Added for SQLancer++: profile selection, validity-feedback statistics, explicit
prohibition of ShQveL flags, and feedback/no-feedback experiment variants.

