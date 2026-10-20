# Pre-publication checklist

Check these before making the repository public or releasing.

## Items

- [ ] Placeholders (`<GITHUB_ID>`, `<NAME>`) have been replaced with real values (`validate.sh` warns about them)
- [ ] None of the forbidden patterns below appear anywhere in the repository (`validate.sh` greps for them)
- [ ] The full `git log -p` has no forbidden patterns, internal paths or personal information either (`validate.sh` does not look at history)
- [ ] No secrets, tokens or keys (`.env`, credential files, hard-coded keys)
- [ ] The skill does not require tools or MCPs specific to one organization (mentioning them as examples is fine)
- [ ] LICENSE, SECURITY.md, CONTRIBUTING.md and the READMEs (English and Korean) are up to date
- [ ] `bash scripts/validate.sh` passes

## Forbidden patterns

`scripts/validate.sh` searches the whole repository for each line of the code block below as a case-insensitive extended regular expression (`grep -iE`).
Empty lines, lines starting with `#` and `<add here>` lines are ignored. Any match is a FAIL.

Categories: company names · project names · internal hosts · personal path patterns

<!-- FORBIDDEN-PATTERNS:BEGIN -->
```
# Company names
<add here>
# Project names
<add here>
# Internal hosts (e.g. \.corp\.example\.com)
<add here>
# Personal path patterns (e.g. /Users/[a-z]+/)
<add here>
```
<!-- FORBIDDEN-PATTERNS:END -->

This file itself is excluded from the search, so adding patterns here is safe.
