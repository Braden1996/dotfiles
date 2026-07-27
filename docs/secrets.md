# Application secrets

Application secrets use 1Password at runtime. The repository stores only each
secret’s alias, item title, field and allowed profiles in
`.chezmoidata.toml`.

## Commands

```sh
braden-dots secret list
braden-dots secret status [alias]
braden-dots secret read <alias>                 # secret only on stdout
braden-dots secret set <alias> [--vault <vault>] \
  [--from-keychain <service>] [--account <account>]
```

`set` prompts without echoing. Both write paths build a 1Password item as JSON
on stdin, so the value is absent from shell history, process arguments and
managed files.

Consumers should prefer a pipe:

```sh
braden-dots secret read <alias> | consumer
```

Use an environment variable or local file only when the consumer has no
stdin-based option. A file projection becomes a plaintext copy that must be
permissioned and rotated separately.

## Flow Icons

Flow Icons is installed on both personal and work Macs. It uses premium icons
when the current profile’s configured vault contains the optional licence,
otherwise it installs the public set.

Each machine vault should contain:

- item: `Flow Icons License`
- concealed field: `license key`

Apply that vault’s value to every installed editor with:

```sh
braden-dots secret status flow-icons
braden-dots app flow-icons
```

The operation updates only the Flow Icons setting:

- VS Code and Cursor receive `flow-icons.licenseKey` in their local
  `settings.json`. Existing JSONC comments and unrelated settings are
  preserved, the setting is added to `settingsSync.ignoredSettings`, and the
  file is written atomically with mode `0600`.
- Zed’s pinned extension builder receives the licence through stdin. The key is
  not stored in the generated extension.

VS Code and Cursor require the key in editor settings, so those two projections
are necessarily plaintext local copies. They remain outside the Chezmoi source,
outside Settings Sync, and below the user-private `~/Library` tree. Zed does not
persist the key.

After rotating the item in 1Password, rerun:

```sh
braden-dots app flow-icons
```

`braden-dots secret set flow-icons` remains available for secure prompted entry.
It creates or updates those same item coordinates without placing the value in
shell history or process arguments. Work service accounts remain read-only, so
create or rotate a work-vault item from a trusted desktop-authenticated Mac.

Verify each work Mac can read its copy, then approve the upstream disclosure:

```sh
braden-dots secret status flow-icons && braden-dots app flow-icons
```

The Zed updater:

- executes a checksum-pinned, reviewed upstream revision;
- passes the licence through stdin, not OS arguments or environment;
- asks once before sending the licence and hostname-derived identifier to the
  upstream premium API;
- builds in a staging directory and swaps only after success;
- falls back to public icons when the optional licence is missing.

Run `braden-dots app flow-icons --public` to avoid reading the licence.
The public path leaves any existing VS Code or Cursor licence setting untouched.

## Vaults and sharing

An item belongs to one 1Password vault. Give machines within the same trust
boundary access to one vault rather than making copies. A work service account
should only be able to read its work vault.

Personal and work vaults are separate trust boundaries. Keep a `Flow Icons
License` item in each intended machine vault, then update each copy during a
rotation. Prefer a vault ID when similarly named vaults exist in multiple
accounts. Vault permissions remain the real security boundary.

## Adding another secret

1. Add non-secret coordinates and allowed profiles under `[runtimeSecrets]` in
   `.chezmoidata.toml`.
2. Run `mise run check`.
3. Store the value with `braden-dots secret set <alias>`.
4. Pipe `braden-dots secret read <alias>` directly to its consumer.

Do not call `onepasswordRead` from a Chezmoi template: status, diff and apply
render templates and would unnecessarily materialise the secret.
