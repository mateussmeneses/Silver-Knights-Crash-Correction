# Case-mismatch audit - load strings only (T-10a)

Supersedes the raw count in `docs/evidence/run-29-case-audit.txt`, which treated
embedded diagnostics as file references and so over-reported the risk.

The binary is a NUL-delimited string pool holding **both** a pre-built message and
the real load string, and the two do not always agree in case:

```
"Mesh file is corrupted.(giga-bazooka.x)"   <- message token
"giga-bazooka.X"                            <- loader token
```

Only loader tokens can cause a failed file open. Classifying on message text would
have produced the wrong rename direction for exactly these files.

**12 case differences: 12 real load mismatches / 0 already correct / 0 undetermined.**

## Real load mismatches

| Disk file | Loader asks for | Message says | Action |
|---|---|---|---|
| `mesh/blast.X` | `blast.x` | - | rename `mesh/blast.X` to `blast.x` |
| `mesh/blast2.X` | `blast2.x` | - | rename `mesh/blast2.X` to `blast2.x` |
| `mesh/icarus/bullet.X` | `bullet.x` | `bullet.x` | rename `mesh/icarus/bullet.X` to `bullet.x` |
| `mesh/force.X` | `force.x` | - | rename `mesh/force.X` to `force.x` |
| `mesh/giga/giga-bazooka.x` | `giga-bazooka.X` | `giga-bazooka.x` | rename `mesh/giga/giga-bazooka.x` to `giga-bazooka.X` |
| `png/mist.PNG` | `mist.png` | - | rename `png/mist.PNG` to `mist.png` |
| `mesh/philo/philo-gun-emb.x` | `philo-gun-emb.X` | - | rename `mesh/philo/philo-gun-emb.x` to `philo-gun-emb.X` |
| `mesh/philo/philo-option.X` | `philo-option.x` | `philo-option.x` | rename `mesh/philo/philo-option.X` to `philo-option.x` |
| `bsp/Shaft.bsp` | `shaft.bsp` | - | rename `bsp/Shaft.bsp` to `shaft.bsp` |
| `bsp/Shaft.wad` | `shaft.wad` | - | rename `bsp/Shaft.wad` to `shaft.wad` |
| `mesh/smoke.X` | `smoke.x` | - | rename `mesh/smoke.X` to `smoke.x` |
| `mesh/smoke2.X` | `smoke2.x` | - | rename `mesh/smoke2.X` to `smoke2.x` |

## Already correct

_none_

## Undetermined (needs call-site inspection)

_none_

## Severity

- `bsp/Shaft.bsp` and `bsp/Shaft.wad` are **most serious**: a `.bsp` that fails to
  open means the map cannot load at all, not merely a missing prop.
- The `.x` mesh entries (`blast`, `blast2`, `force`, `smoke`, `smoke2`,
  `philo-gun-emb`) would at worst produce a missing model - most likely an
  explosion, smoke or force effect rather than a player mech.
- `png/mist.PNG` is a character portrait texture; a miss would leave a blank
  portrait on the select screen.

## Guidance

- 12 renames are proposed, each grounded in the loader's own literal.
- Do them on a branch, in one commit, re-running this audit before and after.
- Then re-verify on **Windows**: the case-insensitive build must still load every
  asset, proving the rename did not break the reference.
- This is a **content change** to the shipped tree - a portability fix, not a bug
  fix. The original runs correctly on NTFS.
- None of this proves ext4 behaviour. Whether a failed open is fatal, degraded or
  silent is still untested (T-10b).
