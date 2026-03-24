
### Workflow: Version bump → Test → Release → Publish

| Step | Task | npm Script | What it does |
|---|---|---|---|
| **1a** | Package patch & local install | `package` | Version bump (patch) + VSIX + install locally |
| **1b** | Package minor & local install | `package-minor` | Version bump (minor) + VSIX + install locally |
| **1c** | Package major & local install | `package-major` | Version bump (major) + VSIX + install locally |
| **1d** | 🔄 Package (no new version) & local install | `package-no-new-version` | Build VSIX only + install locally |
| **Test** | Test | `test` | Run lint + tests |
| **2** | 🚀 Release to GitHub | `release` | Create GitHub release (_**no version bump**_) |
| **3** | 📦 Publish to Marketplace | `publish` | Publish to VS Code Marketplace |
| **2+3** | 🚀📦 Release & Publish | `release-and-publish` | GitHub release + Marketplace in one step |

**Typical flow:** `package` → test manually → `release-and-publish`
