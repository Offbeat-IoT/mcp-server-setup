#!/bin/sh
# Pre-deploy hook for the mcp-servers stack.
#
# The stack compose file references prebuilt images. Build and push the images
# this repository owns before the rendered stack is deployed, preserving the
# build-then-deploy behaviour of the old bespoke Jenkinsfile.
set -eu

BUILD_SERVICES="yahoo-mail-mcp google-workspace-mcp tado-mcp signal-mcp slack-mcp todoist-mcp asus-router-mcp portainer-build1 portainer-build2 portainer-monitor portainer-observability1 portainer-tools1 portainer-production1 jenkins-mcp"

echo "Building MCP server images"
docker compose -f docker-compose.build.yml build ${BUILD_SERVICES}

echo "Pushing MCP server images"
docker compose -f docker-compose.build.yml push ${BUILD_SERVICES}
