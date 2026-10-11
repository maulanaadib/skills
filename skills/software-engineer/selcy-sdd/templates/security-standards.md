# Security Standards

Non negotiable rules. Every feature spec inherits these; a feature may add to them but never relax them. If a spec contradicts this file, this file wins.

## Auth and Session

<AUTH_SECURITY_BULLETS>

## Authorization

<AUTHORIZATION_BULLETS>

Who may read and mutate what. The rule every mutation boundary enforces, stated once here so no feature spec invents its own.

## Input Validation

<INPUT_VALIDATION_BULLETS>

## Secrets and Environment

<SECRETS_BULLETS>

## Data Protection

<DATA_PROTECTION_BULLETS>

## Compliance

<COMPLIANCE_BULLETS>

## Security Checklist (per feature)

Every feature spec must be able to answer these. Any "no" is either a scope limit stated in the spec, or a gap.

- [ ] Does it authenticate before reading?
- [ ] Does it authorize before mutating?
- [ ] Is all external input validated at the boundary?
- [ ] Are secrets read from env, never hardcoded or logged?
- [ ] Does it log without leaking secrets or PII?
- [ ] Are errors handled without leaking internals?
