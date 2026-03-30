---
name: vibecode-integration-gitlab
display_name: GitLab
provider_skill: true
integration_dependencies:
  - gitlab
description: >
  GitLab API for managing repositories, issues, merge requests, and CI/CD pipelines.
  Consult this skill:
  1. When the user asks to manage GitLab projects, issues, or merge requests
  2. When the user needs to check CI/CD pipeline status or trigger builds
  3. When the user wants to manage branches, tags, or releases
  4. When the user mentions GitLab, MRs, or CI/CD pipelines
metadata: {"openclaw": {"emoji": "🦊", "requires": {"env": ["GITLAB_ACCESS_TOKEN"]}}}
---

# GitLab Integration

REST API for projects, issues, merge requests, pipelines, and repository management.

**Auth**: `PRIVATE-TOKEN` header via `GITLAB_ACCESS_TOKEN` (Personal Access Token).
**Base URL**: `https://gitlab.com/api/v4` (or self-hosted instance).

```bash
GL="https://gitlab.com/api/v4"

# GitLab uses PRIVATE-TOKEN header (NOT Bearer)
curl -s -H "PRIVATE-TOKEN: $GITLAB_ACCESS_TOKEN" "$GL/<endpoint>"
```

## Projects

```bash
# List my projects
curl -s -H "PRIVATE-TOKEN: $GITLAB_ACCESS_TOKEN" "$GL/projects?membership=true&per_page=20"

# Search projects
curl -s -H "PRIVATE-TOKEN: $GITLAB_ACCESS_TOKEN" "$GL/projects?search=my-app&per_page=10"

# Get project by ID or path
curl -s -H "PRIVATE-TOKEN: $GITLAB_ACCESS_TOKEN" "$GL/projects/{id}"
curl -s -H "PRIVATE-TOKEN: $GITLAB_ACCESS_TOKEN" "$GL/projects/$(python3 -c "import urllib.parse; print(urllib.parse.quote('namespace/project', safe=''))")"
```

## Issues

```bash
# List project issues
curl -s -H "PRIVATE-TOKEN: $GITLAB_ACCESS_TOKEN" "$GL/projects/{id}/issues?state=opened&per_page=20"

# Create issue
curl -s -X POST -H "PRIVATE-TOKEN: $GITLAB_ACCESS_TOKEN" -H "Content-Type: application/json" \
  "$GL/projects/{id}/issues" \
  -d '{"title":"Fix login bug","description":"Users cannot log in with SSO","labels":"bug,critical","assignee_ids":[123]}'

# Update issue
curl -s -X PUT -H "PRIVATE-TOKEN: $GITLAB_ACCESS_TOKEN" -H "Content-Type: application/json" \
  "$GL/projects/{id}/issues/{issue_iid}" \
  -d '{"state_event":"close"}'

# Add comment to issue
curl -s -X POST -H "PRIVATE-TOKEN: $GITLAB_ACCESS_TOKEN" -H "Content-Type: application/json" \
  "$GL/projects/{id}/issues/{issue_iid}/notes" \
  -d '{"body":"Fixed in !45"}'
```

## Merge requests

```bash
# List open MRs
curl -s -H "PRIVATE-TOKEN: $GITLAB_ACCESS_TOKEN" "$GL/projects/{id}/merge_requests?state=opened&per_page=20"

# Get MR details
curl -s -H "PRIVATE-TOKEN: $GITLAB_ACCESS_TOKEN" "$GL/projects/{id}/merge_requests/{mr_iid}"

# Get MR changes (diff)
curl -s -H "PRIVATE-TOKEN: $GITLAB_ACCESS_TOKEN" "$GL/projects/{id}/merge_requests/{mr_iid}/changes"

# Create MR
curl -s -X POST -H "PRIVATE-TOKEN: $GITLAB_ACCESS_TOKEN" -H "Content-Type: application/json" \
  "$GL/projects/{id}/merge_requests" \
  -d '{"source_branch":"feature/login","target_branch":"main","title":"Fix login flow","description":"Closes #42"}'

# Merge MR
curl -s -X PUT -H "PRIVATE-TOKEN: $GITLAB_ACCESS_TOKEN" -H "Content-Type: application/json" \
  "$GL/projects/{id}/merge_requests/{mr_iid}/merge" \
  -d '{"squash":true,"should_remove_source_branch":true}'

# Approve MR
curl -s -X POST -H "PRIVATE-TOKEN: $GITLAB_ACCESS_TOKEN" \
  "$GL/projects/{id}/merge_requests/{mr_iid}/approve"
```

## CI/CD Pipelines

```bash
# List pipelines
curl -s -H "PRIVATE-TOKEN: $GITLAB_ACCESS_TOKEN" "$GL/projects/{id}/pipelines?per_page=10"

# Get pipeline details
curl -s -H "PRIVATE-TOKEN: $GITLAB_ACCESS_TOKEN" "$GL/projects/{id}/pipelines/{pipeline_id}"

# List pipeline jobs
curl -s -H "PRIVATE-TOKEN: $GITLAB_ACCESS_TOKEN" "$GL/projects/{id}/pipelines/{pipeline_id}/jobs"

# Get job log
curl -s -H "PRIVATE-TOKEN: $GITLAB_ACCESS_TOKEN" "$GL/projects/{id}/jobs/{job_id}/trace"

# Retry pipeline
curl -s -X POST -H "PRIVATE-TOKEN: $GITLAB_ACCESS_TOKEN" \
  "$GL/projects/{id}/pipelines/{pipeline_id}/retry"

# Trigger pipeline
curl -s -X POST -H "PRIVATE-TOKEN: $GITLAB_ACCESS_TOKEN" -H "Content-Type: application/json" \
  "$GL/projects/{id}/pipeline" \
  -d '{"ref":"main"}'
```

## Repository

```bash
# List branches
curl -s -H "PRIVATE-TOKEN: $GITLAB_ACCESS_TOKEN" "$GL/projects/{id}/repository/branches?per_page=20"

# List tags
curl -s -H "PRIVATE-TOKEN: $GITLAB_ACCESS_TOKEN" "$GL/projects/{id}/repository/tags"

# Get file content
curl -s -H "PRIVATE-TOKEN: $GITLAB_ACCESS_TOKEN" "$GL/projects/{id}/repository/files/$(python3 -c "import urllib.parse; print(urllib.parse.quote('path/to/file.ts', safe=''))")/raw?ref=main"
```

## Tips

- **Auth is `PRIVATE-TOKEN` header** — not Bearer. This is GitLab-specific.
- **Project paths must be URL-encoded**: `namespace/project` → `namespace%2Fproject`.
- **IDs vs IIDs**: Issue/MR numbers visible in the UI are `iid` (internal ID). Use `iid` for human-facing references.
- **Pagination**: `per_page` (max 100) + `page` params. Check `X-Total` and `X-Next-Page` headers.
- **Self-hosted**: Replace `gitlab.com` with your instance URL.
- **Rate limit**: 2000 requests/minute for authenticated users.

---

*Based on [odyssey4me/gitlab skill](https://skills.sh/odyssey4me/agent-skills/gitlab), [vince-winkintel/gitlab-cli-skills](https://skills.sh/vince-winkintel/gitlab-cli-skills), and [GitLab REST API Reference](https://docs.gitlab.com/ee/api/rest/).*
