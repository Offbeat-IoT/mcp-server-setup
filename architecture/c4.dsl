# C4 model fragment - Offbeat-IoT/mcp-server-setup
# Consumed by Offbeat-IoT/information/scripts/c4/build.py.

mcp_server_setup = softwareSystem "MCP Server Setup" "Docker Compose and Swarm setups that host the MCP servers connecting an AI assistant to Offbeat and third-party services, with a shared MCP network and an OpenCode CLI client container." {
  tags "runtime"

  opencode = container "OpenCode Client" "Interactive OpenCode CLI container on the mcp-network; the MCP client that every hosted server is registered against." "Docker, Node.js"

  custom_mcp_servers = container "Custom MCP Servers" "One container per locally built MCP server - Slack, Signal, Jenkins, Portainer (one per swarm node), Tado, Todoist, Google Workspace, ASUS Router and Yahoo Mail - served over SSE on ports 3101-3117." "Python FastMCP, Node.js and Java, SSE transport"

  headroom_proxy = container "Headroom Proxy" "OpenAI-compatible endpoint that compresses tool outputs, logs and conversation history before they reach the upstream provider." "Docker, Headroom"

  opencode -> custom_mcp_servers "Calls MCP tools over SSE"
  opencode -> headroom_proxy "Routes LLM requests through for context compression"
}
