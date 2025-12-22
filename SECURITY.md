# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | ✅ Yes             |
| < 1.0   | ❌ No              |

## Security Features

### Data Protection
- **Local Processing**: All log analysis happens on your Mac
- **API Key Security**: Stored securely in macOS Keychain with encryption
- **No Data Collection**: We don't collect, store, or transmit user data
- **Secure Communication**: All network requests use HTTPS/TLS encryption
- **App Sandboxing**: Restricted file system and network access

### Privacy
- You control all data sharing and API usage
- Clear indication of all network requests
- No analytics, telemetry, or user tracking

## Reporting a Vulnerability

### Do NOT Publicly Disclose
- **Do not** create a public GitHub issue
- **Do not** discuss the vulnerability in public forums

### Report Privately
Send a detailed report to: **security@chadbourne.consulting**

Include:
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Your contact information

### Response Timeline
- **Initial Response**: Within 48 hours
- **Investigation**: Within 1 week
- **Resolution**: Within 2 weeks
- **Disclosure**: After fix is released

We follow responsible disclosure practices and will credit you for the discovery (unless you prefer anonymity).

## Security Best Practices

### API Key Management
- Use the built-in secure storage (Keychain)
- Rotate API keys periodically
- Monitor usage on API provider dashboards
- Use API keys with minimal required permissions

### Network Security
- Ensure bot endpoints use HTTPS
- Only connect to endpoints with valid SSL certificates
- Be aware of what data is being sent to external services

### File Security
- Ensure log files are from trusted sources
- Remove sensitive data from exported reports if needed
- Protect configuration files with appropriate permissions

### Testing Internal Bots
- Ensure test data doesn't contain sensitive information
- Use test environments rather than production systems
- Review exported reports before sharing

### Using Cloud AI Providers
When using OpenAI, Anthropic, or other cloud providers:
- Review provider privacy policies and terms of service
- Understand data retention and usage policies
- Monitor costs and usage patterns
- Consider using local models (Ollama) for sensitive data

## Security Architecture

### Sandboxing
Patience uses macOS App Sandbox with these entitlements:
- `com.apple.security.app-sandbox` - Enables sandboxing
- `com.apple.security.network.client` - Outgoing network connections
- `com.apple.security.files.user-selected.read-write` - User-selected file access

### Network Security
- All HTTP requests use URLSession with default security settings
- Certificate validation is enforced for HTTPS connections
- Timeout and retry logic prevents hanging connections

### Data Handling
- Configuration data stored in app container
- API keys stored in Keychain with app-specific access
- Temporary files cleaned up after use
- No persistent logging of sensitive data

### Code Security
- Swift's memory safety prevents buffer overflows
- Input validation on all user-provided data
- Error handling prevents information leakage

## Threat Model

### Assets Protected
- User API keys and credentials
- Test configurations and scenarios
- Chat logs and conversation data
- Test results and reports

### Mitigations
- **Input Validation**: All file parsing includes bounds checking
- **Secure Communication**: HTTPS enforcement and certificate validation
- **Keychain Storage**: Encrypted storage for sensitive credentials
- **Sandboxing**: Restricted system access and isolation

## Contact Information

- **Security Email**: security@chadbourne.consulting
- **Response Time**: 48 hours for initial response
- **GitHub Issues**: For non-security bugs and feature requests

---

**Last Updated**: December 21, 2025
**Version**: 1.0
