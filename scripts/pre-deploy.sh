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
SERVICES=""
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
    SERVICES="${SERVICES} ${service}"
    # Do not wait for convergence here: a service that cannot start would block
    # the hook indefinitely. The deploy's readiness check owns rollout failures.
    docker service update --detach=true --force --with-registry-auth \
        --image "registry:5000/offbeat-iot/${image}:latest" \
        "mcp-servers_${service}" >/dev/null 2>&1 || true
done

# Wait (bounded) until Swarm has recorded every update spec, otherwise the stack
# deploy can fail with "update out of sequence".
i=0
while [ "${i}" -lt 24 ]; do
    busy=0
    for service in ${SERVICES}; do
        state="$(docker service inspect "mcp-servers_${service}" --format '{{if .UpdateStatus}}{{.UpdateStatus.State}}{{end}}' 2>/dev/null || true)"
        if [ "${state}" = "updating" ] || [ "${state}" = "paused" ]; then
            busy=1
        fi
    done
    [ "${busy}" -eq 0 ] && break
    sleep 5
    i=$((i + 1))
done
