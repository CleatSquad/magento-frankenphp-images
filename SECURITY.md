# Security Policy

## Supported Versions

| Version | Supported          |
|---------| ------------------ |
| 1.0.x   | :white_check_mark: |

## Reporting a Vulnerability

If you discover a security vulnerability:

1. **Do NOT** open a public GitHub issue
2. Send an email to: `contact@cleatsquad.dev`
3. Include: description, steps to reproduce, potential impact

### Response Timeline

- Acknowledgment: Within 48 hours
- Status Update: Within 7 days
- Resolution: Within 14 days

## Security Best Practices

### Environment Variables

```bash
# Never commit .env files
# Use strong passwords (min 16 characters)
MYSQL_ROOT_PASSWORD=<strong-password>
DB_PASSWORD=<strong-password>
RABBITMQ_DEFAULT_PASS=<strong-password>
```

### Production Checklist

- [ ] All default passwords changed
- [ ] SSL/TLS properly configured
- [ ] Database ports not exposed externally
- [ ] Two-Factor Authentication enabled for Magento admin
- [ ] Backups configured

## Security Resources

- [Magento Security Best Practices](https://experienceleague.adobe.com/docs/commerce-operations/implementation-playbook/best-practices/launch/security-best-practices.html)
- [Docker Security](https://docs.docker.com/develop/security-best-practices/)
- [FrankenPHP Security](https://github.com/dunglas/frankenphp/security)
- [PHP Security](https://www.php.net/security)

## Contact

Security inquiries: `contact@cleatsquad.dev`
