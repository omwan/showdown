#!/bin/bash

export MIX_ENV=prod
export PORT=4793

echo "Stopping old copy of app, if any..."

_build/prod/rel/showdown/bin/showdown stop || true

echo "Starting app..."

# Foreground for testing and for systemd
_build/prod/rel/showdown/bin/showdown foreground
