#!/usr/bin/env -S bash -Eeuo pipefail
path="$(realpath test-paths.txt)"
suffix="$RANDOM"

unit_name="$(systemd-run --user -p "StandardInput=file:$path" --unit="grep-hydra-$suffix" result/bin/grep-hydra)"

echo "grep-hydra-$suffix.service" >> jobs.log
