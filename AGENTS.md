# Multi-app terraform configurations

This repo manages self-hosted apps on GCP using Terraform. Each app is organized by top-level directory (e.g. `infisical/`).

Each directory have their own mise.toml, you MUST must run `mise tasks` inside the directory of the relevant app you are working on at the start of every converstation.

As coding agent, do NOT run deploy or destroy terraform command yourself. Leave that to human.

Always run `mise run check` after you reconfigure terraform.
