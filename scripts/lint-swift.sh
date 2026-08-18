#!/usr/bin/env bash
set -euo pipefail
swiftformat GamePlayer GamePlayerTests GamePlayerUITests --lint
swiftlint lint --strict --no-cache
