## Organisation context index

This workspace is connected to the dine4fit MCP hub, which exposes a `context__get_index`
tool (the exact name is prefixed by the connector, e.g.
`mcp__claude_ai_dine4fit__context__get_index` or `mcp__dine4fit-hub__context__get_index`).

It returns a navigation map of WHERE the company's information lives — projects,
repositories, branding, Confluence wiki, drives, data warehouses, business systems, 
people, etc.
It returns pointers (links + one-line descriptions), NOT the content itself 

**Call `context__get_index` proactively and FIRST** whenever a task needs
company-specific knowledge and you do not already know the exact location — e.g. the
user asks about a project, client, person, team, system, process, policy, metric, or
document, or says "where do I find / who owns / how do we do X". Then follow the
returned pointer through the relevant connector (Confluence, Drive, GitLab, …) using
the user's own access to open the actual source.

Do NOT call it for generic questions that need no company knowledge (general coding,
math, unrelated lookups).
