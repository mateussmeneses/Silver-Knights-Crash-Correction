# Silver Knights 0.13 — Windows Setup Guide

**English** · [Português abaixo](#português)

---

## ⚠️ Read this first

This repository does **not** contain the game. Silver Knights is © 2003–2012 Haruo Teshima
(TESHIMA), and its `ReadMe-English.txt` says:

> "Do not change any datas in this software without permission from the author."
> "This software is still under development, so do not distribute or upload this software."

So there is **no download here**, and no zip is published. The only lawful way to get the game
is from the author's own site:

- http://philotes.sv1.sp-land.net/

**What this repository gives you** is a way to make *your own copy* run on Windows 11, plus the
evidence that the fix works. You build the patched files yourself, from files you obtained
lawfully. Screenshots are explicitly permitted by the author for introducing the game, which is
why the tutorial below can show them.

If you hold the rights to this game and want a redistribution published, that decision is yours
to make — nothing here does it on your behalf.

---

## What the problem actually is

Silver Knights was written for Windows 2000/XP and last built in **July 2012**. On Windows 11 it
closes itself about **8 seconds** after launch, with no error dialog, no crash report and a clean
log file. That looks like a crash. It is not.

`SK-Main.exe` copies the first 20 bytes of `winmm!timeGetTime` and compares them against the
machine code that Windows 95/98/2000 used. On Windows 11 that function begins with a different
but equally valid instruction sequence, so the game concludes a cheat tool has hooked it and
**deliberately shuts itself down**.

Three bytes of detail, for the curious — this is proven, not guessed:

| | |
|---|---|
| Expected first byte | `0x83` (`cmp [abs32], 0`) |
| Actual on Windows 11 | `0xFF` (`jmp [IAT]`) |
| Verdict the game computes | `0x100 + 0xFF` = **`0x1FF`** |
| Which is exactly the dialog text | `Timer-API hook was detected.(01ff)` |

The fix is one byte: `7E` → `EB` at `SK-Main.exe` RVA `0x1f4d50`, which turns "if the check
failed, complain and quit" into "skip the complaint". The check's other diagnostics are left
intact on purpose.

There are two smaller problems, also fixed:

- **Two pointless dialogs** on every launch, about a registry value Windows 11 no longer has.
- **Asset filename case** that only matters on Linux/macOS, not on Windows.

---

## Requirements

- Windows 10 or 11, 64-bit
- A Direct3D 9 capable GPU (anything from the last 15 years)
- The **original Silver Knights 0.13 files**, obtained from the author
- Python 3 (only for the build step)
- [UPX](https://upx.github.io/) 4.x (only for the build step)

---

## Step 1 — Verify your originals

You need these files from your own copy:

```
SK-Main.exe          1,464,320 bytes
SK-Startup.exe         102,400 bytes
SKGuard.dll
libeay32.dll
msvcr71.dll
SilverKnights.ini
1041.ini
mesh/  bsp/  png/  se/  logo/  mp3/  midi/
```

Confirm the main executable is the expected build:

```bash
sha256sum SK-Main.exe
# cd54b002cf465a5fa63c57b9e1d7f5e348dc86ba55304d90ddc88ef03a009bab
md5sum SK-Main.exe
# 84a321d3035de0e2f03539123667f3d6
```

If those do not match, you have a different version and **these offsets will not apply**. Stop
and check what you have.

> Note: both executables are UPX-packed. That is why the shipped binary's import table looks
> nearly empty — the real imports appear only after unpacking. This is normal, not corruption.

---

## Step 2 — Build the patched files

The build writes to a separate output directory. **It never modifies your originals.**

```bash
python tools/build_patched.py --game-dir . --upx /path/to/upx.exe --out-dir build-patched
```

What it does:

1. Unpacks `SK-Main.exe` to recover the real code
2. Applies the 1-byte change at RVA `0x1f4d50`
3. Re-packs and **pads back to exactly 1,464,320 bytes** — the same length as the original
4. Recomputes the MD5 that `SK-Startup.exe` checks, and patches that constant too

Step 3 and 4 matter because `SK-Startup.exe` verifies **both the size and the MD5** of
`SK-Main.exe`. A build that changes either is rejected with
`'SK-Main.exe' file is corrupted.` The same-length approach means only one constant needs editing,
and the launcher's verification logic stays intact rather than being disabled.

Expected result:

```
build-patched/SK-Main.exe     1,464,320 bytes
build-patched/SK-Startup.exe    102,400 bytes
```

---

## Step 3 — Install

1. Copy your whole game folder somewhere writable, e.g. `C:\Games\SilverKnights`
2. Replace `SK-Main.exe` and `SK-Startup.exe` with the two files from `build-patched/`
3. Leave everything else exactly as it was

**Do not** put the game in `C:\Program Files`. It writes `SilverKnights.log` and `temp/` next to
itself, and Windows will silently redirect those writes, which makes problems much harder to
diagnose.

---

## Step 4 — Run it

Double-click **`SK-Startup.exe`**.

Not `SK-Main.exe` — that one is the renderer and expects the launcher as its IPC peer. Run alone
it exits immediately with status 0 and writes nothing to the log, which is confusing.

The launcher shows a small window with a **Window** button. Click it. The game then opens.

### If it still closes after ~8 seconds

The patch did not take. Check:

```bash
md5sum SK-Main.exe
```

If this is still `84a321d3035de0e2f03539123667f3d6`, you are running the original. Re-copy from
`build-patched/`.

### If you see "'SK-Main.exe' file is corrupted."

`SK-Startup.exe` rejected the build because size or MD5 did not match. Both must come from the
same build run — do not mix a patched `SK-Main.exe` with an unpatched `SK-Startup.exe`.

### If the game closes after exactly 30 minutes

That is **not** a bug. It is a designed session limit on battles, and it is clean — the game
writes an ordinary `End` line and exits with status 0. Sitting in the menus is **not** limited;
a 31-minute menu idle was tested and survived. Only a match is capped. Start a new match.

---

## Controls

Configured in `SilverKnights.ini` under `[KEYBOARD]`, using DirectInput scancodes.

| Key | Action |
|---|---|
| Arrow keys | Move / turn |
| `B` | Main shooting / sword attack |
| `V` | Sub shooting / heavy sword attack |
| `C` | Flight / boost (press twice for sudden rise) |
| `X` | Guard |
| `Z` | Option / modification |
| `N` | Lock-on target (press twice to cancel) |
| `F` | Help message |
| `D` | Spare message |
| `F3` | **Start the match** (not Enter) |
| `ESC` | Back |

**Enter is not "start".** On the Battle setup screen, Enter only moves the slot cursor. The
match begins with **F3**. This trips up nearly everyone at first.

---

## Known limitations

Documented honestly rather than hidden:

| Area | Status |
|---|---|
| Gameplay, rendering, audio | **Working** — verified with a live match |
| Music (MP3) | **Working** — signal measured at the audio device |
| Music (MIDI) | **Working** — verified in isolation with MP3 disabled |
| Anti-cheat | **Disabled** by the patch. Fine for single-player/archival use; this build is not suitable for any competitive claim |
| Network mode | **Untested** — the name-entry field cannot be automated, needs a human |
| Controller | **Untested** — no device available |
| Linux / macOS | **Untested** — no host available. Do not assume it works |
| Handle leak | Present, ~20/min. Harmless in practice (would take ~580 days to matter) |

---

## Credits

Silver Knights is © 2003–2012 **Haruo Teshima (TESHIMA)**. Art by Moongate, audio by Kei Tokusa,
animation by EOS.

This guide and the patch tooling are independent work and claim no rights over the game. The
author permits using screenshots to introduce the game; that permission is what the tutorial
relies on.

---
---

# Português

## ⚠️ Leia isto primeiro

Este repositório **não contém o jogo**. Silver Knights é © 2003–2012 Haruo Teshima (TESHIMA), e o
`ReadMe-English.txt` dele diz:

> "Do not change any datas in this software without permission from the author."
> "This software is still under development, so do not distribute or upload this software."

Ou seja: **não há download aqui**, e nenhum zip é publicado. A única forma legítima de obter o
jogo é pelo site do autor:

- http://philotes.sv1.sp-land.net/

**O que este repositório oferece** é como fazer a *sua própria cópia* rodar no Windows 11, mais as
evidências de que a correção funciona. Você mesmo gera os arquivos corrigidos, a partir de
arquivos que obteve legalmente. O autor permite explicitamente o uso de capturas de tela para
divulgar o jogo — é nisso que o tutorial abaixo se apoia.

Se você detém os direitos deste jogo e quer publicar uma redistribuição, essa decisão é sua —
nada aqui faz isso em seu nome.

---

## Qual é o problema, de verdade

Silver Knights foi feito para Windows 2000/XP e a última compilação é de **julho de 2012**. No
Windows 11 ele se fecha cerca de **8 segundos** após abrir, sem caixa de erro, sem relatório de
falha e com o log limpo. Parece um travamento. Não é.

O `SK-Main.exe` copia os primeiros 20 bytes da função `winmm!timeGetTime` e compara com o código
de máquina que o Windows 95/98/2000 usava. No Windows 11 essa função começa com uma sequência
diferente, porém igualmente válida, então o jogo conclui que uma ferramenta de trapaça o
interceptou e **se encerra de propósito**.

Três bytes de detalhe, para quem gosta — isto é comprovado, não suposto:

| | |
|---|---|
| Primeiro byte esperado | `0x83` (`cmp [abs32], 0`) |
| Real no Windows 11 | `0xFF` (`jmp [IAT]`) |
| Veredito calculado pelo jogo | `0x100 + 0xFF` = **`0x1FF`** |
| Que é exatamente o texto do diálogo | `Timer-API hook was detected.(01ff)` |

A correção é um byte: `7E` → `EB` em `SK-Main.exe` RVA `0x1f4d50`, transformando "se a checagem
falhou, avise e saia" em "pule o aviso". Os outros diagnósticos da checagem são preservados de
propósito.

Existem dois problemas menores, também corrigidos:

- **Dois diálogos inúteis** a cada execução, sobre um valor de registro que o Windows 11 não tem mais.
- **Diferença de maiúsculas/minúsculas** em nomes de arquivos, que só afeta Linux/macOS.

---

## Requisitos

- Windows 10 ou 11, 64 bits
- GPU com suporte a Direct3D 9 (qualquer uma dos últimos 15 anos)
- Os **arquivos originais do Silver Knights 0.13**, obtidos com o autor
- Python 3 (só para a etapa de build)
- [UPX](https://upx.github.io/) 4.x (só para a etapa de build)

---

## Passo 1 — Confira seus originais

Você precisa destes arquivos da sua própria cópia:

```
SK-Main.exe          1.464.320 bytes
SK-Startup.exe         102.400 bytes
SKGuard.dll
libeay32.dll
msvcr71.dll
SilverKnights.ini
1041.ini
mesh/  bsp/  png/  se/  logo/  mp3/  midi/
```

Confirme que o executável principal é a compilação esperada:

```bash
sha256sum SK-Main.exe
# cd54b002cf465a5fa63c57b9e1d7f5e348dc86ba55304d90ddc88ef03a009bab
md5sum SK-Main.exe
# 84a321d3035de0e2f03539123667f3d6
```

Se não baterem, você tem outra versão e **estes offsets não se aplicam**. Pare e verifique o que
tem em mãos.

> Nota: os dois executáveis são compactados com UPX. É por isso que a tabela de imports do
> arquivo distribuído parece quase vazia — os imports reais só aparecem após descompactar. Isso é
> normal, não é corrupção.

---

## Passo 2 — Gere os arquivos corrigidos

O build escreve em uma pasta separada. **Ele nunca altera seus originais.**

```bash
python tools/build_patched.py --game-dir . --upx /caminho/para/upx.exe --out-dir build-patched
```

O que ele faz:

1. Descompacta o `SK-Main.exe` para recuperar o código real
2. Aplica a mudança de 1 byte no RVA `0x1f4d50`
3. Recompacta e **preenche de volta para exatamente 1.464.320 bytes** — o mesmo tamanho do original
4. Recalcula o MD5 que o `SK-Startup.exe` verifica, e corrige essa constante também

Os passos 3 e 4 importam porque o `SK-Startup.exe` verifica **tamanho e MD5** do `SK-Main.exe`.
Um build que mude qualquer um dos dois é rejeitado com `'SK-Main.exe' file is corrupted.` A
abordagem de mesmo tamanho faz com que só uma constante precise ser editada, e a lógica de
verificação do launcher continua intacta em vez de ser desativada.

Resultado esperado:

```
build-patched/SK-Main.exe     1.464.320 bytes
build-patched/SK-Startup.exe    102.400 bytes
```

---

## Passo 3 — Instale

1. Copie a pasta inteira do jogo para um local gravável, ex. `C:\Games\SilverKnights`
2. Substitua `SK-Main.exe` e `SK-Startup.exe` pelos dois arquivos de `build-patched/`
3. Deixe todo o resto exatamente como estava

**Não** coloque o jogo em `C:\Program Files`. Ele grava `SilverKnights.log` e `temp/` ao lado de
si mesmo, e o Windows vai redirecionar essas gravações silenciosamente, o que torna qualquer
problema muito mais difícil de diagnosticar.

---

## Passo 4 — Execute

Dê um duplo clique em **`SK-Startup.exe`**.

Não em `SK-Main.exe` — esse é o renderizador e espera o launcher como parceiro de IPC. Executado
sozinho ele sai imediatamente com status 0 e não escreve nada no log, o que confunde bastante.

O launcher mostra uma janela pequena com um botão **Window**. Clique nele. O jogo abre.

### Se ainda fechar após ~8 segundos

A correção não foi aplicada. Verifique:

```bash
md5sum SK-Main.exe
```

Se ainda for `84a321d3035de0e2f03539123667f3d6`, você está rodando o original. Copie de novo de
`build-patched/`.

### Se aparecer "'SK-Main.exe' file is corrupted."

O `SK-Startup.exe` rejeitou o build porque tamanho ou MD5 não conferem. Os dois arquivos devem
vir da mesma execução do build — não misture um `SK-Main.exe` corrigido com um `SK-Startup.exe`
não corrigido.

### Se o jogo fechar após exatamente 30 minutos

Isso **não** é bug. É um limite de sessão por batalha, planejado, e é limpo — o jogo escreve uma
linha `End` normal e sai com status 0. Ficar nos menus **não** tem limite; testamos 31 minutos
parado no menu e ele sobreviveu. Só a partida tem teto. Comece outra partida.

---

## Controles

Configurados em `SilverKnights.ini`, seção `[KEYBOARD]`, usando scancodes do DirectInput.

| Tecla | Ação |
|---|---|
| Setas | Mover / virar |
| `B` | Tiro principal / golpe de espada |
| `V` | Tiro secundário / golpe pesado |
| `C` | Voo / impulso (aperte duas vezes para subida súbita) |
| `X` | Defesa |
| `Z` | Opção / modificação |
| `N` | Travar alvo (aperte duas vezes para cancelar) |
| `F` | Mensagem de ajuda |
| `D` | Mensagem extra |
| `F3` | **Iniciar a partida** (não é Enter) |
| `ESC` | Voltar |

**Enter não é "iniciar".** Na tela de configuração de batalha, Enter só move o cursor de slot. A
partida começa com **F3**. Isso confunde quase todo mundo na primeira vez.

---

## Limitações conhecidas

Documentadas com honestidade, não escondidas:

| Área | Situação |
|---|---|
| Jogabilidade, renderização, áudio | **Funcionando** — verificado com partida ao vivo |
| Música (MP3) | **Funcionando** — sinal medido no dispositivo de áudio |
| Música (MIDI) | **Funcionando** — verificado isoladamente com MP3 desativado |
| Anti-cheat | **Desativado** pela correção. Ok para uso single-player/arquivo; este build não serve para nenhuma alegação competitiva |
| Modo rede | **Não testado** — o campo de nome não pode ser automatizado, precisa de uma pessoa |
| Controle/joystick | **Não testado** — sem dispositivo disponível |
| Linux / macOS | **Não testado** — sem máquina disponível. Não assuma que funciona |
| Vazamento de handle | Presente, ~20/min. Inofensivo na prática (levaria ~580 dias para importar) |

---

## Créditos

Silver Knights é © 2003–2012 **Haruo Teshima (TESHIMA)**. Arte por Moongate, áudio por Kei
Tokusa, animação por EOS.

Este guia e as ferramentas de patch são trabalho independente e não reivindicam direitos sobre o
jogo. O autor permite o uso de capturas de tela para divulgar o jogo; é nessa permissão que o
tutorial se apoia.
