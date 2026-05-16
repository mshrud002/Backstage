#!/usr/bin/env bash
set -euo pipefail

REGISTRY="${REGISTRY:-ghcr.io}"
OWNER="${OWNER:-your-org}"
IMAGE_NAME="${IMAGE_NAME:-backstage}"
TAG="${TAG:-latest}"
FULL_IMAGE="${REGISTRY}/${OWNER}/${IMAGE_NAME}:${TAG}"

echo "Building Backstage image: ${FULL_IMAGE}"

docker build -t "${FULL_IMAGE}" .

echo "Pushing image to registry..."
docker push "${FULL_IMAGE}"

echo "Done! Image: ${FULL_IMAGE}"
