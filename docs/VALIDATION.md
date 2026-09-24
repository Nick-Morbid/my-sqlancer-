# Validation record

The harness was checked before its initial commit on 2026-09-24. These checks
prepare the experiment but do not constitute a completed 24-hour run.

## Completed checks

- Every shell script passes `bash -n scripts/*.sh`.
- Every Python helper passes `python3 -m py_compile scripts/*.py`.
- SQLancer++ was built from the pinned baseline commit
  `0fd731fc8e08deca9efa405e56b169cc20e0fcb5`.
- `tlp-where`, `norec`, and `tlp-where-no-feedback` each started against a real
  PostgreSQL instance for a five-second smoke test. The expected timeout exit
  status was observed, with no command-line parsing failure.
- `preflight.sh` reported the pinned commit, found no ShQveL-only options in the
  profiles, verified the target PostgreSQL instance and NFS mount, and emitted
  `READY_FOR_24H=YES` in the preparation container.
- The repository was scanned for credentials, private keys, large artifacts,
  coverage files, database data, and experiment logs. None are included.

## Checks required in the destination container

Machine-local facts must be checked again after cloning. Run `bootstrap.sh`,
then `preflight.sh`; do not start the formal run unless preflight prints
`READY_FOR_24H=YES`. In particular, this revalidates the PostgreSQL binary and
port, exact SQLancer++ commit, available disk space, and writable NFS mount.

The default coverage PostgreSQL uses port 55433 and a data directory under
`/app/sqlancerpp_24h`. It does not reuse or modify PostgreSQL on ports 5432 or
5433.
