# MCP Registry publishing

This directory holds the metadata for the project's entry in the [official MCP Registry](https://modelcontextprotocol.io/registry/), published as:

```
io.github.cytoscape/cytoscape-desktop-mcp-bridge
```

`server.json` is a **template**. The `identifier`, `version` and `fileSha256` are set at release time.

## What the user must have installed

Either packaging — the `.mcpb` or the npm package — is just the bridge. The user still has to supply Cytoscape Desktop; see [Bridge Requirements](../claude-extension/server/README.md#prerequisites--read-this-first).

## What gets published, and what does not

The registry hosts metadata only. The entry lists two packagings of the **bridge**, side by side:

| Entry | What a client does with it |
|---|---|
| `registryType: mcpb` | Downloads `cytoscape-mcp.mcpb` from a GitHub release |
| `registryType: npm` | Runs `npx @cytoscape/cytoscape-desktop-mcp-bridge` |

These are parallel, not layered — a client picks whichever it supports; neither wraps the other. They exist to enable registry-driven and marketplace installers to provide a local MCP connector. 

## Versioning

`claude-extension/manifest.json`'s `version` is the single source of truth for the bridge, hand-bumped only when the bridge materially changes. Three things derive from it at publish time:

- the registry entry's top-level `version`
- the npm package entry's `version`
- the published npm package's `version` 

The `mcpb-vX.Y.Z` gh release tag encoding restates that same number, and `make check-bridge-version` fails the release if they disagree. 

Consequence: app releases will not trigger the release workflow to publish the mcpb registry bundles. Only release tags prefixed with `mcpb-v` will initiate publishing a registry bundle.

## Cutting a bridge release

1. Bump `version` in `claude-extension/manifest.json` to `X.Y.Z`.
2. Publish a GitHub Release with the tag `mcpb-vX.Y.Z`.

The tag starts the `release-mcpb` job, which checks the tag matches the manifest, builds the `.mcpb`, attaches it to the release, and then publishes twice — once to npm, once to the MCP Registry.

Confirm both landed:

```bash
npm view @cytoscape/cytoscape-desktop-mcp-bridge version
curl "https://registry.modelcontextprotocol.io/v0.1/servers?search=io.github.cytoscape/cytoscape-desktop-mcp-bridge"
```

### Re-running is safe

The two publishes are independent, and each one checks whether that version is already out there before doing anything:

- npm already has `X.Y.Z` → prints `already on npm, skipping` and carries on
- the registry already has `X.Y.Z` → prints `already in registry, skipping publish`

So if one half fails you can re-run the job: it completes the missing half and leaves the finished half alone. It is also why publishing an npm version by hand does not block a release — npm gets skipped and the registry still publishes.

## First-time npm setup (already done, for reference)

npm can only hand publishing rights to a GitHub workflow for a package that already exists. So the first version of the bridge had to be pushed up by hand, and only then could CI take over. This was done once, for `1.0.3`. You would only need it again if the package were renamed.

### 1. Publish the first version by hand

From `main`, as a member of the `cytoscape` npm org:

```bash
npm login
make stage-npm-bridge TAG=mcpb-vX.Y.Z
npm publish ./build/npm-staging --access public --dry-run   # check the file list
npm publish ./build/npm-staging --access public
npm view @cytoscape/cytoscape-desktop-mcp-bridge version mcpName
```

`mcpName` must come back as `io.github.cytoscape/cytoscape-desktop-mcp-bridge`. That field is how the MCP Registry confirms this npm package belongs to the project; without it the registry publish is rejected.

### 2. Let the workflow publish from then on

On npmjs.com, open the package → **Settings** → **Trusted Publisher** → **GitHub Actions**, and enter:

| Field | Value |
|---|---|
| Organization or user | `cytoscape` |
| Repository | `cytoscape-desktop-mcp` |
| Workflow filename | `release.yml` |
| Environment name | *leave blank* |
| Allowed actions | `npm publish` |

Values are case-sensitive, and a package can have only one trusted publisher at a time. From here on npm trusts that one workflow in that one repository, so `release.yml` publishes without any stored password.

## Local mcpb and registry builds (publishes nothing)

`X.Y.Z` is the `version` field in `claude-extension/manifest.json`.

```bash
make build_claude_mcpb
make stamp-server-json TAG=mcpb-vX.Y.Z   # -> build/server.json
make stage-npm-bridge  TAG=mcpb-vX.Y.Z   # -> build/npm-staging/
.tools/mcp-publisher validate build/server.json
npm publish ./build/npm-staging --access public --dry-run
```

Note `mcp-publisher validate` checks shape against the live registry but **not** namespace ownership — a wrong namespace passes validation and fails only at publish time.

## Authentication

No secrets. Both publishes authenticate with the release job's GitHub OIDC identity, which is why it declares `permissions: id-token: write`.

- **MCP Registry** — `mcp-publisher login github-oidc` exchanges the OIDC token for a registry JWT scoped to `io.github.cytoscape/*`.
- **npm** — [trusted publishing](https://docs.npmjs.com/trusted-publishers/). The workflow is trusted by the package itself; see [First-time npm setup](#first-time-npm-setup-already-done-for-reference).

The release workflow must not set `registry-url` on `setup-node`. That makes npm use a placeholder credential instead of the OIDC exchange. The registry is pinned in the bridge package's `publishConfig` instead.

## Gotchas

- **Never delete or retag a published `mcpb-v` release.** The registry entry points straight at that release's `.mcpb` file, so removing it breaks installs for anyone on that version.
- **Published versions can't be taken back.** To correct a bad release, bump the version and publish again.
- **Editing `server.json` on its own changes nothing.** Publishing skips any version already in the registry, so an edit only goes live with a version bump.
