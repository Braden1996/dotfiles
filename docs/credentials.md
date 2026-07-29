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

The work service account is read-only. `setup` therefore syncs and loads the
pair provisioned above rather than creating one.

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

For `gh` on a non-interactive account, create a short-lived fine-grained PAT.
The default account uses the machine title:

```text
Title:      GitHub Machine PAT (<machine>)
Username:   <GitHub login>
Credential: <PAT>
```

A separate account selected by an identity scope uses:

```text
Title:      GitHub Machine PAT (<machine> <slug>)
Username:   <GitHub login>
Credential: <PAT>
```

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

## Retirement and limits

- Retire one machine by deleting all matching GitHub keys and 1Password items.
- Retire work access by also disabling its service account.
- Revocation stops future vault reads. It cannot recall a private key or token
  already copied into process or agent memory.
- A service account can read every secret in every vault it can access. Prefer
  one work vault and service account per machine, and put only credentials made
  for that machine or explicitly approved work-readable application secrets
  inside it.
- The login Keychain improves at-rest protection; it does not isolate a token
  from every process running as the logged-in user while unlocked.

Use `braden-dots identity status --repo . --json` to inspect the effective
author, signing-key path, and SSH route without exposing key material. The
machine’s configured `defaultGitHubUser` owns the plain `github.com` route;
additional accounts use the alias reported by that status command.

Use `braden-dots status` and `braden-dots doctor` for the wider machine state.
