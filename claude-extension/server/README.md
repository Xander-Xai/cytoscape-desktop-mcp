# @cytoscape/cytoscape-desktop-mcp-bridge

A stdio-to-HTTP bridge for the [Cytoscape Desktop MCP server](https://github.com/cytoscape/cytoscape-desktop-mcp). It exists so MCP registry and marketplace installers have an installable package to wrap — it is **not** the recommended way to set this up by hand.

## Prerequisites — read this first

This package is **only a transport passthrough**. It contains no tools and does nothing on its own. The actual MCP server — every tool, every capability — is hosted inside Cytoscape Desktop by the Cytoscape MCP Server app, served from Cytoscape's built-in CyREST HTTP server.

Before this bridge can do anything, you must:

1. Install **Cytoscape Desktop** 3.10 or later — <https://cytoscape.org>
2. Install the **Cytoscape MCP Server** app — <https://apps.cytoscape.org/apps/cytoscapemcpserver>
3. Have Cytoscape **running**, with that app enabled

Without a running Cytoscape and that app installed, this bridge has nothing to connect to and every tool call will fail.

**If you are configuring a client yourself, do not install this.** The MCP server runs inside Cytoscape Desktop and already speaks Streamable HTTP. Point your client straight at it:

```
http://localhost:1234/mcp
```

That is fewer moving parts than this bridge — no Node process, no extra hop. Replace `1234` if you changed the CyREST port under **Edit > Preferences > REST API**. See [docs/AgentConfiguration.md](https://github.com/cytoscape/cytoscape-desktop-mcp/blob/main/docs/AgentConfiguration.md) for per-client instructions.

## What it does

Reads newline-delimited JSON-RPC on stdin, POSTs each message to the `/mcp` endpoint on Cytoscape's CyREST HTTP server, and writes responses back to stdout — unwrapping `text/event-stream` framing and replaying the MCP session id. That is the whole of it: zero dependencies, zero tools, Node.js built-ins only.

Set `CYREST_PORT` to override the default port of `1234`.

## License

BSD-3-Clause. Copyright The Regents of the University of California.
