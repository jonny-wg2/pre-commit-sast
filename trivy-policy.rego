# Custom Trivy policy file in Rego format
# This allows very granular control over what gets ignored

package trivy

import rego.v1

# Ignore MEDIUM severity issues in test files
ignore contains res if {
    input.Rule.Severity == "MEDIUM"
    regex.match(`.*test.*`, input.Filepath)
    res := {
        "filepath": input.Filepath,
        "rule": input.Rule.ID,
        "reason": "MEDIUM severity issues ignored in test files"
    }
}

# Ignore specific CVE in vendor code
ignore contains res if {
    input.Rule.ID == "CVE-2021-44228"
    startswith(input.Filepath, "vendor/")
    res := {
        "filepath": input.Filepath,
        "rule": input.Rule.ID,
        "reason": "Log4j vulnerability in vendor dependencies"
    }
}

# Ignore Kubernetes security contexts in dev configs
ignore contains res if {
    input.Rule.ID == "AVD-KSV-0014"
    contains(input.Filepath, "/dev/")
    res := {
        "filepath": input.Filepath,
        "rule": input.Rule.ID,
        "reason": "Development environment - security context not required"
    }
}

# Ignore Docker root user in development images
ignore contains res if {
    input.Rule.ID == "AVD-DS-0002"
    endswith(input.Filepath, "Dockerfile.dev")
    res := {
        "filepath": input.Filepath,
        "rule": input.Rule.ID,
        "reason": "Development dockerfile - root user acceptable"
    }
}
