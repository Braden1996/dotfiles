# GitHub credentials

GitHub authentication and commit signing use per-machine SSH keys generated in
1Password. Private keys are streamed into the OS SSH agent and are never
written to a key file.

## What lives where

- 1Password: private keys, Git identities and optional GitHub API tokens.
- Local disk: public keys, `allowed_signers`, SSH host aliases and generated
  Git identity routing.
- Personal Mac: `op` authenticates through the 1Password desktop app.
- Work Mac: `op` uses a vault-scoped service account token kept in the login
  Keychain. Loaded keys expire from the agent after nine hours.

The configured `opVault` is a trust boundary. Personal and work machines should
use different vaults.

## Personal machine

```sh
braden-dots init
braden-dots identity status --repo .
braden-dots identity test
```

`setup` creates the machine’s authentication and signing keys in 1Password,
publishes their public halves to the active `gh` account, writes local routing
and loads the private keys into the agent.

## Work machine

Provision its keys from a trusted personal Mac that has write access to the
work vault:

```sh
gh auth switch -h github.com -u <github-login>
braden-dots identity provision <work-machine> \
  --vault '<work-vault-id>' \
  --github-user <github-login>
```

On the work Mac, use the same machine name during the initial Chezmoi
bootstrap, then:

```sh
braden-dots identity store-token
braden-dots init
braden-dots identity status
```

`setup` intentionally limits the work service account to syncing and loading
the pair provisioned above. Its actual vault permissions are enforced by
1Password rather than inferred by `braden-dots`.

## Extra Git identity or GitHub account

An identity is an email plus `owner/**` or `owner/repo` scope:

```sh
braden-dots identity add personal <email> 'Braden1996/**' \
  --vault '<work-vault-id>'
```

If that identity uses another GitHub account, switch `gh` to it and provision a
separate pair for the target machine:

```sh
gh auth switch -h github.com -u Braden1996
braden-dots identity provision <work-machine> \
  --identity personal \
  --vault '<work-vault-id>' \
  --github-user Braden1996
```

Then run `braden-dots identity sync && braden-dots identity ensure` on the
target. Clone through the generated alias, for example:

```sh
git clone git@github-personal:Braden1996/repo.git
```

`--github-user` prevents publishing a key to whichever `gh` account happened to
be active.

## Optional GitHub API token

Provision a short-lived fine-grained PAT on the target machine, or from another
machine that can authenticate as the intended GitHub account:

```sh
braden-dots identity provision-token <machine> \
  --vault '<target vault>' \
  --github-user <login> \
  --target <owner/repo> \
  --profile pr-maintainer
```

The command asks for confirmation, opens GitHub's prefilled token form, captures
the resulting token without echoing it or placing it in argv, verifies its
GitHub account, and sends it to 1Password over stdin. GitHub still requires the
repository selection and any organization approval in its UI. Use
`--identity <slug>` when provisioning a separate account.

On a work profile, this explicit command may write through the configured
service account. 1Password remains the authority: the service account must
have `Create Items` permission in the target vault. Other work-profile identity
mutations remain disabled.

The default account is stored as:

```text
Title:      GitHub Machine PAT (<machine>)
Username:   <GitHub login>
Credential: <PAT>
```

Separate accounts use `GitHub Machine PAT (<machine> <slug>)`. Rerunning
`provision-token` never reads, replaces, or duplicates an existing item.
Delete or rename the old item deliberately before rotating it.

On the target machine, verify the token without making a GitHub change:

```sh
braden-dots identity token-check --repo .
```

This checks the token account plus repository, Actions-run, and pull-request
read access. Organization approval may leave a newly created token unable to
read the repository even though the token has already been stored.

Run `gh` through the checked, repository-aware wrapper:

```sh
braden-dots identity gh --repo . -- pr create --fill
```

Git's generated `includeIf` rules remain the source of truth: an author-only
scope keeps the default account, while a scope with its own key pair selects
the matching machine-and-identity token. The wrapper rejects a mismatched SSH
route and verifies the token’s account before running the requested command.
Use `--identity <slug>` only when no repository route is available. The legacy
positional form, `gh <slug> -- ...`, remains accepted.

Fine-grained PATs currently do not support every GitHub API, including the
Checks API. `token-check` covers the read paths used for Actions and pull
requests, but the requested `gh` operation remains the final permission test.

## Retirement and limits

- Retire one machine by deleting all matching GitHub keys and 1Password items.
- Retire work access by also disabling its service account.
- Revocation stops future vault reads. It cannot recall a private key or token
  already copied into process or agent memory.
- A service account can exercise every permission granted in every vault it can
  access. Prefer one work vault and service account per machine, grant only the
  required item permissions, and put only credentials made for that machine or
  explicitly approved work-accessible application secrets inside it.
- The login Keychain improves at-rest protection; it does not isolate a token
  from every process running as the logged-in user while unlocked.

Use `braden-dots identity status --repo . --json` to inspect the effective
author, signing-key path, and SSH route without exposing key material. The
machine’s configured `defaultGitHubUser` owns the plain `github.com` route;
additional accounts use the alias reported by that status command.

Use `braden-dots status` and `braden-dots doctor` for the wider machine state.
