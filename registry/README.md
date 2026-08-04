# MCP Registry publishing

This directory holds the metadata for the project's entry in the [official MCP Registry](https://modelcontextprotocol.io/registry/), published as:

```
io.github.cytoscape/cytoscape-desktop-mcp-bridge
```

`server.json` is a **template**. Its `version`, the mcpb `identifier`, and `fileSha256` are `PLACEHOLDER`/`0.0.0` on purpose — `make stamp-server-json` fills them in and writes `build/server.json`. The tracked file is never mutated by a release.

## What the user must have installed

Whatever a client installs from this registry entry — the `.mcpb` or the npm package — it is **only a transport passthrough**. It carries no tools. The MCP server itself is hosted inside Cytoscape Desktop by the Cytoscape MCP Server app, served from Cytoscape's built-in CyREST HTTP server.

So an install from the registry is only half the setup. The user also needs:

1. **Cytoscape Desktop** 3.10 or later — <https://cytoscape.org>
2. The **Cytoscape MCP Server** app — <https://apps.cytoscape.org/apps/cytoscapemcpserver>
3. Cytoscape **running**, with that app enabled

The registry schema has nowhere to express this. `description` is capped at 100 characters and there is no prerequisite field, so the only places it can be stated are `websiteUrl` (the repo README), the `.mcpb` manifest description that Claude Desktop shows at install time, and the npm package README. Keep all three saying it.

## What gets published, and what does not

The registry hosts metadata only. The entry lists two packagings of the **bridge**, side by side:

| Entry | What a client does with it |
|---|---|
| `registryType: mcpb` | Downloads `cytoscape-mcp.mcpb` from a GitHub release |
| `registryType: npm` | Runs `npx @cytoscape/cytoscape-desktop-mcp-bridge` |

These are parallel, not layered — a client picks whichever it supports; neither wraps the other. The npm package exists so registry-driven and marketplace installers have something installable to wrap. **It is intentionally not documented as an end-user option** in `docs/AgentConfiguration.md`: any client that can run `npx` can almost certainly take the HTTP URL directly, which is strictly better.

The Cytoscape App JAR has **no** registrable package type — it is distributed through the [Cytoscape App Store](https://apps.cytoscape.org/apps/cytoscapemcpserver), which the registry knows nothing about. The registry entry therefore describes only the bridge, which is why the prerequisites above have to be communicated out of band.

## Versioning

`claude-extension/manifest.json`'s `version` is the single source of truth for the bridge, hand-bumped only when the bridge materially changes. Three things derive from it at publish time:

- the registry entry's top-level `version`
- the npm package entry's `version`
- the published npm package's `version` (the tracked `claude-extension/server/package.json` keeps a `0.0.0` placeholder)

The `mcpb-vX.Y.Z` tag restates that same number, and `make check-bridge-version` fails the release if they disagree. **Do not "fix" the manifest version to match the JAR version** — the divergence is deliberate. The bridge is ~130 lines of transport plumbing with zero tools; versioning it by app releases would advertise a number that says nothing about which tools a user actually gets.

Consequence: most app releases publish nothing here. Both guards skip and the job exits 0.

## Cutting a bridge release

1. Bump `version` in `claude-extension/manifest.json`.
2. Optionally tag `mcpb-vX.Y.Z-rc.N` first — RC tags build and upload the bundle but **never** publish, so this dry-runs job routing and the version assertion at zero risk.
3. Tag `mcpb-vX.Y.Z` and publish a GitHub Release. `release-mcpb` then asserts the version, builds, uploads, publishes to npm, validates, and publishes to the registry.
4. Confirm: `npm view @cytoscape/cytoscape-desktop-mcp-bridge mcpName` and
   `curl "https://registry.modelcontextprotocol.io/v0.1/servers?search=io.github.cytoscape/cytoscape-desktop-mcp-bridge"`

Both publishes are guarded by existence checks, so re-running the job is safe.

## Local inspection (publishes nothing)

```bash
make build_claude_mcpb
make stamp-server-json TAG=mcpb-v1.0.2   # -> build/server.json
make stage-npm-bridge  TAG=mcpb-v1.0.2   # -> build/npm-staging/
.tools/mcp-publisher validate build/server.json
npm publish ./build/npm-staging --access public --dry-run
```

Note `mcp-publisher validate` checks shape against the live registry but **not** namespace ownership — a wrong namespace passes validation and fails only at publish time.

## Authentication

CI uses GitHub OIDC: the job declares `id-token: write`, and the registry converts the token's `repository_owner` claim into publish rights for `io.github.cytoscape/*`. No secret, no PAT. `make publish-registry` picks the method automatically — `github-oidc` when `ACTIONS_ID_TOKEN_REQUEST_URL` is set, otherwise the interactive `github` device flow (which requires membership in the `cytoscape` GitHub org).

`NPM_TOKEN` must be set as a repo secret for the npm half, and the `@cytoscape` scope must exist.

## Gotchas

- **Do not delete or retag the bridge release** the entry points at. `identifier` pins that release's asset, and it stays pinned across later app releases.
- Registry versions are append-only. Withdrawing one uses `mcp-publisher status`, not deletion.
- `description` is capped at **100 characters** by the registry schema — shorter than the `.mcpb` manifest's description, which is why they differ.
- Metadata-only changes here (description, `websiteUrl`) cannot be published without a bridge version bump, since the guard keys on the version.
