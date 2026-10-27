from feature_gate import require_revit_version

require_revit_version(2022, "Export Parameters to Excel")

from xlsex_script import main

if __name__ == "__main__":
    main(advanced=True)
