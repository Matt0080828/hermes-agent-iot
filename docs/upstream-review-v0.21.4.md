# Upstream review: what changed between our baseline and v0.21.4 (v2026.9.21)

Written for the Pi2/IoT fork sync. Everything below is measured with `git`/`gh` against
`NousResearch/hermes-agent`, not copied from a summary.

## Scope

| | |
| --- | --- |
| Our fork's baseline | `v2026.9.14` (upstream tag `345cd2b05`), fork version `0.21.3.post1` |
| Official install on this PC | `77ecc72bcd` (`describe` = `v2026.9.14-2018`) — a `main` snapshot from 2026-09-17 |
| Upstream target (tag) | **`v0.21.4` / tag `v2026.9.21`** = `d337b736aa`, released 2026-09-21T18:10Z |
| Upstream `main` tip | `9fe737aef2` (2026-09-22 19:47 -0700) |
| Commits behind (official install → upstream main) | **3,636** (3,155 to the v0.21.4 tag); 0 ahead |
| Diff size (official install → upstream main) | 4,181 files, +223,152 / −55,900 |
| Upstream's own window statement | since v0.21.3: 5,071 non-merge commits, 5,169 files (+312,961 / −62,855), 1,812 merged PRs, 2,116 closed issues (full curated notes deferred to v0.22.0) |

Commit mix in our window: 2,035 `fix` · 417 `test` · 294 `chore` · 232 `feat` · 203 `refactor` ·
154 `docs` · 58 `catalog` · 35 `perf` · 47 commit subjects that read as security work.

Area distribution (commit subjects): desktop 461 · gateway 269 · plugin-catalog 168 · agent 131 ·
cron 108 · kanban 95 · cli 69 · mcp 62 · plugins 58 · update 55 · skills 55 · state 48 · catalog 46 ·
auth 44 · compression 42 · codex 41 · config 39 · tools 37.

## What is in it that matters for this fork

- **Update/install pipeline** (55 commits) — we ship install guards and a Pi2 install path, so this is
  the area most likely to need fork-side re-verification after the merge.
- **Agent core** (131) — `auxiliary_client.py` (97 commits), `context_compressor.py` (40),
  `model_metadata.py` (31), `agent_init.py` (39): all files this fork also patches.
- **Gateway + platforms** (269) — `gateway/platforms/api_server.py` carries 47 commits.
- **Desktop** (461, the largest area) — including a host-wide gateway singleton lock and Desktop
  attaching to the already-running host backend instead of spawning a second one.
- **Cron / kanban / state** (108 / 95 / 48) — the low-resource surfaces we care about most.
- **Nothing Pi2/ARMv7/low-resource specific upstream**: a subject search for
  `pi2|raspberry|armv7|low-resource|minimal` returns one unrelated test-fixture commit. Our fork is the
  only place that work lives, which is why the fork delta has to be carried through by hand.

## Feature highlights from the v0.21.4 release notes

- Host-wide gateway singleton lock with a rendezvous record; Desktop attaches to the running host backend.
- One backend-owned connector operation with a setup card on Desktop, TUI and CLI.
- `--format stream-json` structured JSONL output for the CLI.
- `skills.auto_load` pins skills into every new session's prompt.
- Desktop: chat/UI font picker, one-click local engine updates, plugin uninstall from the Plugins hub.
- Gateway: `decline` behaviour for unauthorized DMs; configurable MCP discovery cap
  (`mcp.discovery_concurrency`).
- `session_search` gains after/before bounds plus an OR-relaxed recall retry;
  `hermes sessions set-journal-mode`.
- Catalog/website: LTX 2.5 and Kling O3 video entries, a page per catalog plugin and author, a dozen new
  community plugins (tailscale, ssh, shodan, terminal, rss, resetwatch, done-bell, kiwi, cognee, Octen).
- A large run of profile/multiplex isolation, cron, kanban, Desktop and `state.db` fixes.

## Conflict map for this fork (the actual cost of syncing)

- Fork-only delta: **158 files** (+16,407 / −1,810), of which **140 are not CI files**.
- Upstream changed **5,170 files** between `v2026.9.14` and `v2026.9.21`.
- **Overlap = 57 files** (7,265 insertions / 1,794 deletions upstream side). These are the files that
  need a judgement call, not a mechanical merge.

Upstream churn on the files where a mistake would hurt most:

| File | Upstream commits | Upstream diff |
| --- | --- | --- |
| `agent/auxiliary_client.py` | 97 | +870 / −328 |
| `agent/context_compressor.py` | 40 | +520 / −102 |
| `agent/model_metadata.py` | 31 | +357 / −94 |
| `gateway/platforms/api_server.py` | 47 | +348 / −63 |
| `hermes_cli/main.py` | 35 | +229 / −74 |
| `agent/agent_init.py` | 39 | +199 / −62 |
| `agent/conversation_loop.py` | 11 | +93 / −25 |
| `run_agent.py` | 16 | +75 / −26 |
| `pyproject.toml` | 5 | +22 / −3 |
| `uv.lock` | 3 | +21 / −21 |
| `hermes_cli/__init__.py` | 1 | +2 / −2 (the release version bump) |
| `toolsets.py` | 1 | +1 / −1 |

Other overlapping paths: `agent/agent_runtime_helpers.py`, `agent/chat_completion_helpers.py`,
`agent/conversation_compression.py`, `agent/transports/codex_app_server_session.py`,
`hermes_cli/{cli_info_mixin,context_switch_guard,doctor_tools,main_install_repair,main_provider_setup,model_setup_flows,model_setup_flows_custom,tools_config,web_server}.py`,
`gateway/platforms/{weixin,yuanbao}.py`, `tools/lazy_deps.py`, `package-lock.json`, `.gitignore`,
`apps/desktop/{README.md,package.json}`, plus fork-side tests and workflows.

## Resolution policy used for the sync

1. `backup/pi2-lite-before-v0.21.4-sync-20260923` ref before touching anything.
2. Merge upstream `v2026.9.21` into `pi2-lite` with `--no-ff` (no rebase, no force push).
3. For overlapping **runtime** files, take upstream's newer implementation first, then re-apply the
   fork's small delta on top (the paired facade/implementation rule — never mix a new caller with an old
   implementation).
4. Keep fork-only files (Pi2 docs, install guards, benchmark JSON, workflows) as they are; only update
   them where upstream renamed or moved something they reference.
5. Regenerate `uv.lock` / `package-lock.json` with the project resolvers instead of hand-merging.
6. Version fields move to `0.21.4.post1` (`hermes_cli/__init__.py`, `pyproject.toml`, self-referential
   extras, `uv.lock`), tag `iot-v0.21.4.post1` — **tag and PyPI publication stay behind separate
   authorization**.
7. Verify on the real Pi 2B before claiming the version is usable, and leave the docs pinned to the last
   hardware-verified version until that run happens.
