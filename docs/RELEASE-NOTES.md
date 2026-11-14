# Silver Knights 0.13 — Windows 11 build

**English** · [Português abaixo](#português)

A patched build of Silver Knights 0.13 that runs on Windows 10 and 11, plus a tutorial, because
the game ships with no manual.

---

## What this fixes

Silver Knights was written for Windows 2000/XP and last built in **July 2012**. On Windows 11 it
closed itself about **8 seconds** after launch: no error dialog, no crash report, exit status 0,
clean log. It looked like a crash and was not one.

`SK-Main.exe` fingerprints the machine code of `winmm!timeGetTime`, expecting the sequence
Windows 95/98/2000 used. Modern `winmm` begins differently, so the game concluded a cheat tool
had hooked it and deliberately shut itself down:

```
expected first byte : 0x83   (cmp [abs32], 0)
actual on Windows 11 : 0xFF   (jmp [IAT])
verdict computed     : 0x100 + 0xFF = 0x1FF
dialog shown         : Timer-API hook was detected.(01ff)
```

**The fix is one byte**: `7E` → `EB` at RVA `0x1f4d50`. The check's other diagnostics are left
intact; only this one verdict path is bypassed.

Also fixed: two pointless dialogs on every launch, about a registry value Windows 11 no longer
has.

---

## What is in the archive

```
PLAY.bat                  double-click to start
HOW-TO-PLAY.md            the manual the game never shipped (EN / PT)
SETUP-WINDOWS.md          how the patch works, how to verify it (EN / PT)
LICENCE-AND-DISTRIBUTION.md   terms, and what this build may and may not be used for
MANIFEST.md5              every file with its MD5, so you can verify what you got
SK-Main.exe               PATCHED
SK-Startup.exe            PATCHED
ReadMe-English.txt        the original licence — unmodified, read it
everything else           the original game data, unmodified
```

`SK-Main.exe` is padded back to exactly **1,464,320 bytes**, its original length, so only the
MD5 constant inside `SK-Startup.exe` needed changing rather than disabling the launcher's
integrity check.

---

## Install

1. Unzip anywhere **writable**. Not `C:\Program Files` — the game writes `SilverKnights.log`
   and `temp/` beside itself, and Windows silently redirects those, which makes problems much
   harder to diagnose.
2. Run **`PLAY.bat`**, or `SK-Startup.exe` directly.
3. In the small launcher window, click **Window**.

Do not run `SK-Main.exe` by itself. It is the renderer and exits immediately with status 0 and no
log line, which is confusing but expected.

### Starting a match

Menu → **Battle Mode** → **F3**.

**Enter does not start the match.** On the setup screen Enter only moves the cursor between
slots. This is the single most common point of confusion, so it is worth stating twice.

---

## Verified

Tested by execution, not assumption:

| Area | Status |
|---|---|
| Launch → menu → live match | **Verified** |
| 3D rendering, HUD, match timer | **Verified** |
| High-end post-processing (`EFFECT_LEVEL=3`, HDR, DoF) | **Verified** — 4 profiles, no shader compile failure |
| Audio — SFX and MP3 music | **Verified** — signal measured at the output device |
| Audio — MIDI | **Verified** — isolated by removing the MP3s and switching `MIDI=1` |
| Launcher dialogs | **Fixed** |
| 30-minute session limit | **Characterised** — designed, per match, not a crash |

## Not verified — do not assume these work

| Area | Status |
|---|---|
| Network / multiplayer | **Untested.** The lobby needs a player name typed by hand, which could not be automated, so nobody has confirmed whether DirectPlay still initialises on modern Windows |
| Controller / joystick | **Untested.** No device was available. The game expects 8+ buttons |
| Story Mode | **Not verified.** Battle Mode is the verified path |
| Replay recording | **Not verified.** `F2` toggles record, but no `.rep` file appeared |
| Linux / macOS | **Untested.** No host was available. No claim is made |

---

## The 30-minute limit is not a bug

A battle ends itself at exactly **30 minutes**, cleanly, with no error — a designed session cap,
confirmed against the game's own log, which writes an ordinary `End` line at 1800 seconds and
exits with status 0.

It applies to **matches only**. Idling in the menus is not capped; a 31-minute menu idle was
tested and the process survived. If the game closes after half an hour of fighting, start another
match — no need to relaunch.

---

## One thing you must know before using this

The patch **disables an anti-tamper check**. That is what makes the game run at all on modern
Windows, but it means:

- **Fine** for single-player, archival and personal use.
- **Not fine** for anything competitive or where cheat detection matters.

Any claim that this build is "the original, just fixed" would be wrong. It is the original with
one check neutralised. See `LICENCE-AND-DISTRIBUTION.md`.

---

## Credits

Silver Knights is © 2003–2012 **Haruo Teshima (TESHIMA)**. Art by Moongate, audio by Kei Tokusa,
animation by EOS.

This build is unofficial and is not endorsed by the author. The patch, analysis and documentation
are independent work and claim no rights over the game.

---
---

# Português

Um build corrigido do Silver Knights 0.13 que roda no Windows 10 e 11, mais um tutorial, porque o
jogo não vem com manual.

---

## O que isto corrige

Silver Knights foi feito para Windows 2000/XP e a última compilação é de **julho de 2012**. No
Windows 11 ele se fechava cerca de **8 segundos** após abrir: sem caixa de erro, sem relatório de
falha, status 0, log limpo. Parecia travamento e não era.

O `SK-Main.exe` faz uma impressão digital do código de máquina de `winmm!timeGetTime`, esperando a
sequência que o Windows 95/98/2000 usava. O `winmm` moderno começa diferente, então o jogo
concluiu que uma ferramenta de trapaça o havia interceptado e se encerrou de propósito:

```
primeiro byte esperado : 0x83   (cmp [abs32], 0)
real no Windows 11     : 0xFF   (jmp [IAT])
veredito calculado     : 0x100 + 0xFF = 0x1FF
diálogo exibido        : Timer-API hook was detected.(01ff)
```

**A correção é um byte**: `7E` → `EB` no RVA `0x1f4d50`. Os outros diagnósticos da checagem ficam
intactos; só esse caminho de veredito é desviado.

Também corrigido: dois diálogos inúteis a cada execução, sobre um valor de registro que o Windows
11 não tem mais.

---

## O que vem no arquivo

```
PLAY.bat                  clique duas vezes para iniciar
HOW-TO-PLAY.md            o manual que o jogo nunca teve (EN / PT)
SETUP-WINDOWS.md          como o patch funciona, como verificar (EN / PT)
LICENCE-AND-DISTRIBUTION.md   termos, e para que este build pode e não pode ser usado
MANIFEST.md5              cada arquivo com seu MD5, para você conferir o que recebeu
SK-Main.exe               CORRIGIDO
SK-Startup.exe            CORRIGIDO
ReadMe-English.txt        a licença original — sem alteração, leia
todo o resto              os dados originais do jogo, sem alteração
```

O `SK-Main.exe` foi preenchido de volta para exatamente **1.464.320 bytes**, seu tamanho original,
então só a constante MD5 dentro do `SK-Startup.exe` precisou mudar, em vez de desativar a
verificação de integridade do launcher.

---

## Instalação

1. Descompacte em qualquer lugar **gravável**. Não em `C:\Program Files` — o jogo grava
   `SilverKnights.log` e `temp/` ao lado de si mesmo, e o Windows redireciona isso
   silenciosamente, o que torna problemas muito mais difíceis de diagnosticar.
2. Execute **`PLAY.bat`**, ou `SK-Startup.exe` diretamente.
3. Na janelinha do launcher, clique em **Window**.

Não execute `SK-Main.exe` sozinho. Ele é o renderizador e sai imediatamente com status 0 e sem
linha no log, o que confunde mas é esperado.

### Iniciando uma partida

Menu → **Battle Mode** → **F3**.

**Enter não inicia a partida.** Na tela de configuração o Enter só move o cursor entre os slots.
É o ponto de confusão mais comum, então vale repetir.

---

## Verificado

Testado por execução, não por suposição:

| Área | Situação |
|---|---|
| Abertura → menu → partida ao vivo | **Verificado** |
| Renderização 3D, HUD, relógio da partida | **Verificado** |
| Pós-processamento no máximo (`EFFECT_LEVEL=3`, HDR, DoF) | **Verificado** — 4 perfis, sem falha de shader |
| Áudio — SFX e música MP3 | **Verificado** — sinal medido no dispositivo de saída |
| Áudio — MIDI | **Verificado** — isolado removendo os MP3 e usando `MIDI=1` |
| Diálogos do launcher | **Corrigidos** |
| Limite de sessão de 30 minutos | **Caracterizado** — planejado, por partida, não é travamento |

## Não verificado — não assuma que funciona

| Área | Situação |
|---|---|
| Rede / multiplayer | **Não testado.** O lobby exige um nome digitado à mão, o que não pôde ser automatizado, então ninguém confirmou se o DirectPlay ainda inicializa no Windows moderno |
| Controle / joystick | **Não testado.** Não havia dispositivo. O jogo espera 8+ botões |
| Story Mode | **Não verificado.** Battle Mode é o caminho verificado |
| Gravação de replay | **Não verificado.** `F2` alterna a gravação, mas nenhum `.rep` apareceu |
| Linux / macOS | **Não testado.** Não havia máquina. Nenhuma afirmação é feita |

---

## O limite de 30 minutos não é bug

Uma batalha se encerra sozinha em exatamente **30 minutos**, de forma limpa, sem erro — um teto de
sessão planejado, confirmado contra o log do próprio jogo, que escreve uma linha `End` normal aos
1800 segundos e sai com status 0.

Vale **só para partidas**. Ficar nos menus não tem limite; testamos 31 minutos parado no menu e o
processo sobreviveu. Se o jogo fechar depois de meia hora de luta, comece outra partida — não
precisa reabrir o jogo.

---

## Uma coisa que você precisa saber antes de usar

O patch **desativa uma checagem anti-tamper**. É isso que faz o jogo rodar no Windows moderno, mas
significa:

- **Ok** para single-player, preservação e uso pessoal.
- **Não ok** para qualquer coisa competitiva ou onde detecção de trapaça importe.

Dizer que este build é "o original, só que corrigido" seria falso. É o original com uma checagem
neutralizada. Veja `LICENCE-AND-DISTRIBUTION.md`.

---

## Créditos

Silver Knights é © 2003–2012 **Haruo Teshima (TESHIMA)**. Arte por Moongate, áudio por Kei Tokusa,
animação por EOS.

Este build é não-oficial e não é endossado pelo autor. O patch, a análise e a documentação são
trabalho independente e não reivindicam direitos sobre o jogo.
