import Quickshell
import Quickshell.Io
import QtQuick

// Sends the bar geometry to the glass process (glass/shell.qml) whenever it changes,
// reconnecting while the glass process is (re)starting.
Scope {
    id: root
    // Protocol: see glass/shell.qml.
    property string message

    onMessageChanged: send()

    function send() {
        if (!socket.connected || !message) return
        socket.write(message + "\n")
        socket.flush()
    }

    Socket {
        id: socket
        path: Quickshell.env("XDG_RUNTIME_DIR") + "/mac-dock-glass.sock"
        connected: true
        onConnectedChanged: if (connected) root.send()
    }

    Timer {
        interval: 1000
        repeat: true
        running: !socket.connected
        onTriggered: socket.connected = true
    }
}
