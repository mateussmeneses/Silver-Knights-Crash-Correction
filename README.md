# Silver Knights 0.13 — Windows 11 Recovery

Making a 2003–2012 mech arena fighter run on modern Windows, with evidence rather than guesses.

**English** · [Português abaixo](#português)

---

## ⚠️ This repository does not contain the game

Silver Knights is © 2003–2012 **Haruo Teshima (TESHIMA)**. Its own `ReadMe-English.txt` states:

> "Do not change any datas in this software without permission from the author."
> "This software is still under development, so do not distribute or upload this software."

To be precise about the current state, because it would be dishonest to imply otherwise: **the
repository's base commit already contains the full game** (it was pushed before this analysis
began, in a commit with no `.gitignore`). This project did not add those files and does not add
more; everything committed since is analysis, tooling and documentation, and the game binaries are
byte-identical to that base commit.

No **Release** asset is published. A verified archive can be built locally with
`tools/build_release.py`; whether to publish it is the repository owner's decision, and
`docs/DISTRIBUTION.md` §0 lays out what that decision actually changes.

The author's site (`philotes.sv1.sp-land.net`) **no longer resolves** as of November 2026. The
Internet Archive holds snapshots through January 2026.

What this project adds is a **patch tool** you run against your own copy, plus the documentation
and the evidence that the fix works. Screenshots are used under the author's explicit permission
for introducing the game.

---

## The problem, in one paragraph

On Windows 11 the game closes itself about **8 seconds** after launch: no error dialog, no crash
report, status 0, and a clean log. It looks like a crash and is not one. `SK-Main.exe` copies the
first 20 bytes of `winmm!timeGetTime` and compares them against the Windows 95/98/2000 machine
code. Modern `winmm` starts with a different-but-valid sequence (`FF 25` instead of `83 3D`), so
the game concludes it has been hooked by a cheat tool and deliberately shuts itself down. The
verdict it computes is `0x100 + 0xFF` = `0x1FF`, which is exactly the `(01ff)` in the dialog it
shows: `Timer-API hook was detected.(01ff)`.

The fix is **one byte**: `7E` → `EB` at `SK-Main.exe` RVA `0x1f4d50`.

---

## Download

**[Silver Knights 0.13 — Windows 11 build](https://github.com/mateussmeneses/Silver-Knights-Crash-Correction/releases/tag/v0.13-win11)**

A ready-to-run zip: the game already patched, `PLAY.bat` to start it, and the bilingual guides
inside. No build step needed.

```
SilverKnights-0.13-Windows11.zip
  sha256 11e40b9adfc627c63ed0a968d24b3c68f86f37a5181158f48c861ec2cc4acea8
```

Unzip somewhere writable (not `C:\Program Files`), run `PLAY.bat`, click **Window** in the small
launcher, then **Battle Mode** and press **F3** to start a match.

Verify what you downloaded against `MANIFEST.md5`, which lists every file with its MD5.

---

## Start here

| Document | What it covers |
|---|---|
| **[docs/SETUP-WINDOWS.md](docs/SETUP-WINDOWS.md)** | Install and patch, step by step (EN / PT) |
| **[docs/HOW-TO-PLAY.md](docs/HOW-TO-PLAY.md)** | Tutorial: controls, movement modes, combat (EN / PT) |
| **[docs/DISTRIBUTION.md](docs/DISTRIBUTION.md)** | Licence status, and what publishing a release would change |
| [docs/CRASH-ANALYSIS.md](docs/CRASH-ANALYSIS.md) | Full root cause, proven by disassembly |
| [docs/COMPATIBILITY-MATRIX.md](docs/COMPATIBILITY-MATRIX.md) | What is verified, what is not |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Binary architecture, no source available |
| [docs/LINUX.md](docs/LINUX.md) · [docs/MACOS.md](docs/MACOS.md) | Cross-platform investigation |
| [docs/HANDOFF.md](docs/HANDOFF.md) | Session continuity |

---

## What actually works

Verified by execution, not by assumption:

| Area | Status |
|---|---|
| Launch → menu → live match | **Verified** |
| Rendering (D3D9, 3D geometry, HUD) | **Verified** |
| High-end post-processing | **Verified** — 4 profiles, no shader compile failure |
| Audio (SFX + MP3 music) | **Verified** — signal measured at the device |
| Audio (MIDI) | **Verified** — isolated with MP3 disabled |
| Startup dialogs | **Fixed** |
| 30-minute session limit | **Characterised** — designed, per-match, not a crash |
| Network play | **Untested** — needs a human to type a name |
| Controller | **Untested** — no device |
| Linux / macOS | **Untested** — no host. Not claimed |

Three things this project deliberately does **not** claim: that Linux works, that multiplayer
works, or that this build is fit for competitive play (the patch disables an anti-cheat check).

---

## Build

```bash
python tools/build_patched.py --game-dir . --upx /path/to/upx.exe --out-dir build-patched
```

Produces a patched `SK-Main.exe` padded back to exactly **1,464,320 bytes**, and a
`SK-Startup.exe` whose embedded size/MD5 constants match it. Same-length patching matters because
the launcher verifies both; see [docs/BINARY-ANALYSIS.md](docs/BINARY-ANALYSIS.md).

---

## Repository layout

```
SK-Main.exe, SK-Startup.exe, ...  original game (gitignored, yours to supply)
docs/                             analysis, evidence, guides
  evidence/                       run records, PE dumps, screenshots
  images/                         screenshots used by the tutorial
tools/                            build, analysis and test harnesses
```

The originals in a working tree are never modified. Every patch writes to a separate directory,
and `git diff --stat -- SK-Main.exe ...` is asserted empty before each commit.

---
---

# Português

## ⚠️ Este repositório não contém o jogo

Silver Knights é © 2003–2012 **Haruo Teshima (TESHIMA)**. O próprio `ReadMe-English.txt` diz:

> "Do not change any datas in this software without permission from the author."
> "This software is still under development, so do not distribute or upload this software."

Para ser preciso sobre o estado atual, porque seria desonesto insinuar o contrário: **o commit
base do repositório já contém o jogo completo** (foi enviado antes desta análise começar, num
commit sem `.gitignore`). Este projeto não adicionou esses arquivos e não adiciona mais; tudo o
que foi commitado depois é análise, ferramental e documentação, e os binários do jogo são
byte-idênticos ao commit base.

Nenhum **asset de Release** é publicado. Um arquivo verificado pode ser gerado localmente com
`tools/build_release.py`; publicá-lo ou não é decisão do dono do repositório, e o §0 de
`docs/DISTRIBUTION.md` expõe o que essa decisão realmente muda.

O site do autor (`philotes.sv1.sp-land.net`) **não resolve mais** em novembro de 2026. O Internet
Archive tem snapshots até janeiro de 2026.

O que este projeto adiciona é uma **ferramenta de patch** que você roda sobre a sua própria cópia,
mais a documentação e as evidências de que a correção funciona. As capturas de tela são usadas sob
permissão explícita do autor para divulgar o jogo.

---

## O problema, em um parágrafo

No Windows 11 o jogo se fecha cerca de **8 segundos** após abrir: sem caixa de erro, sem relatório
de falha, status 0 e log limpo. Parece travamento e não é. O `SK-Main.exe` copia os primeiros 20
bytes de `winmm!timeGetTime` e compara com o código de máquina do Windows 95/98/2000. O `winmm`
moderno começa com uma sequência diferente, porém válida (`FF 25` em vez de `83 3D`), então o jogo
conclui que foi interceptado por uma ferramenta de trapaça e se encerra de propósito. O veredito
calculado é `0x100 + 0xFF` = `0x1FF`, que é exatamente o `(01ff)` do diálogo
`Timer-API hook was detected.(01ff)`.

A correção é **um byte**: `7E` → `EB` em `SK-Main.exe` RVA `0x1f4d50`.

---

## Baixar

**[Silver Knights 0.13 — build Windows 11](https://github.com/mateussmeneses/Silver-Knights-Crash-Correction/releases/tag/v0.13-win11)**

Um zip pronto para usar: o jogo já corrigido, `PLAY.bat` para iniciar, e os guias bilíngues
dentro. Sem etapa de build.

```
SilverKnights-0.13-Windows11.zip
  sha256 11e40b9adfc627c63ed0a968d24b3c68f86f37a5181158f48c861ec2cc4acea8
```

Descompacte em local gravável (não em `C:\Program Files`), execute `PLAY.bat`, clique em
**Window** na janelinha do launcher, depois **Battle Mode** e aperte **F3** para começar a partida.

Confira o que baixou contra o `MANIFEST.md5`, que lista cada arquivo com seu MD5.

---

## Comece por aqui

| Documento | Conteúdo |
|---|---|
| **[docs/SETUP-WINDOWS.md](docs/SETUP-WINDOWS.md)** | Instalação e patch, passo a passo (EN / PT) |
| **[docs/HOW-TO-PLAY.md](docs/HOW-TO-PLAY.md)** | Tutorial: controles, modos de movimento, combate (EN / PT) |
| [docs/CRASH-ANALYSIS.md](docs/CRASH-ANALYSIS.md) | Causa raiz completa, provada por desmontagem |
| [docs/COMPATIBILITY-MATRIX.md](docs/COMPATIBILITY-MATRIX.md) | O que está verificado e o que não está |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Arquitetura do binário, sem código-fonte |
| [docs/HANDOFF.md](docs/HANDOFF.md) | Continuidade entre sessões |

---

## O que realmente funciona

Verificado por execução, não por suposição:

| Área | Situação |
|---|---|
| Abertura → menu → partida ao vivo | **Verificado** |
| Renderização (D3D9, geometria 3D, HUD) | **Verificado** |
| Pós-processamento no nível máximo | **Verificado** — 4 perfis, sem falha de shader |
| Áudio (SFX + música MP3) | **Verificado** — sinal medido no dispositivo |
| Áudio (MIDI) | **Verificado** — isolado com MP3 desativado |
| Diálogos de inicialização | **Corrigidos** |
| Limite de sessão de 30 minutos | **Caracterizado** — planejado, por partida, não é travamento |
| Modo rede | **Não testado** — precisa de uma pessoa digitando um nome |
| Controle/joystick | **Não testado** — sem dispositivo |
| Linux / macOS | **Não testado** — sem máquina. Não afirmado |

Três coisas que este projeto deliberadamente **não** afirma: que o Linux funciona, que o
multiplayer funciona, ou que este build serve para jogo competitivo (o patch desativa uma
checagem anti-cheat).

---

## Build

```bash
python tools/build_patched.py --game-dir . --upx /caminho/para/upx.exe --out-dir build-patched
```

Gera um `SK-Main.exe` corrigido e preenchido de volta para exatamente **1.464.320 bytes**, e um
`SK-Startup.exe` cujas constantes de tamanho/MD5 conferem com ele. O patch de mesmo tamanho é
necessário porque o launcher verifica os dois; veja [docs/BINARY-ANALYSIS.md](docs/BINARY-ANALYSIS.md).

---

## Créditos

Silver Knights é © 2003–2012 **Haruo Teshima (TESHIMA)**. Arte por Moongate, áudio por Kei Tokusa,
animação por EOS.

Análise, ferramentas e documentação deste repositório são trabalho independente e não reivindicam
direitos sobre o jogo.
