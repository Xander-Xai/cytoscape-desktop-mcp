# @cytoscape/cytoscape-desktop-mcp-bridge

A stdio-to-HTTP bridge for the [Cytoscape Desktop MCP server](https://github.com/cytoscape/cytoscape-desktop-mcp). It exists to enable agents that only support stdio for local MCP servers and MCP registry and marketplace installers to have an installable package to wrap. 

## Prerequisites — read this first

This package is **only a transport passthrough**. It contains no tools and does nothing on its own. The actual MCP server — every tool, every capability — is hosted inside Cytoscape Desktop by the Cytoscape MCP Server app, served from Cytoscape's built-in CyREST HTTP server.

Before this bridge can do anything, you must:

1. Install **Cytoscape Desktop** 3.10 or later — <https://cytoscape.org>
2. Install the **Cytoscape MCP Server** app — <https://apps.cytoscape.org/apps/cytoscapemcpserver>
3. Have Cytoscape **running**, with that app enabled

If you are configuring an agentic client to use the Cytoscape Desktop MCP, you likely do not need to install this bridge because you can configure the agentic client for a local MCP Streaming HTTP connector and use the port exposed by the Desktop App in Cytoscape Desktop directly, refer to [docs/AgentConfiguration.md](https://github.com/cytoscape/cytoscape-desktop-mcp/blob/main/docs/AgentConfiguration.md).  However, if the agentic application you are using does not support configuring local MCP connectors on the Streaming HTTP transport, then this bridge should be installed and used locally.


## What it does

It is used as a stdio MCP connector in agentic application's MCP configuration. It will then provide a real-time transport bridge from the agentic application stdio to the actual Cytoscape Desktop MCP server which is hosted on the `CyRest` HTTP port published by your Cytoscape Desktop Instance running on your machine.

Set `CYREST_PORT` if you have overridden the default Cytoscape Desktop CyRest port of `1234`.

## License

BSD-3-Clause. Copyright The Regents of the University of California.
