┌─────────────────────────────────────────────────────────────────────────────┐
│ LAB 6.1 KEY TAKEAWAYS │
├─────────────────────────────────────────────────────────────────────────────┤
│ │
│ 1. CONTAINER BASICS │
│ • Container = lightweight, isolated process with bundled dependencies │
│ • Image = template (from registry), Container = running instance │
│ • Start in seconds vs minutes for VMs │
│ │
│ 2. ACI FUNDAMENTALS │
│ • Container Group = one or more containers sharing lifecycle/network │
│ • Containers in same group communicate via localhost │
│ • Per-second billing - stop when not using! │
│ │
│ 3. RESTART POLICIES │
│ • Always: Long-running services (web servers) │
│ • OnFailure: Batch jobs that should retry │
│ • Never: One-time tasks, CI/CD jobs │
│ │
│ 4. SIDECAR PATTERN │
│ • Multiple containers working together │
│ • Main app + supporting containers (logging, monitoring) │
│ • Shared network namespace (localhost communication) │
│ │
└─────────────────────────────────────────────────────────────────────────────┘
