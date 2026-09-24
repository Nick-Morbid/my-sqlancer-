# Validation record

The harness was checked before its initial commit and again in its isolated
`/app/sqlancerplusplus` deployment on 2026-09-24. These checks prepare the
experiment but do not constitute a completed 24-hour run.

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

## Isolated deployment validation

- `verify_isolation.sh` confirmed that all mutable SQLancer++ and PostgreSQL
  paths stay below `/app/sqlancerplusplus`, the target is port 55434, and the
  NFS result directory is outside the local root.
- The pinned Java artifact was rebuilt locally. All three profiles passed
  command-line parsing while pointed only at the unused isolated port.
- PostgreSQL 18.3 was built from source with `--enable-coverage`, initialized
  below the isolated root, and verified by executable path, version, TCP port,
  data directory, and database name.
- A 30-second `tlp-where` end-to-end smoke run completed with the expected
  timeout status. It recorded 22,353 server-observed statements, generated
  SQL/runtime/PostgreSQL chunks, metrics, cumulative and final raw lcov data,
  SHA-256 manifests, and atomically uploaded all three artifact groups to NFS.
- Replay reconstruction recovered all 22,353 statements and the same
  77.57348% execution success rate reported by the epoch analyzer.
- Throughout validation, the concurrent ShQveL Java process and its PostgreSQL
  listener on port 55433 remained running. No validation command connected to
  that port or used `/app/my_ShQveL` as a mutable path.

## Checks required in the destination container

Machine-local facts must be checked again after cloning. Run `bootstrap.sh`,
then `preflight.sh`; do not start the formal run unless preflight prints
`READY_FOR_24H=YES`. In particular, this revalidates the PostgreSQL binary and
port, exact SQLancer++ commit, available disk space, and writable NFS mount.

The default coverage PostgreSQL uses port 55434 and a data directory under
`/app/sqlancerplusplus`. It does not reuse or modify PostgreSQL on ports 5432,
5433, or the ShQveL experiment port 55433.
