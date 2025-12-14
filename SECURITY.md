# Security Policy

## Supported Versions

We actively support the following versions of Patience with security updates:

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | ✅ Yes             |
| < 1.0   | ❌ No              |

## Security Features

### App Sandboxing
Patience runs in a secure sandbox environment that:
- Restricts file system access to user-selected files only
- Limits network access to configured endpoints
- Prevents unauthorized system modifications
- Isolates the application from other processes

### Data Protection
- **Local Processing**: All log analysis happens entirely on your Mac
- **API Key Security**: Stored securely in macOS Keychain with encryption
- **No Data Collection**: We don't collect, store, or transmit user data
- **Secure Communication**: All network requests use HTTPS/TLS encryption

### Privacy Safeguards
- **User Control**: You control all data sharing and API usage
- **Transparent Operations**: Clear indication of all network requests
- **Minimal Permissions**: Only requests necessary system permissions
- **No Tracking**: No analytics, telemetry, or user tracking

## Reporting a Vulnerability

We take security vulnerabilities seriously. If you discover a security issue, please follow these steps:

### 1. Do NOT Publicly Disclose
- **Do not** create a public GitHub issue
- **Do not** discuss the vulnerability in public forums
- **Do not** share details on social media

### 2. Report Privately
Send a detailed report to: **security@chadbourne.consulting**

Include:
- Description of the vulnerability
- Steps to reproduce the issue
- Potential impact assessment
- Suggested fix (if you have one)
- Your contact information

### 3. What to Expect

**Initial Response**: Within 48 hours
- Acknowledgment of your report
- Initial assessment of the issue
- Timeline for investigation

**Investigation**: Within 1 week
- Detailed analysis of the vulnerability
- Confirmation of impact and severity
- Development of fix strategy

**Resolution**: Within 2 weeks
- Security patch development
- Testing and validation
- Coordinated disclosure timeline

**Disclosure**: After fix is released
- Public security advisory
- Credit to reporter (if desired)
- Details of the fix

### 4. Responsible Disclosure

We follow responsible disclosure practices:
- We will work with you to understand and fix the issue
- We will keep you informed throughout the process
- We will credit you for the discovery (unless you prefer anonymity)
- We will coordinate public disclosure after the fix is available

## Security Best Practices for Users

### API Key Management
- **Store Safely**: Use the built-in secure storage (Keychain)
- **Rotate Regularly**: Change API keys periodically
- **Monitor Usage**: Check API provider dashboards for unusual activity
- **Limit Scope**: Use API keys with minimal required permissions

### Network Security
- **Verify Endpoints**: Ensure bot endpoints use HTTPS
- **Trust Certificates**: Only connect to endpoints with valid SSL certificates
- **Monitor Traffic**: Be aware of what data is being sent to external services
- **Use VPN**: Consider VPN for additional network security

### File Security
- **Scan Files**: Ensure log files are from trusted sources
- **Backup Data**: Keep backups of important test configurations
- **Clean Up**: Remove sensitive data from exported reports if needed
- **Access Control**: Protect configuration files with appropriate permissions

### System Security
- **Keep Updated**: Install macOS security updates promptly
- **Use Firewall**: Enable macOS firewall for additional protection
- **Monitor Permissions**: Review app permissions regularly
- **Secure Storage**: Use FileVault disk encryption

## Common Security Scenarios

### Testing Internal Bots
When testing internal company chatbots:
- Ensure test data doesn't contain sensitive information
- Use test environments rather than production systems
- Review exported reports before sharing
- Consider network isolation for sensitive tests

### Using Cloud AI Providers
When using OpenAI, Anthropic, or other cloud providers:
- Review provider privacy policies and terms of service
- Understand data retention and usage policies
- Use API keys with appropriate rate limits
- Monitor costs and usage patterns
- Consider using local models (Ollama) for sensitive data

### Sharing Results
When sharing test results:
- Remove sensitive information from reports
- Redact personal or confidential data
- Use secure channels for transmission
- Consider who has access to shared reports

## Security Architecture

### Sandboxing Details
Patience uses macOS App Sandbox with these entitlements:
- `com.apple.security.app-sandbox` - Enables sandboxing
- `com.apple.security.network.client` - Outgoing network connections
- `com.apple.security.files.user-selected.read-write` - User-selected file access

### Network Security
- All HTTP requests use URLSession with default security settings
- Certificate validation is enforced for HTTPS connections
- No custom certificate validation or bypassing
- Timeout and retry logic prevents hanging connections

### Data Handling
- Configuration data stored in app container
- API keys stored in Keychain with app-specific access
- Temporary files cleaned up after use
- No persistent logging of sensitive data

### Code Security
- Swift's memory safety prevents buffer overflows
- No use of unsafe APIs or manual memory management
- Input validation on all user-provided data
- Error handling prevents information leakage

## Threat Model

### Assets Protected
- User API keys and credentials
- Test configurations and scenarios
- Chat logs and conversation data
- Test results and reports

### Potential Threats
- **Malicious Log Files**: Crafted files that could cause crashes or data exposure
- **Network Attacks**: Man-in-the-middle or endpoint spoofing
- **API Key Theft**: Unauthorized access to stored credentials
- **Data Exfiltration**: Unauthorized transmission of sensitive data

### Mitigations
- **Input Validation**: All file parsing includes bounds checking and validation
- **Secure Communication**: HTTPS enforcement and certificate validation
- **Keychain Storage**: Encrypted storage for sensitive credentials
- **Sandboxing**: Restricted system access and isolation

## Security Updates

### Automatic Updates
- Security updates are delivered through the Mac App Store (when available)
- Critical security fixes are prioritized for immediate release
- Users are notified of important security updates

### Manual Updates
- Check for updates regularly if not using automatic updates
- Subscribe to security advisories for notifications
- Review changelog for security-related fixes

## Compliance and Standards

### Privacy Compliance
- **GDPR**: No personal data collection or processing
- **CCPA**: No sale or sharing of personal information
- **COPPA**: No collection of data from children

### Security Standards
- Follows Apple's App Store security guidelines
- Implements OWASP secure coding practices
- Uses industry-standard encryption and security protocols

## Contact Information

### Security Team
- **Email**: security@chadbourne.consulting
- **Response Time**: 48 hours for initial response
- **Languages**: English

### General Support
- **GitHub Issues**: For non-security bugs and feature requests
- **Documentation**: Check DOCUMENTATION.md for common questions

## Acknowledgments

We thank the security research community for helping keep Patience secure. Special thanks to:

- Security researchers who have responsibly disclosed vulnerabilities
- The Swift and macOS security communities
- Apple's security team for platform-level protections

---

**Last Updated**: 2025-12-13
**Version**: 1.0

