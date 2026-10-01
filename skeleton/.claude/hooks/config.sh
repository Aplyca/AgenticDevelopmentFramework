# Project settings for the Claude Code hooks in this directory.
# The hook scripts source this file. Edit the values here — the scripts themselves are
# framework-owned and get replaced on upgrade; this file is yours.
# Patterns are shell globs. A pattern without "/" matches a file name at any depth;
# a pattern with "/" matches the path relative to the repository root.

# CUSTOMIZE: branches that never take direct commits or pushes from an agent.
# Add your integration and release branches (e.g. "main staging develop"). Empty disables the check.
PROTECTED_BRANCHES="main master"

# CUSTOMIZE: append-only history — existing files here must never be modified; adding new
# files is fine. E.g. "db/migrations/* db/migrate/* prisma/migrations/*/migration.sql"
APPEND_ONLY_GLOBS=""

# Generated files that must never be hand-edited — regenerate them with their tool.
# Add generated types or clients, e.g. "src/types/database.generated.ts".
GENERATED_GLOBS="package-lock.json npm-shrinkwrap.json pnpm-lock.yaml yarn.lock bun.lock bun.lockb poetry.lock uv.lock Pipfile.lock Gemfile.lock composer.lock Cargo.lock go.sum"

# CUSTOMIZE: sensitive areas — paths where any change takes at least the careful lane, whatever its
# size (mirror AGENTS.md § Sensitive areas). The first edit in each area stops once per session so
# the agent confirms the lane. E.g. "src/billing/* src/auth/* supabase/migrations/*". Empty disables.
CAREFUL_GLOBS=""

# The triage — the lane and why — comes before the first file change. "1" stops the first edit of a
# session once, as a reminder, when its reply text states no lane yet. Empty disables.
TRIAGE_FIRST="1"

# The env template that declares (names only, no values) every environment variable the code
# reads. Empty = auto-detect .env.example, .env.sample, .env.template or .env.dist at the root.
ENV_TEMPLATE=""

# Variables the runtime or platform provides — never expected in the env template.
ENV_IGNORE="NODE_ENV CI HOME PATH PWD USER SHELL TERM TZ LANG"

# Files never checked for undeclared environment variables.
ENV_CHECK_EXCLUDE="*.test.* *.spec.* *_test.* test_*.py tests/* */tests/* */__tests__/* docs/* *.md"

# Where spec folders live (used for session context).
SPECS_DIR="specs"
