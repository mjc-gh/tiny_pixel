---
description: Fetch a GitHub issue and implement it
model: openrouter/openai/gpt-5.6-luna
---

Fetch the issue to content using:

`gh api repos/mjc-gh/tiny_pixel/issues/$1 | jq -r '"# \(.title)\n\(.body)"'`

**Instructions:**

1. Analyze what needs to be implemented or fixed for the fetched issue
2. Follow the exact plan described in the issue
3. Implement the required changes following the project's coding conventions
4. Follow the checklist in the issue and complete all tasks

**IMPORTANT**: Never commit changes or call git. Only implement the code changes requested in the issue. The user will handle the commits themselves.
