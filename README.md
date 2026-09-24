# my-sqlancer-

Portable 24-hour SQLancer++ PostgreSQL baseline harness. It builds an isolated
PostgreSQL 18.3 with gcov, runs the authors' adaptive `general` generator,
captures every server-observed SQL statement, records feedback/success metrics,
collects cumulative coverage hourly, and atomically commits artifacts to NFS.

The default source is pinned to SQLancer++ commit
`0fd731fc8e08deca9efa405e56b169cc20e0fcb5` (`develop`, before the ShQveL merge)
so that the baseline cannot silently drift to LLM-enabled `main`.

## Quick start in a new container

```bash
git clone git@github.com:Nick-Morbid/my-sqlancer-.git /app/my-sqlancer-
cp /app/my-sqlancer-/config/experiment.env.example /app/my-sqlancer-/config/experiment.env
# Adjust paths/NFS/profile; no API key is required.
/app/my-sqlancer-/scripts/bootstrap.sh
/app/sqlancerpp_24h/scripts/preflight.sh
/app/sqlancerpp_24h/scripts/run_24h.sh tlp-where
```

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
