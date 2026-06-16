# Homebrew distribution — `veilens` CLI

The `veilens` CLI ships as a **prebuilt, Developer-ID-signed universal binary**,
attached to each GitHub Release as `veilens-macos.tar.gz` by
`.github/workflows/release.yml`.

## Installing (once the tap exists)

```sh
brew install veilensapp/tap/veilens
veilens status
```

## Releasing a new version

1. Tag the repo (`git tag v0.1.0 && git push origin v0.1.0`). CI builds the
   signed universal `veilens-macos.tar.gz` and attaches it to the Release. (The
   job log prints the tarball's sha256.)
2. Bump the formula to point at the new asset + checksum:

   ```sh
   dist/homebrew/update-formula.sh v0.1.0
   ```

3. Publish the formula to the tap repo (`veilensapp/homebrew-tap`) as
   `Formula/veilens.rb`.

## Creating the tap (one-time)

A Homebrew tap is just a repo named `homebrew-<name>`:

```sh
gh repo create veilensapp/homebrew-tap --public
git -C homebrew-tap add Formula/veilens.rb
git -C homebrew-tap commit -m "veilens 0.1.0" && git -C homebrew-tap push
```

`brew install veilensapp/tap/veilens` resolves `veilensapp/homebrew-tap` →
`Formula/veilens.rb`.

## Notes

- **Signing, not notarization.** A Developer-ID-signed CLI runs from the
  terminal without a Gatekeeper prompt, and Homebrew doesn't quarantine tap
  downloads, so notarization isn't required.
- **Shared state with millrace.** `veilens` installs into the same tree
  (`~/Library/Application Support/Millrace`) and drives the same launchd job
  (`me.millrace.server`) as the `millrace` CLI — they interoperate on one
  inference server. `veilens` adds headgate + the vault on top.
