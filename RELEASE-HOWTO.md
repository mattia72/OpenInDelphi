
### Workflow: Develop → Test → Version bump →  Release + Publish

| Step | Task | npm Script | What it does |
|---|---|---|---|
| **0** | change code | | Add new features |
| **1** | 🔄 Package (no new version) & local install | `package-no-new-version` | Build VSIX only + install locally |
| **Test** | Test | `test` | Run lint + tests |
|||||
| **2a** | Package patch & local install | `package` | Version bump (patch) + VSIX + install locally |
| **2b** | Package minor & local install | `package-minor` | Version bump (minor) + VSIX + install locally |
| **2c** | Package major & local install | `package-major` | Version bump (major) + VSIX + install locally |
|||||
| **3** | 🚀 Release to GitHub | `release` | Create GitHub release (_**no version bump**_) |
| **4** | 📦 Publish to Marketplace | `publish` | Publish to VS Code Marketplace |
| **3+4** | 🚀📦 Release & Publish | `release-and-publish` | GitHub release + Marketplace in one step |

**Typical flow:** → uninstall open-in-delphi → `package` → ctrl+shift+p Install from VSX: open-in-delphi → test manually → `release-and-publish`

### Prerequisites

- **Marketplace token:** The `publish` and `release-and-publish` scripts require the `VSCE_PAT` environment variable to be set with a valid Personal Access Token from [dev.azure.com](https://dev.azure.com) (Scopes: Marketplace → Manage).
- **GitHub token:** The `release` script reads the GitHub token from `$env:GITHUB_TOKEN`.
