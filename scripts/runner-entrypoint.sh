#!/bin/sh
set -e

CONFIG_FILE="/etc/gitlab-runner/config.toml"
CERT_FILE="/etc/gitlab-runner/certs/gitlab.local.crt"

# Wait for GitLab to be ready
echo "Waiting for GitLab to be available at ${CI_SERVER_URL}..."
until wget -q -O /dev/null --no-check-certificate "${CI_SERVER_URL}/users/sign_in" 2>/dev/null; do
    echo "GitLab not ready yet, waiting 10s..."
    sleep 10
done
echo "GitLab is ready!"

# Check if runner is already registered
if [ -f "$CONFIG_FILE" ] && grep -q "token" "$CONFIG_FILE"; then
    echo "Runner already registered, starting..."
else
    echo "Registering runner..."

    # Check if cert file exists
    if [ -f "$CERT_FILE" ]; then
        echo "Using certificate from $CERT_FILE"
        gitlab-runner register \
            --non-interactive \
            --url "${CI_SERVER_URL}" \
            --registration-token "${REGISTRATION_TOKEN}" \
            --executor "${RUNNER_EXECUTOR:-docker}" \
            --docker-image "${RUNNER_DOCKER_IMAGE:-alpine:latest}" \
            --description "${RUNNER_NAME:-docker-runner}" \
            --tag-list "${RUNNER_TAGS:-docker,local}" \
            --run-untagged="true" \
            --locked="false" \
            --tls-ca-file="$CERT_FILE"
    else
        echo "No certificate found, registering without TLS CA file..."
        gitlab-runner register \
            --non-interactive \
            --url "${CI_SERVER_URL}" \
            --registration-token "${REGISTRATION_TOKEN}" \
            --executor "${RUNNER_EXECUTOR:-docker}" \
            --docker-image "${RUNNER_DOCKER_IMAGE:-alpine:latest}" \
            --description "${RUNNER_NAME:-docker-runner}" \
            --tag-list "${RUNNER_TAGS:-docker,local}" \
            --run-untagged="true" \
            --locked="false"
    fi

    echo "Runner registered successfully!"
fi

# Start the runner
exec gitlab-runner run --user=gitlab-runner --working-directory=/home/gitlab-runner
