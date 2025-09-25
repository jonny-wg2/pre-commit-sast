# pre-commit-sast

Repo containing hooks for SAST tools. Check out `.pre-commit-config.yaml` for additional SAST tools.

## Trivy

Trivy configuration scanner with batch scanning for improved reliability.

### Features

- **Batch scanning**: Scans all files in one operation (eliminates race conditions)
- **Performance optimized**: Reduced I/O priority and efficient execution

### Usage

```yaml
- repo: https://github.com/jonny-wg2/pre-commit-sast
  rev: v0.0.1
  hooks:
    - id: trivyconfig
      args:
        - "--args=--severity HIGH,CRITICAL"
```

### Ignore Files (Optional)

Create any of these files in your repo root - they're auto-detected:

- **`.trivyignore`** - Simple list of IDs to ignore
- **`.trivyignore.yaml`** - Structured ignores with paths and reasons
- **`trivy-policy.yaml`** - Advanced policy rules

No need to specify them in your pre-commit config - the hook finds them automatically.
