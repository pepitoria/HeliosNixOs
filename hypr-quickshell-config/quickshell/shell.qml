// Base Quickshell bar -- copy to ~/.config/quickshell/shell.qml
// (Quickshell's default search path; launched by `exec-once = qs` in
// hyprland.conf.)
//
// Omarchy 4.x's actual Quickshell shell is a 300+ file QML application
// (workspace overview, notification center, agent panels, a plugin system)
// that only makes sense bundled with the rest of the Omarchy package. This
// is a small, real, working bar in the same visual language (dark
// background, cyan/green accent -- matching hyprland.conf's border colors)
// built from Quickshell's own documented API, meant as a starting point to
// build your own widgets on top of. See https://quickshell.org/docs for the
// full type reference -- PanelWindow, Variants, Hyprland and Io are the
// pieces used below.
//
// Quickshell live-reloads this file on save while it's running.
//
// Required for tray item right-click/menu-fallback popups (QsMenuAnchor) --
// without it, Quickshell runs in a lighter QGuiApplication mode that can't
// render platform menus at all and errors with "Cannot call
// QsMenuAnchor.open() as quickshell was not started in QApplication mode."
//@ pragma UseQApplication

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import QtQuick
import QtQuick.Layouts

ShellRoot {
  Variants {
    model: Quickshell.screens

    delegate: Component {
      PanelWindow {
        property var modelData
        screen: modelData

        anchors {
          top: true
          left: true
          right: true
        }

        implicitHeight: 34
        color: "#141414"

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: 10
          anchors.rightMargin: 10

          // ---- Left: workspaces ------------------------------------
          RowLayout {
            spacing: 4

            Repeater {
              model: 10

              Rectangle {
                width: 26
                height: 24
                radius: 4
                color: (Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === index + 1)
                  ? "#33ccff"
                  : "transparent"

                Text {
                  anchors.centerIn: parent
                  text: (index + 1) % 10
                  color: (Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === index + 1)
                    ? "#141414"
                    : "#cccccc"
                  font.family: "monospace"
                  font.pointSize: 10
                }

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: Hyprland.dispatch("workspace " + (index + 1))
                }
              }
            }
          }

          Item { Layout.fillWidth: true }

          // ---- Center: clock ----------------------------------------
          Text {
            id: clock
            color: "#ffffff"
            font.family: "monospace"
            font.pointSize: 11

            Process {
              id: dateProc
              command: ["date", "+%a %d %b  %H:%M:%S"]
              running: true
              stdout: SplitParser {
                onRead: data => clock.text = data
              }
            }

            Timer {
              interval: 1000
              running: true
              repeat: true
              onTriggered: dateProc.running = true
            }
          }

          Item { Layout.fillWidth: true }

          // ---- Right: tray + volume + lock -----------------------------
          RowLayout {
            spacing: 12

            // System tray (StatusNotifierItem protocol) -- this is what
            // blueman-applet and nm-applet render their icons into. Without
            // this widget, those applets run but have nowhere to show up.
            RowLayout {
              spacing: 6

              Repeater {
                model: SystemTray.items

                Rectangle {
                  id: trayIcon
                  Layout.preferredWidth: 20
                  Layout.preferredHeight: 20
                  radius: 4
                  color: "transparent"

                  Image {
                    anchors.centerIn: parent
                    width: 16
                    height: 16
                    // WORKAROUND, not a real fix: Quickshell 0.2.0's own
                    // "image://icon/<name>" resolver fails to load some
                    // valid, correctly-installed icons (confirmed against
                    // this system -- the files, the icon-theme.cache, and
                    // XDG_DATA_DIRS are all fine; this is an upstream bug,
                    // see https://github.com/quickshell-mirror/quickshell/issues/26
                    // and https://discourse.nixos.org/t/quickshell-cant-find-icons/65859,
                    // both unresolved). Known-broken names get pointed
                    // straight at their real file on disk instead. Add
                    // entries here if a future tray app shows a blank icon
                    // -- check `qs -p ~/.config/quickshell/shell.qml` output
                    // for "Could not load icon "<name>"" to get the name,
                    // then find its file under
                    // /run/current-system/sw/share/icons/hicolor/.
                    property var brokenIconFallbacks: ({
                      "blueman-tray": "file:///run/current-system/sw/share/icons/hicolor/scalable/status/blueman-tray.svg",
                      "nm-device-wired": "file:///run/current-system/sw/share/icons/hicolor/scalable/apps/nm-device-wired.svg"
                    })
                    source: {
                      const raw = modelData.icon ?? "";
                      const name = raw.replace("image://icon/", "");
                      return brokenIconFallbacks[name] ?? raw;
                    }
                    visible: status === Image.Ready
                  }

                  // Right-click menus (SystemTrayItem.menu) are opened via
                  // QsMenuAnchor, not by calling a method on the menu
                  // itself -- verified against this Quickshell version's
                  // actual qmltypes, not just examples found online.
                  QsMenuAnchor {
                    id: trayMenu
                    menu: modelData.menu
                    anchor.item: trayIcon
                  }

                  MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: mouse => {
                      // A menu takes priority on either click -- most tray
                      // apps (nm-applet included) don't implement a
                      // meaningful "activate" at all and rely entirely on
                      // their menu (e.g. nm-applet's "Edit Connections..."
                      // launches nm-connection-editor from there).
                      if (modelData.hasMenu) {
                        trayMenu.open();
                      } else {
                        modelData.activate();
                      }
                    }
                  }
                }
              }
            }

            Text {
              id: volume
              color: "#00ff99"
              font.family: "monospace"
              font.pointSize: 10

              Process {
                id: volProc
                command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
                running: true
                stdout: SplitParser {
                  onRead: data => volume.text = "vol " + data.replace("Volume: ", "").trim()
                }
              }

              Timer {
                interval: 5000
                running: true
                repeat: true
                onTriggered: volProc.running = true
              }
            }

            Text {
              text: "⏻"
              color: "#cccccc"
              font.pointSize: 12

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: lockProc.running = true
              }

              Process {
                id: lockProc
                command: ["hyprlock"]
              }
            }
          }
        }
      }
    }
  }
}

// Ideas to extend this file:
// - Notifications: Quickshell.Services.Notifications.
// - Active window title: Hyprland.activeToplevel.
// - Per-monitor layout tweaks: branch on modelData.name inside the
//   Variants delegate above.
