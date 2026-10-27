# Experimental Revit 2019 compatibility

This branch adapts pyRevit 7.0.0.26278 for Revit 2019. It is not supported by upstream. In one Revit 2019.2 session the ribbon loaded, the agent returned model context, an IronPython query read levels, a dry run rolled back a test change, and a user-approved building operation committed. This is not a comprehensive compatibility test. CPython, individual ribbon commands, other Revit versions, and a clean live install need further testing.

## Rebuild

Use a clean checkout with Windows long paths enabled for Git, the .NET 10 SDK, a locally installed Revit 2019 and the `bin` folder from the matching official pyRevit 7.0.0.26278 distribution. Run `build/build-revit2019.ps1 -SeedBin <path-to-bin>`. Override `-Revit2019Path` when Revit is installed in a non-default location. The script refuses to overwrite an existing `bin` directory. It rebuilds the 2019 loaders and both IronPython runtimes and publishes a self-contained CLI. Autodesk assemblies are not included in this repository.

The 2019-specific package is built from `release/pyrevit-revit2019-experimental.iss` using Inno Setup 7. It registers the packaged clone and replaces only the current user's Revit 2019 pyRevit manifest, saving the previous manifest in the installation folder. When uninstalled, it restores the saved manifest only if the current manifest still points to this installation. It does not configure a Codex MCP client automatically. These installer behaviours have been tested in a simulated user profile; a clean Revit startup from the installed location is still pending.

The agent policy is user configuration, not part of the source branch. `ask` requires an in-Revit decision for each modify run; `readonly` permits queries and dry runs. This build omits the `IsSavingAsCentralFile` telemetry field unavailable in Revit 2019. Do not rely on it for production without further verification.

The eight pyRevit Tools commands marked for Revit 2022 and `Show View Range` (2023) are visible in this experimental build, but stop with a version notice in Revit 2019 before using newer API calls. Their functionality has not been backported. The separate Developer Tools `Temporary Graphics` sample remains gated to Revit 2022.
