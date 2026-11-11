#!/bin/sh
# Pre-deploy hook for the mcp-servers stack.
#
# The stack compose file references prebuilt images. Build and push the images
# this repository owns before the rendered stack is deployed, preserving the
# build-then-deploy behaviour of the old bespoke Jenkinsfile.
set -eu

BUILD_SERVICES="yahoo-mail-mcp google-workspace-mcp tado-mcp signal-mcp slack-mcp todoist-mcp asus-router-mcp portainer-build1 portainer-build2 portainer-monitor portainer-observability1 portainer-tools1 portainer-production1 jenkins-mcp"

MCP_DATA_DIR="${MCP_DATA_DIR:-/home/jenkins/mcp-server-setup-data}"

echo "Preparing host data directories under ${MCP_DATA_DIR}"
docker run --rm -v "${MCP_DATA_DIR}:/host-data" alpine:3.20 \
    sh -c 'mkdir -p /host-data/google-workspace /host-data/tado /host-data/signal-cli /host-data/playwright /host-data/headroom'

echo "Building MCP server images"
docker compose -f docker-compose.build.yml build ${BUILD_SERVICES}

echo "Pushing MCP server images"
docker compose -f docker-compose.build.yml push ${BUILD_SERVICES}

# Swarm was created with --resolve-image never, so a moving :latest tag keeps the
# digest resolved by the previous deploy. Force each first-party service to pull
# the image that was just pushed. Missing services (first deploy) are ignored;
# the stack deploy creates them.
echo "Refreshing first-party service images"
for pair in \
    yahoo-mail-mcp:yahoo-mail-mcp \
    google-workspace-mcp:google-workspace-mcp \
    tado-mcp:tado-mcp \
    signal-mcp:signal-mcp \
    slack-mcp:slack-mcp \
    todoist-mcp:todoist-mcp \
    asus-router-mcp:asus-router-mcp \
    jenkins-mcp:jenkins-mcp \
    portainer-build1:portainer-mcp \
    portainer-build2:portainer-mcp \
    portainer-monitor:portainer-mcp \
    portainer-observability1:portainer-mcp \
    portainer-tools1:portainer-mcp \
    portainer-production1:portainer-mcp; do
    service="${pair%%:*}"
    image="${pair##*:}"
    docker service update --detach=false --force --with-registry-auth \
        --image "registry:5000/offbeat-iot/${image}:latest" \
        "mcp-servers_${service}" >/dev/null 2>&1 || true
done

# Let Swarm finish recording the update specs before the stack deploy issues its
# own updates; otherwise it can fail with "update out of sequence".
sleep 15
