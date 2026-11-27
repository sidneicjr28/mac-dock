import Quickshell
import QtQuick

// Runs glass/shell.qml under a renamed copy of quickshell. KWin derives the window class from
// the executable name, so the blur window ("mac-dock-glass") can be treated apart from the dock.
// `install -C` only rewrites the copy when quickshell itself is updated.
// Basic render loop: the window draws nothing, so a separate render thread only costs memory.
// (The software backend would save more, but KWin then stops blurring the window.)
SupervisedProcess {
    name: "glass"
    command: ["sh", "-c",
        'bin="$XDG_RUNTIME_DIR/mac-dock-glass"; install -C /usr/bin/quickshell "$bin" && ' +
        'rm -f "$XDG_RUNTIME_DIR/mac-dock-glass.sock" && QSG_RENDER_LOOP=basic exec "$bin" -p "$1"',
        "sh", Quickshell.shellPath("glass")]
    onStderrLine: line => { if (/ERROR|WARN/.test(line)) console.warn("glass:", line) }
}
