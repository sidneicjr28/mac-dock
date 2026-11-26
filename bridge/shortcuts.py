#!/usr/bin/env python3
"""Register Meta+1..9 with KDE's KGlobalAccel and report presses to the dock.

  stdout: the slot number (1-9) on every press

Plasma's task manager claims Meta+1..9 by default; those bindings are released so ours can
take the keys. Shortcuts can be changed later under System Settings > Shortcuts > Mac Dock.
"""
import sys

import dbus
from dbus.mainloop.glib import DBusGMainLoop
from gi.repository import GLib

COMPONENT, COMPONENT_NAME = "mac-dock", "Mac Dock"
META, KEY_1 = 0x10000000, 0x31
IS_DEFAULT, SET_PRESENT = 0x1, 0x2


def keys(*codes):
    """KGlobalAccel's a(ai): a list of key sequences, each a list of key codes."""
    return dbus.Array([dbus.Struct([dbus.Array([c], signature="i")], signature="ai") for c in codes],
                      signature="(ai)")


def action_id(n):
    return [COMPONENT, f"activate-{n}", COMPONENT_NAME, f"Activate dock app {n}"]


def release_task_manager_key(accel, n, key):
    plasma = ["plasmashell", f"activate task manager entry {n}", "", ""]
    if any(seq[0] and seq[0][0] == key for seq in accel.shortcutKeys(plasma)):
        accel.setForeignShortcutKeys(plasma, keys())
        print(f"shortcuts.py: released Meta+{n} from Plasma's task manager", file=sys.stderr)


def main():
    DBusGMainLoop(set_as_default=True)
    bus = dbus.SessionBus()
    accel = dbus.Interface(bus.get_object("org.kde.kglobalaccel", "/kglobalaccel"), "org.kde.KGlobalAccel")

    for n in range(1, 10):
        key = META | (KEY_1 + n - 1)
        release_task_manager_key(accel, n, key)
        aid = action_id(n)
        accel.doRegister(aid)
        accel.setShortcutKeys(aid, keys(key), dbus.UInt32(IS_DEFAULT))
        # SetPresent marks the action live; without NoAutoloading a saved user binding wins
        got = accel.setShortcutKeys(aid, keys(key), dbus.UInt32(SET_PRESENT))
        if not got:
            print(f"shortcuts.py: Meta+{n} is taken by another shortcut", file=sys.stderr)

    path = accel.getComponent(COMPONENT)

    def pressed(component, action, _timestamp):
        if component == COMPONENT and action.startswith("activate-"):
            print(action.removeprefix("activate-"), flush=True)

    bus.add_signal_receiver(pressed, "globalShortcutPressed", "org.kde.kglobalaccel.Component",
                            "org.kde.kglobalaccel", path)
    GLib.MainLoop().run()


if __name__ == "__main__":
    main()
