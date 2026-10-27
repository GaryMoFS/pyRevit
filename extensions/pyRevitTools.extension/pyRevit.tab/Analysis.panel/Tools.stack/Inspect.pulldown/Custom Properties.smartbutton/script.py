# -*- coding: utf-8 -*-
"""Toggle the Custom Properties dockable pane."""

from pyrevit import HOST_APP, forms, script
from pyrevit.revit import ui
from pyrevit.framework import Threading, System
import pyrevit.extensions as exts
from pyrevit.coreutils.ribbon import ICON_MEDIUM
from feature_gate import require_revit_version


def __selfinit__(script_cmp, ui_button_cmp, __rvt__):
    if HOST_APP.is_older_than(2022):
        return True

    from panes.customprops.pane import CustomPropertiesPanel
    panel_id = CustomPropertiesPanel.panel_id

    def set_icon(is_shown):
        if is_shown:
            icon = ui.resolve_icon_file(script_cmp.directory, exts.DEFAULT_ON_ICON_FILE)
        else:
            icon = ui.resolve_icon_file(
                script_cmp.directory, exts.DEFAULT_OFF_ICON_FILE
            )
        ui_button_cmp.set_icon(icon, icon_size=ICON_MEDIUM)

    def update_icon_from_pane():
        try:
            dockable = forms.get_dockable_panel(panel_id)
            set_icon(dockable.IsShown())
        except Exception:
            set_icon(False)

    def on_visibility_changed(sender, args):
        def deferred():
            update_icon_from_pane()

        Threading.Dispatcher.CurrentDispatcher.BeginInvoke(
            Threading.DispatcherPriority.Background, System.Action(deferred)
        )

    def on_document_opened(sender, args):
        __rvt__.Application.DocumentOpened -= on_document_opened
        update_icon_from_pane()
        __rvt__.DockableFrameVisibilityChanged += on_visibility_changed

    set_icon(False)

    try:
        if __rvt__.ActiveUIDocument is not None:
            update_icon_from_pane()
            __rvt__.DockableFrameVisibilityChanged += on_visibility_changed
        else:
            __rvt__.Application.DocumentOpened += on_document_opened
    except Exception:
        __rvt__.Application.DocumentOpened += on_document_opened

    return True


if __name__ == "__main__":
    require_revit_version(2022, "Custom Properties")
    from panes.customprops.pane import CustomPropertiesPanel, CONFIG_SECTION

    my_config = script.get_config(CONFIG_SECTION)
    if not my_config.get_option("enabled", False):
        forms.alert(
            "Tool disabled in config.",
            title="Custom Properties",
            exitscript=True,
        )
    dockable = forms.get_dockable_panel(CustomPropertiesPanel.panel_id)
    forms.toggle_dockable_panel(
        CustomPropertiesPanel.panel_id, not dockable.IsShown()
    )
