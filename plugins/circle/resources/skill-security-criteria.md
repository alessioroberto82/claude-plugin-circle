# Skill Security Criteria

This document defines the security criteria for reviewing external skills before installation. Read this during the security review phase of `circle:skills-discovery`.

## Risk Classification

### PASS (Low Risk)
The skill is safe to install. It only reads information and does not modify files or execute commands.

**Allowed capabilities**:
- Read-only file access and search
- Search-engine queries that do not transmit project data

**Characteristics**:
- No shell commands
- No file modifications
- No external network calls beyond documented APIs
- No access to sensitive files

### WARN (Medium Risk)
The skill modifies files or communicates externally. Review carefully before approving.

**Flagged capabilities**:
- File or notebook modification
- External HTTP communication
- Shell execution, including non-destructive commands (`ls`, `git status`, `npm test`, `npx`, `cat`)

**Characteristics**:
- File modifications are scoped to project directory
- Network calls are to documented, well-known APIs
- Shell commands are read-only or standard dev tools

### BLOCK (High Risk)
The skill poses a security threat. Do NOT install.

**Blocked patterns**:
- Shell execution with destructive commands: `rm -rf`, `rm -f` on paths outside project
- Shell execution of network content: `curl | sh`, `curl | bash`, `wget | sh`
- Dynamic evaluation: `eval`, `exec`, `source` with untrusted input
- Access to sensitive files: `.env`, `credentials`, `secrets`, `tokens`, API keys, SSH keys
- Access to system paths: `~/.ssh/`, `~/.aws/`, `~/.config/`, `/etc/`, `/usr/`
- Environment variable reading for secrets: `$API_KEY`, `$SECRET`, `$TOKEN`, `$PASSWORD`
- `dangerouslyDisableSandbox: true` or equivalent bypass flags
- Obfuscated code: base64-encoded commands, encoded URLs, hex-encoded strings
- Data exfiltration: `curl -X POST`, `wget --post-data`, outbound `nc`/`netcat`

## Detailed Patterns to Flag

### Shell Command Analysis
When a skill uses a shell, inspect each command for:

| Pattern | Risk | Verdict |
|---------|------|---------|
| `rm -rf /` or `rm -rf ~` | Destructive | BLOCK |
| `rm -rf` on project-scoped paths | Caution | WARN |
| `curl \| sh` or `curl \| bash` | Remote code execution | BLOCK |
| `eval "$variable"` | Code injection | BLOCK |
| `git push --force` | Destructive | WARN |
| `npm install`, `npx` | Dependency install | WARN |
| `git status`, `git diff` | Read-only | PASS |
| `ls`, `cat`, `head` | Read-only | PASS |

### File Access Analysis
When a skill reads or writes files, check paths for:

| Path Pattern | Risk | Verdict |
|--------------|------|---------|
| `.env`, `.env.*` | Secrets exposure | BLOCK |
| `*credentials*`, `*secret*` | Secrets exposure | BLOCK |
| `~/.ssh/*`, `~/.aws/*` | System credentials | BLOCK |
| `~/.config/*` | System config | WARN |
| Project-scoped paths | Normal | PASS |

### Network Analysis
When a skill uses web access or shell network commands:

| Pattern | Risk | Verdict |
|---------|------|---------|
| Web access to documented API | External comm | WARN |
| `curl` GET to known API | External comm | WARN |
| `curl -X POST` with project data | Data exfiltration | BLOCK |
| `nc`/`netcat` outbound | Data exfiltration | BLOCK |

## Security Report Format

After analysis, generate a report in this format:

```
SKILL SECURITY REPORT
=====================
Skill: <owner/repo>
Verdict: PASS | WARN | BLOCK

Risk Level: Low | Medium | High
Capabilities Used: [list of capabilities declared or detected]
Shell Commands: [list of shell commands found]
Files Accessed: [list of file paths referenced]
Network Calls: [list of URLs or endpoints]

Findings:
- [Finding 1 with severity]
- [Finding 2 with severity]

Recommendation: [Install / Review carefully / Do NOT install]
```

## Verdict Rules

1. If ANY BLOCK pattern is found → verdict is **BLOCK**
2. If WARN patterns found but no BLOCK → verdict is **WARN**
3. If only PASS patterns found → verdict is **PASS**
4. If unable to analyze (repo not accessible) → verdict is **WARN** (caution)
