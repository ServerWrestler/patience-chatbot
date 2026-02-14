# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| 1.0.x   | ✅ Yes    |
| < 1.0   | ❌ No     |

## Security Features

- **Local Processing**: All analysis happens on your Mac
- **Keychain Storage**: API keys encrypted via macOS Keychain
- **No Data Collection**: No telemetry or user tracking
- **HTTPS Enforcement**: All external requests use TLS
- **App Sandbox**: Restricted system access

## Reporting Vulnerabilities

**Do NOT create public GitHub issues for security vulnerabilities.**

Email: **security@chadbourne.consulting**

Include:
- Description of the vulnerability
- Steps to reproduce
- Potential impact

**Response Timeline:**
- Initial response: 48 hours
- Investigation: 1 week
- Resolution: 2 weeks

## Best Practices

### API Keys
- Use built-in Keychain storage
- Rotate keys periodically
- Use minimal permissions

### Network
- Use HTTPS endpoints only
- Review data sent to external services

### Testing
- Use test environments, not production
- Remove sensitive data from exported reports
- Consider Ollama for privacy-sensitive testing

## Security Architecture

**Entitlements:**
- `com.apple.security.app-sandbox`
- `com.apple.security.network.client`
- `com.apple.security.files.user-selected.read-write`

**Data Handling:**
- Configs in app container
- API keys in Keychain
- No persistent logging of sensitive data

## Contact

- Security issues: security@chadbourne.consulting
- General issues: [GitHub Issues](https://github.com/ServerWrestler/patience-chatbot/issues)
