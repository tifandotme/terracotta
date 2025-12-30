# Infisical

## Prerequisites

- mise installed
- GCP account with billing enabled
- GCP CLI authenticated: `mise run set-project`
- NeonDB database provisioned
- Upstash Redis provisioned
- Mailgun SMTP credentials
- DNS configured:

```
Type: CNAME
Name: infisical
Value: ghs.googlehosted.com
```

## Setup

### 1. Configure mise

Environment variables are defined in `mise.toml`:

### 2. Deploy

```sh
mise run set-project
mise run terraform:init
mise run terraform:plan
mise run terraform:deploy
```

## Environment Variables

See: <https://infisical.com/docs/self-hosting/configuration/envars>
