# The committed install

`/adf:adopt` reads this at Step 3 when the team chose the committed install.

Write the machinery from the plugins, its source (decision 0028):

```bash
python3 <framework-root>/scripts/build-committed.py <repo> --modules <the chosen modules, comma-separated>
```

It writes the skills, agents, workflows, hook scripts, and reference docs, with the chosen modules'
skills. It never overwrites a file, and lists the ones it kept: merge each, or keep the project's
under a name of its own.
