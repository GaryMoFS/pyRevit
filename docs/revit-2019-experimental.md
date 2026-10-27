# Experimental Revit 2019 compatibility

This branch is an experimental adaptation of pyRevit 7.0.0.26278 for Revit 2019. It is not supported by upstream. The runtime, loader, and assembly builder were compiled against a locally installed Revit 2019 API. In one Revit 2019.2 session, the ribbon loaded, the agent returned model context, an IronPython query read levels, and a dry run rolled back a test level. This is not a comprehensive compatibility test. CPython, individual commands, and the model-change approval workflow require further testing.

The runtime project uses the installed Revit 2019 API assemblies under `C:\Program Files\Autodesk\Revit 2019` by default. Override the `Revit2019Path` MSBuild property if Revit is installed elsewhere. Autodesk assemblies and compiled binaries are not included in this branch.

This branch is a source snapshot, not a complete installer or automated build. A working local experiment additionally used matching pyRevit 7 release binaries, a rebuilt loader and assembly builder, Revit 2019 entries in the deployed host lists, and an older pyRevit CLI to create the add-in manifest: the unmodified v7 CLI rejects Revit 2019. Those deployment steps are not yet automated or validated for another machine. The Revit 2019 build omits the unavailable `IsSavingAsCentralFile` telemetry field.

The agent policy is a user configuration and is not part of this branch. `ask` requires a decision inside Revit for each modify run; `readonly` permits queries and dry runs. Keep backups and test with disposable models before relying on this unsupported build.
