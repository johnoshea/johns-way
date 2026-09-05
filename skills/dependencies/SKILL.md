---
name: dependencies
description: Adding or updating dependencies and editing CI. The 14-day cooldown, choosing versions, the Python version policy, and GitHub Actions. Consult before uv add, any lockfile update, or any change under .github/workflows.
---

# Dependencies

A dependency version is adopted only when it is at least 14 days old. This covers Python packages, GitHub Actions, and Docker images. The commit check enforces it for packages and Actions. It is never worked around: bypassing it exposes the project to supply-chain attacks.

## Choosing a version

Take the newest version that clears the cooldown. Look the release date up; never answer from memory.

    johns-way-release-date pypi <name> <version>
    johns-way-release-date action <owner/repo> <ref>

If the command is not on PATH, use `../../bin/johns-way-release-date` relative to this skill's directory.

The first prints a package version's release time; PyPI's release history page lists the candidates. The second prints the date of the commit an Action's ref points at, which is what counts, because moving tags such as `v5` are re-pointed.

## Python

Use the latest stable Python release that clears the cooldown. Do not stay on an older one because it is installed. CI runs the same Python version as `pyproject.toml`; change both in the same commit.

## GitHub Actions

When touching a workflow, update every Action in it to its newest version that clears the cooldown. Look each version up.

## Tooling

`uv add`, `uv lock`, `uv sync`, and `uv tree`. Never pip. Never a direct venv binary.

Fix lint failures the tool reports. Never ignore a rule or exclude a file to make it pass.
