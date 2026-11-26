#!/usr/bin/env python3
"""Bridge KWin's org_kde_plasma_window_management protocol to the dock.

KWin does not implement wlr-foreign-toplevel-management, so Quickshell's ToplevelManager is
empty there. This helper speaks Plasma's protocol instead:

  stdout: a JSON array of windows after every change
          [{"uuid", "appId", "title", "pid", "active", "minimized"}, ...]
  stdin:  one command per line: "activate <uuid>" | "minimize <uuid>" | "close <uuid>"
"""
import json
import os
import selectors
import signal
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pywayland.client import Display  # noqa: E402
from pwm_proto import OrgKdePlasmaWindowManagement  # noqa: E402

ACTIVE, MINIMIZED, SKIP_TASKBAR = 0x1, 0x2, 0x1000
MAX_PROTOCOL_VERSION = 16


class Window:
    def __init__(self, uuid, proxy, on_change):
        self.uuid, self.proxy = uuid, proxy
        self.app_id = self.title = ""
        self.state = self.pid = 0
        self.ready = False
        self._on_change = on_change

    def set(self, attr, value):
        setattr(self, attr, value)
        self._on_change()

    @property
    def listed(self):
        return self.ready and not self.state & SKIP_TASKBAR

    def to_json(self):
        return {"uuid": self.uuid, "appId": self.app_id, "title": self.title, "pid": self.pid,
                "active": bool(self.state & ACTIVE), "minimized": bool(self.state & MINIMIZED)}


class WindowBridge:
    def __init__(self):
        self.display = Display()
        self.display.connect()
        self.windows = {}
        self.dirty = False
        self.manager = None
        self._bind_manager()

    def _bind_manager(self):
        found = {}

        def on_global(registry, name, interface, version):
            if interface == "org_kde_plasma_window_management":
                found["manager"] = registry.bind(name, OrgKdePlasmaWindowManagement,
                                                 min(version, MAX_PROTOCOL_VERSION))

        registry = self.display.get_registry()
        registry.dispatcher["global"] = on_global
        self.display.roundtrip()
        if "manager" not in found:
            sys.exit("windows.py: compositor does not offer org_kde_plasma_window_management")
        # Assign before the roundtrip: it delivers the existing windows, which use self.manager.
        self.manager = found["manager"]
        self.manager.dispatcher["window_with_uuid"] = lambda _m, _id, uuid: self._track(uuid)
        self.display.roundtrip()

    def _mark_dirty(self):
        self.dirty = True

    def _track(self, uuid):
        proxy = self.manager.get_window_by_uuid(uuid)
        window = Window(uuid, proxy, self._mark_dirty)
        self.windows[uuid] = window
        for event, attr in (("app_id_changed", "app_id"), ("title_changed", "title"),
                            ("state_changed", "state"), ("pid_changed", "pid")):
            proxy.dispatcher[event] = lambda _p, value, attr=attr: window.set(attr, value)
        proxy.dispatcher["initial_state"] = lambda _p: window.set("ready", True)
        proxy.dispatcher["unmapped"] = lambda _p: self._forget(uuid)

    def _forget(self, uuid):
        window = self.windows.pop(uuid, None)
        self._mark_dirty()
        if window is None:
            return
        try:
            window.proxy.destroy()
        except Exception as error:
            print(f"windows.py: destroying {uuid} failed: {error}", file=sys.stderr)

    def publish(self):
        self.dirty = False
        listed = [w.to_json() for w in self.windows.values() if w.listed]
        sys.stdout.write(json.dumps(listed) + "\n")
        sys.stdout.flush()

    def handle_command(self, line):
        parts = line.split()
        if len(parts) != 2 or parts[1] not in self.windows:
            print(f"windows.py: ignoring command {line!r}", file=sys.stderr)
            return
        action, proxy = parts[0], self.windows[parts[1]].proxy
        if action == "activate":
            proxy.set_state(ACTIVE | MINIMIZED, ACTIVE)
        elif action == "minimize":
            proxy.set_state(MINIMIZED, MINIMIZED)
        elif action == "close":
            proxy.close()
        else:
            print(f"windows.py: unknown action {action!r}", file=sys.stderr)

    def run(self):
        selector = selectors.DefaultSelector()
        selector.register(self.display.get_fd(), selectors.EVENT_READ, "wayland")
        selector.register(sys.stdin, selectors.EVENT_READ, "stdin")
        self.publish()
        while True:
            self.display.dispatch(block=False)
            self.display.flush()
            if self.dirty:
                self.publish()
            for key, _ in selector.select():
                if key.data == "wayland":
                    self.display.dispatch(block=True)
                    continue
                line = sys.stdin.readline()
                if not line:
                    exit_now()
                if line.strip():
                    self.handle_command(line.strip())


def exit_now(*_):
    # libwayland segfaults tearing down live proxies at interpreter exit; skip teardown.
    os._exit(0)


if __name__ == "__main__":
    signal.signal(signal.SIGTERM, exit_now)
    WindowBridge().run()
