# my-sqlancer-

Portable 24-hour SQLancer++ PostgreSQL baseline harness. It builds an isolated
PostgreSQL 18.3 with gcov, runs the authors' adaptive `general` generator,
captures every server-observed SQL statement, records feedback/success metrics,
collects cumulative coverage hourly, and atomically commits artifacts to NFS.

## Background and purpose

This repository was prepared as the SQLancer++ baseline for a comparison with
the ShQveL experiment. ShQveL is currently being run separately with its LLM
learning and `FUZZING` oracle. The baseline here deliberately uses the
pre-ShQveL SQLancer++ revision and its ordinary adaptive feature generator:
there is no API key, documentation retrieval, learned-fragment checkpoint, or
ShQveL-only command-line option.

The intended experiment is a fresh, continuous 24-hour PostgreSQL fuzzing run.
During the run SQLancer++ generates and executes queries online, while the
harness records the generated SQL, PostgreSQL's authoritative CSV execution
log, success/failure statistics, feedback information, and cumulative
line/function/branch coverage. One epoch is committed approximately every hour
so that a stopped or interrupted run still leaves replayable data.

This is a baseline harness, not a replacement for SQLancer++ and not a copy of
the ShQveL runtime. The original pre-ShQveL revision supports the `WHERE`
(TLP) and `NOREC` oracles; it does not support ShQveL's later `FUZZING` oracle.
That oracle difference must be stated when comparing results.

The default source is pinned to SQLancer++ commit
`0fd731fc8e08deca9efa405e56b169cc20e0fcb5` (`develop`, before the ShQveL merge)
so that the baseline cannot silently drift to LLM-enabled `main`.

## Quick start in a new container

```bash
git clone git@github.com:Nick-Morbid/my-sqlancer-.git /app/sqlancerplusplus
cp /app/sqlancerplusplus/config/experiment.env.example /app/sqlancerplusplus/config/experiment.env
# Adjust paths/NFS/profile; no API key is required.
/app/sqlancerplusplus/scripts/bootstrap.sh
/app/sqlancerplusplus/scripts/preflight.sh
/app/sqlancerplusplus/scripts/run_24h.sh tlp-where
```

The container must provide Java/JDK, Maven, Git, `rsync`, `curl`, GNU build
tools, Bison/Flex, Perl, `lcov`/`genhtml`, `zstd`, Python 3, `sudo`, `ss`, and a
`postgres` system user. `bootstrap.sh` checks these prerequisites and stops
with an explicit list if anything is missing; it does not silently install OS
packages. PostgreSQL's source tarball and the SQLancer++ source are downloaded
only during bootstrap.

`bootstrap.sh` downloads/builds the pinned SQLancer++ source and builds a
separate PostgreSQL 18.3 with coverage instrumentation. It does not reuse the
existing PostgreSQL on ports 5432/5433 or the live ShQveL PostgreSQL on port
55433. `preflight.sh` must print `READY_FOR_24H=YES` before starting the formal
run. The default SQLancer++ PostgreSQL listens on 55434 and all local mutable
state is below `/app/sqlancerplusplus`.

Use `tlp-where` for the paper-style TLP experiment, `norec` for NoREC, and
`tlp-where-no-feedback` for the feedback ablation. The pinned original does not
have the later ShQveL `FUZZING` oracle. Do not enable ShQveL learning or extra
learned fragments in this baseline.

`RANDOM_SEED=-1` follows SQLancer++'s random-seed behavior. Set an explicit
non-negative seed in `experiment.env` when paired deterministic runs are
required; every run manifest records it.

Read [experiment design](docs/EXPERIMENT_DESIGN.md), [artifact layout](docs/ARTIFACT_LAYOUT.md),
[validation record](docs/VALIDATION.md), and [porting notes](docs/PORTING_FROM_SHQVEL.md)
before the formal run.

The default local deployment is self-contained under `/app/sqlancerplusplus`
and listens on PostgreSQL port 55434. It does not access the ShQveL deployment
under `/app/my_ShQveL` or its port 55433. See
[coexistence and migration](docs/COEXISTENCE_AND_MIGRATION.md) before running
multiple baselines in the same container.

## What is retained and where

For each hourly epoch, the NFS result tree contains compressed byte chunks for
SQLancer logs and PostgreSQL CSV logs, runtime output, feedback snapshots,
execution metrics, raw and compressed lcov data, checksums, and a `COMPLETE`
marker. `final-artifacts` captures the timeout boundary; `final-coverage` is
collected after a graceful PostgreSQL stop so gcov data is flushed. The replay
helpers reconstruct the server-observed SQL and execution outcomes:

```bash
/app/sqlancerplusplus/scripts/finalize_replay.sh RUN_ID
```

The local epoch is deleted only after its NFS copy passes checksum validation.
Growing logs are retained for the next epoch, which bounds disk usage without
losing data. Runtime directories (`work`, `postgres`, `spool`, `state`, `logs`,
and `replay`) are intentionally ignored by Git; only the experiment definition
and documentation belong in this repository.

## Profiles and reproducibility

- `tlp-where`: paper-style TLP `WHERE` oracle with validity feedback.
- `norec`: NoREC oracle with validity feedback.
- `tlp-where-no-feedback`: feedback ablation.

`RANDOM_SEED=-1` preserves SQLancer++'s normal random behavior. For paired
experiments, set a non-negative seed in the private `config/experiment.env`.
Each run manifest records the source commit, JAR hash, profile, duration and
seed. The formal 24-hour run is not started automatically by cloning or by
`bootstrap.sh`; it is started explicitly with `run_24h.sh`.
