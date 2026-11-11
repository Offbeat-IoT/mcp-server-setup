@Library('shared-jenkins-pipelines@main') _

// Build the MCP server images and deploy the mcp-servers stack to build1 with
// the shared stack pipeline.
//
// The stack lives on build1 only (single-node Swarm). Image build and push are
// preserved through scripts/pre-deploy.sh, and the Jenkins credentials the
// jenkins-mcp/slack-mcp services need are bound during rendering and deploy.
stackRepoCiPipeline(
    stackMembershipVersion: 'main',
    applicationVersionsRef: 'main',
    buildNode: 'build1',
    sourceRepo: 'Offbeat-IoT/mcp-server-setup',
    runProductionDeploy: false,
    credentials: [
        string(credentialsId: 'mcp-jenkins-url', variable: 'MCP_JENKINS_URL'),
        string(credentialsId: 'mcp-jenkins-username', variable: 'MCP_JENKINS_USERNAME'),
        string(credentialsId: 'mcp-jenkins-api-token', variable: 'MCP_JENKINS_API_TOKEN'),
        string(credentialsId: 'slack-bot-token', variable: 'MCP_SLACK_BOT_TOKEN')
    ],
    environment: [
        'JENKINS_URL'        : '$MCP_JENKINS_URL',
        'JENKINS_USERNAME'   : '$MCP_JENKINS_USERNAME',
        'JENKINS_API_TOKEN'  : '$MCP_JENKINS_API_TOKEN',
        'SLACK_BOT_TOKEN'    : '$MCP_SLACK_BOT_TOKEN',
        'MCP_DATA_DIR'       : '/home/jenkins/mcp-server-setup-data'
    ]
)
