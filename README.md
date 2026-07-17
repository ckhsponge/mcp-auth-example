# MCP Auth Example

A minimal Ruby example demonstrating OAuth 2.0 authorization for an MCP (Model Context Protocol) server.

## What it does

- Implements an OAuth 2.0 authorization server (PKCE flow) suitable for use as an MCP gateway
- Exposes `/.well-known/openid-configuration` and `/.well-known/jwks.json` for discovery
- Exposes `/.well-known/oauth-authorization-server` for MCP client discovery
- Issues signed JWT bearer tokens (RS512) via `/oauth/token`
- Includes a dummy `Tool` model with `handle` and `handle_user` methods that return an example MCP-formatted tool response (current date and time)
- Simple web UI with login/logout and an OAuth consent page

## Stack

- Ruby / Sinatra
- Slim templates + Tailwind CSS (CDN)
- In-memory fake User and UserOauth models (no database)
- JWT signing via the `jwt` gem

## Running locally

Copy the example env file and fill in your values:

```bash
cp .env.example .env
# edit .env — at minimum generate a ROOT_GATEWAY_PEM:
openssl genrsa 2048
```

Then install gems and start the server:

```bash
bin/gems.sh   # install gems
bin/start.sh  # start the server
```

Or manually:

```bash
cd app && bundle install && bundle exec puma -p 9292
```

## OAuth flow

```
Client → GET  /oauth/authorize       # consent page
       → POST /oauth/authorize       # user approves, returns auth code
       → POST /oauth/token           # exchange code + PKCE verifier for JWT
       → GET  /.well-known/jwks.json # verify token signature
```

## Example tool response

Both `Tool.handle` and `Tool.handle_user` return MCP-formatted output:

```json
{
  "content": [{ "type": "text", "text": "The current date and time is 2025-01-01 12:00:00 UTC." }],
  "isError": false
}
```

## Environment variables

Copy `.env.example` to `.env` and fill in values.

| Variable | Description |
|---|---|
| `HOST_NAME` | Hostname used in JWT issuer and discovery URLs |
| `PORT_OVERRIDE` | Port appended to BASE_URL (set for local dev) |
| `PROTOCOL` | `http` or `https` |
| `SESSION_SECRET` | Secret for signing session cookies |
| `ROOT_GATEWAY_PEM` | RSA private key PEM for signing JWTs (`openssl genrsa 2048`) |
| `ROOT_GATEWAY_TOKEN_SCOPE` | Scope included in issued tokens |
| `ROOT_GATEWAY_CLIENT_ID` | Client ID included in issued tokens |
