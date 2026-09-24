# Coexistence and migration

## Isolation from ShQveL

The default SQLancer++ deployment owns only these resources:

- local root: `/app/sqlancerplusplus`;
- PostgreSQL TCP port: `55434`;
- PostgreSQL source, installation, data, socket, logs and gcov files below the
  local root;
- NFS results: `/app/nfs/chq_data/SQLancerPlusPlus/postgres`;
- SQLancer++ Java process and its own process group.

PostgreSQL compilation defaults to two jobs (`PG_BUILD_JOBS=2`) so preparing
this baseline alongside another live experiment does not consume every CPU.

ShQveL currently uses `/app/my_ShQveL`, port 55433, and a different NFS result
tree. SQLancer++ scripts validate the managed PostgreSQL executable, port and
data directory before a run. Stop/reset helpers reject a `PG_DATA` outside
`$LOCAL_ROOT/postgres/data`. `verify_isolation.sh` additionally rejects paths
outside the local root and ports 5432, 5433, and 55433. Do not point either
configuration at the other experiment's directories.

## Migration checklist

1. Clone this repository as `/app/sqlancerplusplus`.
2. Copy `config/experiment.env.example` to `config/experiment.env` and inspect
   all absolute paths. The real file is ignored by Git.
3. Mount the Synology NFS export at `/app/nfs/chq_data` and confirm it is an NFS
   mount rather than an ordinary local directory.
4. Ensure Java/JDK, Maven, Git, `rsync`, `curl`, GNU build tools, Bison/Flex,
   Perl, `lcov`/`genhtml`, `zstd`, Python 3, `sudo`, `ss`, and the `postgres`
   system user exist. `bootstrap.sh` performs this check and reports every
   missing prerequisite.
5. Run `scripts/bootstrap.sh`. This builds an isolated coverage PostgreSQL and
   the pinned SQLancer++ source commit.
6. Run `scripts/preflight.sh`; require `READY_FOR_24H=YES`.
7. Start `scripts/run_24h.sh tlp-where` in a persistent terminal or supervisor.

Do not copy `work`, `postgres`, `spool`, `state`, `logs`, or `replay` between
containers. They are runtime artifacts. The scripts and configuration template
are the portable experiment definition.

## Small validation without disturbing a live run

Static checks (`bash -n`, Python compilation, profile inspection and baseline
commit verification) do not contact any DBMS. A true execution smoke test must
use the isolated port and data directory created by bootstrap. Never reuse the
ShQveL PostgreSQL merely to save build time because that contaminates its SQL
stream and coverage counters.
