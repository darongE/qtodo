/*
 *  Copyright 2011 Ruediger Gad
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
 *
 *  ###################
 *
 *  Note: The code of the TreeView is additionally released under the terms
 *  of the GNU Lesser General Public License (LGPL) as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *  Files considered part of the TreeView are: TreeView.qml, NodeListView.qml,
 *  and nodelisthelper.js. These files are additionally licensed under the
 *  terms of the LGPL.
 *
 */

import QtQuick 1.1

Item {
    id: nodeListItem

    property alias model: nodeListView.model
    property alias currentIndex: nodeListView.currentIndex
    property alias currentItem: nodeListView.currentItem
    property int level;
    property bool movingItem: false
    property int tempContentY
    property int tempIndex;

    signal countChanged(int count)
    signal expandTree()
    signal leafNodeSelected()

    function getColor(colorString) {
        if(colorString === "blue")
            return "#2c81c8"
        if(colorString === "green")
            return "#18FF00"
        if(colorString === "yellow")
            return "#FFD600"
        if(colorString === "red")
            return "#FF2300"

        return "#00ff00"
    }

    Connections {
        target: model

        onChanged: {
            if (! movingItem) {
                storage.save()
                currentIndex = -1
                currentIndex = tempIndex
                nodeListView.contentY = tempContentY
            }
        }

        onModelAboutToBeReset: {
            tempContentY = nodeListView.contentY
            tempIndex = currentIndex
        }
    }

    function updateLabels() {
        var listEmpty = (nodeListView.model.rowCount() <= 0)
        emptyListRectangle.visible = listEmpty
    }

    onExpandTree: {
        treeView.addView(nodeListItem)
        treeView.updateSubView(model, currentIndex)
    }

    onLeafNodeSelected: {
        treeView.clearSubLists()
    }

    Rectangle {
        id: emptyListRectangle
        anchors.fill: parent
        color: treeView.color

        Text {
            id: noContentLabel
            text: "No entries yet"
            font.pixelSize: 60; anchors.bottom: explanationLabel.top; anchors.bottomMargin: 50; anchors.horizontalCenter: parent.horizontalCenter
            color: "gray"
        }

        Text {
            id: explanationLabel
            text: "Use + to add entries."
            font.pixelSize: 40
            color: "gray"
            anchors.centerIn: parent
        }
    }

    PinchArea {
        id: dndArea
        anchors.fill: parent

        property real lastPosition: 0
        property real moveDelta: 40

        onPinchStarted: {
            movingItem = true
            lastPosition = pinch.startPoint2.y
        }

        onPinchUpdated: {
            var currentPosition = pinch.point2.y

            if(currentPosition === pinch.point1.y)
                return

            if(lastPosition - currentPosition > moveDelta){
                lastPosition = currentPosition
                moveItem(nodeListView.currentIndex - 1)
            }else if (lastPosition - currentPosition < -moveDelta){
                lastPosition = currentPosition
                moveItem(nodeListView.currentIndex + 1)
            }
        }

        onPinchFinished: {
            movingItem = false
            storage.save()
        }

        function moveItem(targetIndex) {
            if(targetIndex >= 0 && targetIndex < nodeListView.count){
                nodeListView.model.move(nodeListView.currentIndex, targetIndex, 1)
                nodeListView.currentIndex = targetIndex
            }
        }
    }

    FlowListView {
        id: nodeListView
        anchors.fill: parent

        onCountChanged: {
            nodeListItem.countChanged(count)
            updateLabels()
        }

        onCurrentItemChanged: {
            if(treeView.currentLevel !== level) {
                return
            }

            /*
             * Only update the TreeView current item and index if there had actually a
             * valid item been selected. An index of -1 is used to clear the selection
             * of the ListView from the TreeView. Hence, we do not want this change
             * to propagate back to the TreeView.
             */
            if(currentIndex >= 0) {
                treeView.currentItem = currentItem
                treeView.currentIndex = currentIndex
                updateLabels()
            }
        }

        delegate: Item {
            id: delegateItem
            height: nodeListDelegate.height
            width: nodeListDelegate.width
            
            /*
             * These properties are used to access the item properties/data of
             * the current item as returned via the ListView currentItem property.
             * Customize this as needed for your purpose.
             */
            property string text: elementText
            property string type: tagName
            property string itemColor: elementColor
            property bool done: isDone
            property double progress: elementProgress

            property double displayedProgress: getProgress()

            function selectItem() {
                currentIndex = index
                if(isExpandable){
                    expandTree()
                }else{
                    leafNodeSelected()
                }
            }

            function getProgress() {
                if (done)
                    return 1
//                if(progress >= 0)
//                    return progress

                var idx = treeView.currentLevel === 0 ? index : index + 1
                var nTodos = treeView.currentModel.countSubTodos(idx, false, true)
                var notDone = treeView.currentModel.countSubTodos(idx, true, true)

                if (nTodos <= 0)
                    return 0

                return (1 - (notDone / nTodos))
            }

            NodeListDelegate {
                id: nodeListDelegate
            }
        }
    }
}
