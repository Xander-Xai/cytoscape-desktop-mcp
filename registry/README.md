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
2. Create tag `mcpb-vX.Y.Z` as part of GitHub Release. `release-mcpb` then asserts the version, builds, uploads, publishes to npm, validates, and publishes to the registry.
3. Confirm: `npm view @cytoscape/cytoscape-desktop-mcp-bridge mcpName` and
   `curl "https://registry.modelcontextprotocol.io/v0.1/servers?search=io.github.cytoscape/cytoscape-desktop-mcp-bridge"`

Both publishes are guarded by existence checks, so re-running the job is safe.

## Local mcpb and registry builds (publishes nothing)

```bash
make build_claude_mcpb
make stamp-server-json TAG=mcpb-v1.0.2   # -> build/server.json
make stage-npm-bridge  TAG=mcpb-v1.0.2   # -> build/npm-staging/
.tools/mcp-publisher validate build/server.json
npm publish ./build/npm-staging --access public --dry-run
```

Note `mcp-publisher validate` checks shape against the live registry but **not** namespace ownership — a wrong namespace passes validation and fails only at publish time.

## Authentication

`NPM_TOKEN` must be set as a repo secret for the npm publishing to work.

## Gotchas

- **Never delete or retag a published `mcpb-v` release.** The registry entry points straight at that release's `.mcpb` file, so removing it breaks installs for anyone on that version.
- **Published versions can't be taken back.** To correct a bad release, bump the version and publish again.
- **Editing `server.json` on its own changes nothing.** Publishing skips any version already in the registry, so an edit only goes live with a version bump.
