/*
 *  Copyright 2012, 2013 Ruediger Gad
 *
 *  This file is part of Q To-Do.
 *
 *  Q To-Do is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  Q To-Do is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with Q To-Do.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.0

Item {
    id: menu

    /*
     * The following is a quite ugly hack to animate the menu.
     * This should be done via States rather than this hack.
     * Though, due to the limited time, for now this hack is used.
     */
    property bool isOpen: true

    signal closed
    signal opened

    function close() {
        menuBorder.y = height
        closed()
    }

    function open() {
        enabled = true
        menuBorder.y = height - menuBorder.height
        opened()
    }

    anchors.fill: parent
    enabled: false
    visible: enabled
    z: 16

    Rectangle {
        id: background

        anchors.fill: parent
        color: "black"
        opacity: menu.isOpen ? 0.3 : 0
    }

    MouseArea {
        anchors.fill: parent

        onClicked: {
            close();
        }
    }

    Rectangle {
        id: menuBorder

        color: "lightgray"
        opacity: 0.9
        height: menuArea.height
        width: parent.width
        y: parent.height
        z: parent.z + 1

        Behavior on y {
            SequentialAnimation {
                PropertyAnimation { duration: 120 }
                ScriptAction {
                    script: {
                        if (menu.isOpen) {
                            menu.enabled = false
                        }
                        menu.isOpen = ! menu.isOpen
                    }
                }
            }
        }

        Item {
            id: menuArea

            anchors.centerIn: parent
            height: about.height * 7 + primaryFontSize / 3 * 8
            width: parent.width
            y: parent.y

            CommonButton {
                id: changePassword

                anchors.bottom: syncToImap.top
                anchors.bottomMargin: primaryFontSize / 3
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Change Password"
                width: parent.width - primaryFontSize

                onClicked: {
                    passwordChangeDialog.open()
                    menu.close()
                }
            }

            CommonButton {
                id: syncToImap

                anchors.bottom: syncDeleteMessage.top
                anchors.bottomMargin: primaryFontSize / 3
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Sync"
                width: parent.width - primaryFontSize

                onClicked: {
                    confirmSyncToImapDialog.open()
                    menu.close()
                }
            }

            CommonButton {
                id: syncDeleteMessage

                anchors.bottom: syncAccountSettings.top
                anchors.bottomMargin: primaryFontSize / 3
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Clear Sync Data"
                width: parent.width - primaryFontSize

                onClicked: {
                    confirmDeleteSyncMessage.open()
                    menu.close()
                }
            }

            CommonButton {
                id: syncAccountSettings

                anchors.bottom: exportKeePassXml.top
                anchors.bottomMargin: primaryFontSize / 3
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Sync Account Settings"
                width: parent.width - primaryFontSize

                onClicked: {
                    imapAccountSettings.open()
                    menu.close()
                }
            }

            CommonButton {
                id: exportKeePassXml

                anchors.bottom: importKeePassXml.top
                anchors.bottomMargin: primaryFontSize / 3
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Export"
                width: parent.width - primaryFontSize

                onClicked: {
                    entryStorage.exportKeePassXml()
                    menu.close()
                }
            }

            CommonButton {
                id: importKeePassXml

                anchors.bottom: about.top
                anchors.bottomMargin: primaryFontSize / 3
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Import"
                width: parent.width - primaryFontSize

                onClicked: {
                    entryStorage.importKeePassXml()
                    menu.close()
                }
            }

            CommonButton {
                id: about

                anchors.bottom: parent.bottom
                anchors.bottomMargin: primaryFontSize / 3
                anchors.horizontalCenter: parent.horizontalCenter
                text: "About"
                width: parent.width - primaryFontSize

                onClicked: {
                    aboutDialog.open()
                    menu.close()
                }
            }
        }
    }
}