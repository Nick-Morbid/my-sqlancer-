# SQLancer++ PostgreSQL baseline design

SQLancer++ is not mutation over a text corpus. Its baseline is the `general`
adaptive AST/template generator initialized with the authors' common feature
pool. The paper reports 6 statements, 10 clauses/keywords, 58 functions, 47
operators and 3 data types, plus composite function/operator/type features.

During execution it attributes every statement result to its selected feature
set. Validity feedback estimates which features are supported and suppresses
low-validity choices. The baseline must therefore start without ShQveL LLM
learning, external learned checkpoints, or `--enable-extra-features`.

Profiles supported by the pinned pre-ShQveL baseline:

- `tlp-where`: paper-style TLP WHERE logic-bug testing.
- `norec`: paper-supported NoREC logic-bug testing.
- `tlp-where-no-feedback`: TLP ablation corresponding to SQLancer++Rand.

The original pre-ShQveL SQLancer++ does not implement a `FUZZING` oracle; that
enum was added later with ShQveL. Therefore a SQLancer++-versus-ShQveL run that
uses TLP for one side and FUZZING for the other has an oracle confound and must
be labeled accordingly. Do not add the later oracle to this repository merely
to make the command names match, because that would modify the baseline.

Reference: Suyang Zhong and Manuel Rigger, "Scaling Automated Database System
Testing", Section 4, Section 5.4 and Appendix A,
https://arxiv.org/pdf/2503.21424v2.
