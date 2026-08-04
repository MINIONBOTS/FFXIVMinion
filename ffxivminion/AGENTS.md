# FFXIVMinion Agent Guidelines

These instructions apply to the `ffxivminion` repository and all of its
subdirectories. User instructions for a specific task take precedence.

This is a mature Lua codebase with public configuration and profile formats.
Improve code you touch, but do not mass-reformat or modernize unrelated legacy
code as part of a focused change.

## 1. Preserve Behavior and Public Compatibility

- Treat existing settings, profile fields, globals, event names, task names,
  and public helper functions as compatibility surfaces.
- Search all call sites before renaming, deleting, or changing return behavior.
- Preserve user-authored profiles, mesh choices, markers, and settings.
- Do not overwrite a user's configured value merely because a new default is
  available. Migrations must be explicit and versioned.
- Keep public, manually curated behavior in this public repository when users
  need to inspect or edit it.
- Do not revert or rewrite unrelated working-tree changes. This repository is
  commonly edited alongside FFXIVLib.

## 2. Data Ownership

Before adding an immutable lookup table, determine who owns the information.

### FFXIVLib owns

- Data available from FFXIV game sheets or derivable with DuckDB SQL.
- Stable relationships between sheet rows, such as jobs, roles, actions,
  statuses, items, maps, quests, NPCs, and recipes.
- Cached access to game data. FFXIVMinion must use the public
  `FFXIVLib.API.<Domain>` functions and must not call `Data:QueryAsync()`
  directly.

### FFXIVMinion owns

- Bot behavior, task logic, GUI state, settings, profile schemas, and runtime
  state.
- Publicly curated information that is not represented correctly or completely
  by game sheets, such as navmesh default names and behavioral access
  overrides.
- Compatibility adapters required by public profiles or addons.

When data seems static:

1. Search FFXIVLib for an existing API.
2. Check `FFXIVLib/DBSchema/SheetNames.txt` and the parquet data with DuckDB.
3. Prefer one SQL-backed FFXIVLib accessor over a copied Lua dataset.
4. Add a new FFXIVLib API only when FFXIVMinion has a real call site for it.
5. Remove migration-only APIs or adapters that end up unused.

Do not move genuinely user-curated data into a private dependency. Curated
files should explain why the game data is insufficient and how users should
edit them.

Run `python tools/audit_static_data.py` after changing static data ownership.
Do not weaken its checks merely to admit a new copied game-data table.

## 3. FFXIVLib Is Asynchronous

Most FFXIVLib data accessors return `nil` on the first call while an async query
is in flight, then return the cached value on a later frame.

- Always handle `nil` without crashing.
- Arrange hot-path callers to retry naturally on later updates.
- Do not permanently cache a false conclusion made while data was pending.
- Do not spin, sleep, or block the game thread waiting for data.
- Prefer a safe temporary fallback when one frame cannot wait.
- Use public FFXIVLib APIs. Access private cache fields only for narrowly scoped
  diagnostics, never normal behavior.

## 4. Hot-Path Efficiency and GC Pressure

Assume these functions may run every frame or many times per second:

- `OnUpdate`, `InGameOnUpdate`, and draw handlers.
- Cause `evaluate` and effect `execute` methods.
- Targeting, combat, navigation, and skill-condition helpers.
- GUI functions while their windows are open.

For code on those paths:

- Do not build large table literals on every call.
- Avoid per-call closures, metatables, proxy tables, and repeated string
  construction when a direct function call works.
- Avoid repeated `EntityList`, `ActionList`, inventory, navigation, or data
  lookups in the same update. Compute once and reuse the result.
- Call `Now()` once when several comparisons in the function use the same
  timestamp.
- Throttle non-urgent work with existing timers and `TimeSince()` patterns.
- Cache expensive derived values only with a clear invalidation rule, such as
  map, job, profile, quest-state, or version changes.
- Bound caches whose keys can grow from user input or world entities.
- Do not retain stale entity objects across frames when an ID can be resolved
  again safely.
- Prefer early returns for invalid state and cheap rejection checks before
  expensive queries.

One-shot curated datasets may use direct setter calls or compact branching to
avoid leaving a large persistent Lua table behind. Release one-shot installer
namespaces after successful installation when nothing needs them afterward.

Do not trade correctness for micro-optimization. Measure or identify that code
is genuinely hot before making it harder to read.

## 5. Task and Event Discipline

- Keep cause `evaluate` functions cheap and free of irreversible side effects.
- Put state-changing actions in effect `execute` functions or explicit helpers.
- Register each event handler with a stable, unique registration name.
- Do not register handlers repeatedly from an update or draw loop.
- Keep task state on the task instance or its established namespace instead of
  introducing unrelated globals.
- Check player, game-state, entity, and GUI availability before dereferencing
  host objects.
- Preserve existing pulse and timer behavior unless the task specifically
  requires a scheduling change.

## 6. Lua 5.1 and Module Constraints

- All module code must parse as Lua 5.1.
- Do not use newer syntax such as `goto`, `//`, `&`, `|`, `~`, `<<`, or `>>`.
- Files in `module.def` are concatenated in order and compiled as one chunk.
  Test the concatenated module, not only individual files.
- The concatenated main chunk shares Lua 5.1's 200-local limit. Avoid adding
  unnecessary top-level `local` variables. Put long-lived state on the
  appropriate namespace table when practical.
- Function-scoped locals are encouraged; they do not consume the module main
  chunk's local budget.
- Save Lua source as UTF-8 without BOM. A BOM inside the concatenated chunk is
  invalid for stricter Lua 5.1 parsers.
- Add new module files to `module.def` in dependency order.
- Avoid accidental globals. This codebase has intentional legacy globals, but
  new state should have an explicit owner.

## 7. Comments and Readability

Comments should explain information the code cannot explain by itself:

- Why a workaround, override, delay, or unusual condition is necessary.
- Which state change invalidates a cache.
- Why game-sheet data is insufficient for a curated rule.
- What a magic ID represents and, when known, its source sheet or content.
- Async loading behavior that a caller must preserve.
- Compatibility behavior that looks removable but is still required.

Avoid comments that merely translate the next line into English. Update or
remove stale comments when behavior changes.

For new or substantially changed non-trivial helpers, document inputs, return
values, async/pending behavior, and important side effects. Prefer focused
functions and descriptive names over long explanatory comments.

Preserve the surrounding file's indentation and naming style. Do not combine a
behavioral change with broad whitespace or formatting churn.

## 8. Tables, Defaults, and Curated Data

- Small runtime/UI/profile tables are appropriate when they model mutable
  state or a public schema.
- Large immutable game-data tables are not appropriate in FFXIVMinion when the
  same result can come from FFXIVLib or SQL.
- Do not recreate a removed migrated dataset under a new variable name.
- Compatibility shims should be lazy, small, and backed by the owning API.
- Do not add an empty proxy table when the only consumer can call a function
  directly.
- Public curated files should use a predictable edit format and contain enough
  context for community maintenance.

## 9. Validation

Use validation proportional to the change. For normal Lua changes:

1. Run `python tools/audit_static_data.py` when available.
2. Parse every changed Lua file with a Lua 5.1-compatible parser.
3. Parse the files from `module.def` concatenated in module order.
4. Run `git diff --check`.
5. Search for stale references to removed functions, globals, and datasets.
6. Perform a targeted runtime or mocked test when behavior depends on async
   data, timers, task transitions, or profile compatibility.

Do not claim a runtime behavior is verified when only syntax was checked.
Report what was tested and any engine-only behavior that still needs an in-game
smoke test.

## 10. Change Checklist

- [ ] Existing callers and public compatibility were checked.
- [ ] Game-derived data was sourced from FFXIVLib or SQL rather than copied.
- [ ] Publicly curated behavior remains public and editable.
- [ ] Async FFXIVLib `nil` results are handled safely.
- [ ] Hot paths avoid unnecessary allocation and repeated expensive work.
- [ ] Cache invalidation and lifetime are explicit.
- [ ] Comments explain reasons, invariants, and compatibility constraints.
- [ ] Changed files and the concatenated module parse as Lua 5.1.
- [ ] Static-data audit and `git diff --check` pass.
- [ ] Unused migration helpers, wrappers, and stale references were removed.
