# Application secrets

Application secrets use 1Password at runtime. The repository stores only each
secret’s alias, item title, field and allowed profiles in
`.chezmoidata.toml`.

## Commands

```sh
dotfiles-secrets list
dotfiles-secrets status [alias]
dotfiles-secrets read <alias>                 # secret only on stdout
dotfiles-secrets set <alias> [--vault <vault>] \
  [--from-keychain <service>] [--account <account>]
```

`set` prompts without echoing. Both write paths build a 1Password item as JSON
on stdin, so the value is absent from shell history, process arguments and
managed files.

Consumers should prefer a pipe:

```sh
dotfiles-secrets read <alias> | consumer
```

Use an environment variable or local file only when the consumer has no
stdin-based option. A file projection becomes a plaintext copy that must be
permissioned and rotated separately.

## Flow Icons

Flow Icons is installed on both personal and work Macs. It uses premium icons
when the current profile’s configured vault contains the optional licence,
otherwise it installs the public set.

Store a new value in the current machine’s vault with:

```sh
dotfiles-secrets set flow-icons
dotfiles-flow-icons
```

Migrate the old login-Keychain item without exposing the value:

```sh
dotfiles-secrets set flow-icons \
  --from-keychain flow-icons-zed-premium
dotfiles-flow-icons
```

The migration deliberately leaves the Keychain copy in place for rollback.
After verifying the Zed extension, remove that old item explicitly if wanted.

Provision a separate work-readable vault from a trusted personal Mac:

```sh
dotfiles-secrets set flow-icons --vault '<work-vault-id>'
# Or migrate the existing Keychain copy directly:
dotfiles-secrets set flow-icons --vault '<work-vault-id>' \
  --from-keychain flow-icons-zed-premium
```

Grant the work service account only view/read-item permission in 1Password.
The helper also refuses `set` on service-account machines, so provisioning and
rotation stay on a trusted desktop-authenticated Mac.

Verify each work Mac can read its copy, then approve the upstream disclosure:

```sh
dotfiles-secrets status flow-icons && dotfiles-flow-icons
```

The Zed updater:

- executes a checksum-pinned, reviewed upstream revision;
- passes the licence through stdin, not OS arguments or environment;
- asks once before sending the licence and hostname-derived identifier to the
  upstream premium API;
- builds in a staging directory and swaps only after success;
- falls back to public icons when the optional licence is missing.

Run `dotfiles-flow-icons --public` to avoid reading the licence.

Cursor is different: its extension only accepts
`flow-icons.licenseKey` in `settings.json`. On either profile, the managed
settings preserve an existing local value and exclude it from Settings Sync,
but do not project the 1Password value to disk.

## Vaults and sharing

An item belongs to one 1Password vault. Give machines within the same trust
boundary access to one vault rather than making copies. A work service account
should only be able to read its work vault.

Personal and work vaults are separate trust boundaries, so `set --vault`
creates an independent Flow Icons copy. Future rotations must update each
copy. Prefer a vault ID when similarly named vaults exist in multiple accounts.
Vault permissions remain the real security boundary.

## Adding another secret

1. Add non-secret coordinates and allowed profiles under `[runtimeSecrets]` in
   `.chezmoidata.toml`.
2. Run `mise run check`.
3. Store the value with `dotfiles-secrets set <alias>`.
4. Pipe `dotfiles-secrets read <alias>` directly to its consumer.

Do not call `onepasswordRead` from a Chezmoi template: status, diff and apply
render templates and would unnecessarily materialise the secret.
