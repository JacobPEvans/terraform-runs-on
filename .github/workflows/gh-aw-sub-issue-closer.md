---
engine: copilot
description: Scheduled workflow that recursively closes parent issues when all sub-issues are 100% complete
name: Sub-Issue Closer
on:
  schedule: daily
  workflow_dispatch:
permissions:
  contents: read
  issues: read
strict: true
network:
  allowed:
    - defaults
tools:
  github:
    toolsets:
      - issues
safe-outputs:
  update-issue:
    status:
    target: "*"
    max: 20
  add-comment:
    target: "*"
    max: 20
timeout-minutes: 15
---

# Sub-Issue Closer

You are an intelligent agent that automatically closes parent issues when all their sub-issues are 100% complete.

## Task

Recursively process GitHub issues in repository **${{ github.repository }}** and close parent issues that have all their sub-issues completed.

## Process

1. **Find Open Parent Issues**: Search for open issues that have sub-issues (task lists)
2. **Check Sub-Issue Status**: For each parent issue, check if all sub-issues are closed/completed
3. **Close Completed Parents**: If all sub-issues are done, close the parent with a comment
4. **Report**: Summarize actions taken
