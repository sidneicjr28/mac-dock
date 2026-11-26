import Quickshell
import Quickshell.Io
import QtQuick

// A long-lived helper process that is restarted whenever it exits.
Scope {
    id: root
    required property string name
    required property var command
    property alias stdout: proc.stdout
    property alias stdinEnabled: proc.stdinEnabled
    property int restartDelay: 2000
    readonly property alias running: proc.running

    signal stderrLine(string line)

    function write(data) {
        if (proc.running) proc.write(data)
        else console.warn(`${name}: not running, dropped write`)
    }

    Process {
        id: proc
        command: root.command
        running: true
        stderr: SplitParser { onRead: line => root.stderrLine(line) }
        onExited: code => {
            console.warn(`${root.name} exited with code ${code}; restarting in ${root.restartDelay} ms`)
            restart.start()
        }
    }

    Timer { id: restart; interval: root.restartDelay; onTriggered: proc.running = true }
}
