# @cytoscape/cytoscape-desktop-mcp-bridge

A stdio-to-HTTP bridge for the [Cytoscape Desktop MCP server](https://github.com/cytoscape/cytoscape-desktop-mcp). It exists so MCP registry and marketplace installers have an installable package to wrap — it is **not** the recommended way to set this up by hand.

**If you are configuring a client yourself, do not install this.** The MCP server runs inside Cytoscape Desktop and already speaks Streamable HTTP. Point your client straight at it:

```
http://localhost:1234/mcp
```

That is fewer moving parts than this bridge — no Node process, no extra hop. Replace `1234` if you changed the CyREST port under **Edit > Preferences > REST API**. See [docs/AgentConfiguration.md](https://github.com/cytoscape/cytoscape-desktop-mcp/blob/main/docs/AgentConfiguration.md) for per-client instructions.

## What it does

Reads newline-delimited JSON-RPC on stdin, POSTs each message to Cytoscape's `/mcp` endpoint, and writes responses back to stdout — unwrapping `text/event-stream` framing and replaying the MCP session id. Zero dependencies; Node.js built-ins only.

Set `CYREST_PORT` to override the default port of `1234`.

## Requirements

Cytoscape Desktop 3.10+ with the Cytoscape MCP app installed and running. Without it there is no server to bridge to.

## License

BSD-3-Clause. Copyright The Regents of the University of California.
