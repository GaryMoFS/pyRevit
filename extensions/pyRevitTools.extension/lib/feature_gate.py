"""Small runtime guards for commands that need newer Revit APIs."""

from pyrevit import HOST_APP, forms


def require_revit_version(minimum_version, command_name):
    """Show a clear notice and stop before an unsupported API is accessed."""
    if HOST_APP.is_older_than(minimum_version):
        forms.alert(
            "{} requires Revit {} or newer. It has not been updated for Revit {} "
            "yet, so no model changes were made.".format(
                command_name, minimum_version, HOST_APP.version
            ),
            title="{} unavailable in Revit {}".format(
                command_name, HOST_APP.version
            ),
            exitscript=True,
        )
