# Raspberry Pi 2 footprint baselines

Reference measurements of the **Pi2 (Raspberry Pi 2 Model B, ARMv7)** so that
footprint regressions are visible as numbers instead of impressions. Each file
is the raw JSON produced by `scripts/pi2_benchmark.py` on real hardware; nothing
here is estimated or extrapolated.

## Baselines

| Baseline | Version measured | Profile | Install source |
| --- | --- | --- | --- |
| `pi2-bench-0.21.3.post1.json` | `hermes-agent-iot 0.21.3.post1` | `minimal` | public PyPI (`pip install 'hermes-agent-iot[minimal]==0.21.3.post1'`) |

Hardware/OS for all files: Raspberry Pi 2 Model B (`armv7l`, ARMv7 rev 5),
Raspbian trixie, CPython 3.13.5, 921 MiB RAM, 921 MiB swap, SD card.

## What the numbers say (0.21.3.post1)

Cold-start import cost, measured in a fresh interpreter per module
(`peak_rss_kb` is that interpreter's high-water mark):

| Module | import | peak RSS |
| --- | --- | --- |
| `hermes_cli.iot_cli` | 0.68 s | 16.7 MiB |
| `agent.agent_init` | **3.87 s** | 28.7 MiB |
| `tools.registry` | 0.33 s | 16.7 MiB |

Console entry points, measured by wrapping each command in a clean parent
process (so the peak RSS belongs to the command, not to a long-lived shell):

| Command | wall | peak RSS | exit |
| --- | --- | --- | --- |
| `hermes-iot profile show` | 1.26 s | 13.1 MiB | 0 |
| `hermes --version` | 3.39 s | 22.8 MiB | 0 |
| `python -c pass` (interpreter floor) | 0.15 s | 9.1 MiB | 0 |

Reading these together: importing the agent costs ~3.9 s and lands at ~29 MiB,
so the ~3.4 s `hermes --version` is essentially "start Python, import the CLI
stack, print, exit". On an x86 host the same `agent.agent_init` import measures
~0.16 s, i.e. **ARMv7 is roughly 20x slower on cold import** — that is the
number to watch when adding import-time work to the CLI path.

`wrapper_overhead_s` in each CLI record is the measurement wrapper's own cost
(fork/exec + reading `VmHWM`), not part of the command; subtract it when
comparing against timings taken another way.

## Reproducing

On the Pi (isolated venv, no sudo needed):

```sh
python3 -m venv ~/hermes-iot-bench
~/hermes-iot-bench/bin/pip install "hermes-agent-iot[minimal]==<version>"
export HERMES_HOME=~/hermes-bench-home          # keep the run off your real config
~/hermes-iot-bench/bin/hermes-iot setup --profile minimal
scp scripts/pi2_benchmark.py pi2@<host>:/tmp/
~/hermes-iot-bench/bin/python /tmp/pi2_benchmark.py \
  --label "pi2-<version>-minimal" \
  --cli-cmd "$HOME/hermes-iot-bench/bin/hermes-iot profile show" \
  --cli-cmd "$HOME/hermes-iot-bench/bin/hermes --version" \
  --out /tmp/pi2-bench-<version>.json
```

Without `HERMES_HOME` + `setup` the CLI records exit 1 (no profile configured) —
the benchmark records exit codes rather than hiding them, so check them.

## Comparing a new run against a baseline

```sh
python3 scripts/pi2_benchmark.py --compare docs/pi2-benchmarks/pi2-bench-0.21.3.post1.json \
  --label "pi2-<new version>-minimal" --out /tmp/pi2-bench-<new version>.json
```

`--compare` prints per-metric deltas. `--max-rss-kb` turns a peak-RSS ceiling
into a non-zero exit, which is what a CI lane would gate on.

## Caveats

- Measurements are single samples on one board. Treat differences below ~10%
  as noise; re-run and compare medians before calling something a regression.
- `disk_free_*` and `loadavg` capture the moment of the run; they are context,
  not benchmarks.
- Files here are de-sensitised (`/home/<user>` collapsed to `~`). Keep it that
  way: no usernames, IPs, credentials or config contents in this directory.
