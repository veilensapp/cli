# veilens (CLI)

> Part of [**veilens**](https://veilens.app) — a private, on-device document
> vault for Apple Silicon, built on the
> [headgate](https://github.com/veilensapp/headgate) privacy harness and the
> [millrace](https://millrace.app) inference engine.

The `veilens` command-line tool: one binary that installs and runs the whole
vault stack on your Mac. It bootstraps the
[millrace inference server](https://github.com/millrace/inference-server) (chat +
embeddings), the headgate harness, and the veilens vault — then indexes your
documents and answers questions about them locally, with the data never leaving
the machine.

`veilens` shares its install tree (`~/Library/Application Support/Millrace`) and
launchd-managed server (`me.millrace.server`) with the
[`millrace` CLI](https://github.com/millrace/app), so the two interoperate on one
inference server; `veilens` adds headgate + the vault on top.

## Install

```sh
brew install veilensapp/tap/veilens
```

## Use

```sh
veilens install                  # millrace server + headgate + veilens site (one time, several GB)
veilens index ~/vault            # embed a folder of PDFs/CSVs/Markdown on-device
veilens start                    # bring it all up; opens the vault chat at http://localhost:10000
veilens ask "When does my insurance renew?"   # one-shot answer over your vault
veilens stop                     # shut the whole stack down
veilens status                   # what's installed
```

Run `veilens --help` for the full command list.

## Layout

| folder                            | what                                                       |
|-----------------------------------|------------------------------------------------------------|
| [`Sources/veilens/`](Sources/veilens)         | the `veilens` CLI (ArgumentParser)             |
| [`Sources/VeilensCore/`](Sources/VeilensCore) | engine-lifecycle logic (install/start/stop)    |
| [`Sources/CZstd/`](Sources/CZstd)             | vendored zstd decoder (for the `.conda` toolchain) |
| [`dist/homebrew/`](dist/homebrew)             | the Homebrew formula + tap tooling             |

## From source (needs macOS 14+ and a Swift toolchain)

```sh
swift run veilens --help          # run the CLI in dev
swift build -c release --product veilens
```

The CLI is published as a signed universal binary via a Homebrew tap — see
[`dist/homebrew/`](dist/homebrew).
