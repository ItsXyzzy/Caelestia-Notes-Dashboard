import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.utils

Item {
    id: root

    implicitWidth: 840
    implicitHeight: 560

    property var notes: []
    property int selectedIndex: -1
    readonly property var selectedNote: root.selectedIndex >= 0 && root.selectedIndex < root.notes.length ? root.notes[root.selectedIndex] : null

    property bool previewMode: false

    // Single newlines become paragraph breaks so quick notes still render, but lists,
    // headings and code blocks keep their own line breaks.
    function previewMarkdown(body: string): string {
        const listy = l => /^\s*([-*+]|\d+[.)])\s/.test(l) || /^\s*>/.test(l);
        const lines = body.split("\n");
        let fence = false;
        let out = "";
        for (let i = 0; i < lines.length; i++) {
            const a = lines[i];
            if (/^\s*```/.test(a))
                fence = !fence;
            out += a;
            if (i === lines.length - 1)
                break;
            const b = lines[i + 1];
            const tight = fence || /^\s*```/.test(a) || a.trim() === "" || b.trim() === "" || (listy(a) && listy(b)) || /^#{1,6}\s/.test(a);
            out += tight ? "\n" : "\n\n";
        }
        return out;
    }

    function newNote(): void {
        const note = {
            id: Date.now(),
            title: Tr.tr("Untitled"),
            body: "",
            updated: Date.now()
        };
        root.notes = [note, ...root.notes];
        root.selectedIndex = 0;
        saveTimer.restart();
    }

    function deleteNote(index: int): void {
        if (index < 0 || index >= root.notes.length)
            return;
        const arr = root.notes.slice();
        arr.splice(index, 1);
        root.notes = arr;
        root.selectedIndex = arr.length > 0 ? Math.min(index, arr.length - 1) : -1;
        saveTimer.restart();
    }

    function updateSelected(field: string, value: string): void {
        if (root.selectedIndex < 0)
            return;
        const arr = root.notes.slice();
        arr[root.selectedIndex] = Object.assign({}, arr[root.selectedIndex], {
            [field]: value,
            updated: Date.now()
        });
        root.notes = arr;
        saveTimer.restart();
    }

    FileView {
        id: fileView

        path: `${Paths.state}/notes_tab.json`
        watchChanges: false
        printErrors: false

        onLoaded: {
            try {
                const data = JSON.parse(fileView.text());
                if (Array.isArray(data))
                    root.notes = data;
            } catch (e) {
                root.notes = [];
            }
        }

        onLoadFailed: root.notes = []
    }

    Timer {
        id: saveTimer
        interval: 400
        onTriggered: {
            fileView.setText(JSON.stringify(root.notes));
        }
    }

    Component.onCompleted: fileView.reload()

    RowLayout {
        id: layout

        anchors.fill: parent
        spacing: Tokens.spacing.medium

        StyledRect {
            Layout.preferredWidth: 260
            Layout.fillHeight: true

            radius: Tokens.rounding.large
            color: Colours.tPalette.m3surfaceContainerLow

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Tokens.padding.large
                spacing: Tokens.spacing.small

                RowLayout {
                    Layout.fillWidth: true

                    StyledText {
                        text: Tr.tr("Notes")
                        font: Tokens.font.body.builders.large.size(20).weight(Font.DemiBold).build()
                        color: Colours.palette.m3onSurface
                        Layout.fillWidth: true
                        Layout.leftMargin: Tokens.padding.small
                    }

                    StyledRect {
                        id: newNoteBtn

                        implicitWidth: 34
                        implicitHeight: 34
                        radius: newNoteArea.pressed ? Tokens.rounding.medium : Tokens.rounding.full
                        color: newNoteArea.containsMouse ? Colours.tPalette.m3surfaceContainerHighest : Colours.tPalette.m3surfaceContainerHigh
                        scale: newNoteArea.pressed ? 0.88 : 1

                        Behavior on radius {
                            Anim {
                                type: Anim.EmphasizedSmall
                            }
                        }

                        Behavior on scale {
                            Anim {
                                type: Anim.EmphasizedSmall
                            }
                        }

                        Behavior on color {
                            CAnim {}
                        }

                        MaterialIcon {
                            anchors.centerIn: parent
                            text: "add"
                            color: Colours.palette.m3primary
                            fontStyle: Tokens.font.icon.medium
                        }

                        CustomMouseArea {
                            id: newNoteArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.newNote()
                        }
                    }
                }

                StyledRect {
                    Layout.fillWidth: true
                    implicitHeight: 1
                    color: Colours.palette.m3outlineVariant
                }

                Flickable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentWidth: width
                    contentHeight: list.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    ColumnLayout {
                        id: list
                        width: parent.width
                        spacing: Tokens.spacing.extraSmall

                        Repeater {
                            model: root.notes

                            delegate: StyledRect {
                                id: noteItem

                                required property var modelData
                                required property int index

                                readonly property bool selected: index === root.selectedIndex

                                Layout.fillWidth: true
                                implicitHeight: itemCol.implicitHeight + Tokens.padding.medium

                                radius: selected ? Tokens.rounding.medium : Tokens.rounding.small
                                color: selected ? Colours.palette.m3secondaryContainer : (itemArea.containsMouse ? Colours.tPalette.m3surfaceContainerHigh : "transparent")
                                scale: itemArea.pressed ? 0.97 : 1

                                Behavior on color {
                                    CAnim {}
                                }

                                Behavior on radius {
                                    Anim {
                                        type: Anim.EmphasizedSmall
                                    }
                                }

                                Behavior on scale {
                                    Anim {
                                        type: Anim.EmphasizedSmall
                                    }
                                }

                                ColumnLayout {
                                    id: itemCol
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.margins: Tokens.padding.small
                                    spacing: 2

                                    RowLayout {
                                        Layout.fillWidth: true

                                        StyledText {
                                            Layout.fillWidth: true
                                            elide: Text.ElideRight
                                            text: noteItem.modelData.title || Tr.tr("Untitled")
                                            font: Tokens.font.body.builders.medium.weight(Font.DemiBold).build()
                                            color: noteItem.selected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                                        }

                                        MaterialIcon {
                                            id: deleteIcon

                                            opacity: deleteArea.containsMouse || noteItem.selected ? 1 : 0
                                            scale: opacity === 1 ? 1 : 0.6
                                            text: "close"
                                            fontStyle: Tokens.font.icon.medium
                                            color: deleteArea.containsMouse ? Colours.palette.m3error : Colours.palette.m3onSecondaryContainer

                                            Behavior on opacity {
                                                Anim {
                                                    type: Anim.FastEffects
                                                }
                                            }

                                            Behavior on scale {
                                                Anim {
                                                    type: Anim.EmphasizedSmall
                                                }
                                            }

                                            Behavior on color {
                                                CAnim {}
                                            }

                                            CustomMouseArea {
                                                id: deleteArea
                                                anchors.fill: parent
                                                anchors.margins: -6
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: root.deleteNote(noteItem.index)
                                            }
                                        }
                                    }

                                    StyledText {
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                        maximumLineCount: 1
                                        text: noteItem.modelData.body || Tr.tr("No additional text")
                                        font: Tokens.font.body.small
                                        opacity: 0.7
                                        color: noteItem.selected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
                                    }
                                }

                                CustomMouseArea {
                                    id: itemArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    z: -1
                                    onClicked: root.selectedIndex = noteItem.index
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.topMargin: Tokens.spacing.large
                            visible: root.notes.length === 0
                            spacing: Tokens.spacing.small

                            MaterialIcon {
                                Layout.alignment: Qt.AlignHCenter
                                text: "note_add"
                                fontStyle: Tokens.font.icon.extraLarge
                                color: Colours.palette.m3onSurfaceVariant
                                opacity: 0.4
                            }

                            StyledText {
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.WordWrap
                                text: Tr.tr("No notes yet. Tap + to add one.")
                                font: Tokens.font.body.small
                                opacity: 0.6
                                color: Colours.palette.m3onSurfaceVariant
                            }
                        }
                    }
                }
            }
        }

        StyledRect {
            Layout.fillWidth: true
            Layout.fillHeight: true

            radius: Tokens.rounding.large
            color: Colours.tPalette.m3surfaceContainerLowest

            ColumnLayout {
                id: editorCol

                transform: Translate {
                    id: editorShift
                }

                anchors.fill: parent
                anchors.margins: Tokens.padding.large
                spacing: Tokens.spacing.medium
                visible: root.selectedNote !== null

                property var trackedId: root.selectedNote ? root.selectedNote.id : null
                onTrackedIdChanged: {
                    switchAnim.restart();
                }

                SequentialAnimation {
                    id: switchAnim

                    ParallelAnimation {
                        Anim {
                            target: editorCol
                            property: "opacity"
                            to: 0.35
                            type: Anim.FastEffects
                        }
                        Anim {
                            target: editorShift
                            property: "y"
                            to: 6
                            type: Anim.FastSpatial
                        }
                    }
                    ParallelAnimation {
                        Anim {
                            target: editorCol
                            property: "opacity"
                            to: 1
                            type: Anim.EmphasizedSmall
                        }
                        Anim {
                            target: editorShift
                            property: "y"
                            to: 0
                            type: Anim.EmphasizedSmall
                        }
                    }
                }

                StyledTextField {
                    id: titleField

                    Layout.fillWidth: true
                    type: StyledTextField.Filled
                    radius: Tokens.rounding.medium
                    text: root.selectedNote ? root.selectedNote.title : ""
                    // The floating "Title" label only shows while the field is empty.
                    placeholderText: text.length === 0 ? Tr.tr("Title") : ""
                    font: Tokens.font.body.builders.large.size(22).weight(Font.DemiBold).build()
                    horizontalPadding: Tokens.padding.medium
                    verticalPadding: text.length === 0 ? Tokens.padding.large : Tokens.padding.medium
                    onTextEdited: root.updateSelected("title", text)

                    Keys.onReturnPressed: bodyField.forceActiveFocus()
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.small

                    StyledRect {
                        implicitWidth: toolRow.implicitWidth + Tokens.padding.small * 2
                        implicitHeight: 36
                        radius: Tokens.rounding.full
                        color: Colours.tPalette.m3surfaceContainerHigh
                        enabled: !root.previewMode
                        opacity: enabled ? 1 : 0.38

                        Behavior on opacity {
                            Anim {
                                type: Anim.FastEffects
                            }
                        }

                        Row {
                            id: toolRow

                            anchors.centerIn: parent
                            spacing: 2

                            FormatButton {
                                icon: "format_bold"
                                onClicked: bodyField.mdFormat("bold")
                            }

                            FormatButton {
                                icon: "format_italic"
                                onClicked: bodyField.mdFormat("italic")
                            }

                            FormatButton {
                                icon: "format_strikethrough"
                                onClicked: bodyField.mdFormat("strike")
                            }

                            FormatButton {
                                icon: "code"
                                onClicked: bodyField.mdFormat("code")
                            }

                            FormatButton {
                                icon: "title"
                                onClicked: bodyField.mdHeading()
                            }

                            FormatButton {
                                icon: "format_list_bulleted"
                                onClicked: bodyField.mdLines("bullet")
                            }

                            FormatButton {
                                icon: "format_list_numbered"
                                onClicked: bodyField.mdLines("numbered")
                            }

                            FormatButton {
                                icon: "checklist"
                                onClicked: bodyField.mdLines("task")
                            }

                            FormatButton {
                                icon: "format_quote"
                                onClicked: bodyField.mdLines("quote")
                            }

                            FormatButton {
                                icon: "link"
                                onClicked: bodyField.mdLink()
                            }
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    StyledRect {
                        id: modeToggle

                        implicitWidth: modeLabel.implicitWidth + Tokens.padding.medium * 2
                        implicitHeight: modeLabel.implicitHeight + Tokens.padding.small * 2
                        radius: Tokens.rounding.full
                        color: modeArea.containsMouse ? Colours.palette.m3secondaryContainer : Colours.tPalette.m3surfaceContainerHigh
                        scale: modeArea.pressed ? 0.92 : 1

                        Behavior on color {
                            CAnim {}
                        }

                        Behavior on scale {
                            Anim {
                                type: Anim.EmphasizedSmall
                            }
                        }

                        StyledText {
                            id: modeLabel

                            anchors.centerIn: parent
                            text: Tr.tr(root.previewMode ? "Edit" : "Preview")
                            font: Tokens.font.body.small
                            color: Colours.palette.m3onSurfaceVariant
                        }

                        CustomMouseArea {
                            id: modeArea

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.previewMode = !root.previewMode
                        }
                    }
                }

                Flickable {
                    id: bodyFlick

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentWidth: width
                    contentHeight: root.previewMode ? preview.implicitHeight : bodyField.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    LiveEdit {
                        id: bodyField

                        width: parent.width
                        visible: !root.previewMode
                        source: root.selectedNote ? root.selectedNote.body : ""
                        noteId: root.selectedNote ? root.selectedNote.id : null
                        dimColour: Colours.palette.m3outline
                        accentColour: Colours.palette.m3primary
                        codeColour: Colours.palette.m3surfaceContainerHigh
                        wrapMode: TextEdit.Wrap
                        font: Tokens.font.body.medium
                        color: Colours.palette.m3onSurface
                        selectByMouse: true
                        selectionColor: Qt.alpha(Colours.palette.m3primary, 0.4)
                        selectedTextColor: color
                        renderType: TextEdit.NativeRendering
                        persistentSelection: true
                        onEdited: text => root.updateSelected("body", text)

                        onCursorRectangleChanged: {
                            const r = cursorRectangle;
                            if (r.y < bodyFlick.contentY)
                                bodyFlick.contentY = r.y;
                            else if (r.y + r.height > bodyFlick.contentY + bodyFlick.height)
                                bodyFlick.contentY = r.y + r.height - bodyFlick.height;
                        }

                        StyledText {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            visible: bodyField.length === 0
                            text: Tr.tr("Start writing...")
                            font: bodyField.font
                            opacity: 0.5
                            color: Colours.palette.m3onSurfaceVariant
                        }
                    }

                    StyledText {
                        id: preview

                        width: parent.width
                        visible: root.previewMode
                        text: root.selectedNote ? root.previewMarkdown(root.selectedNote.body) : ""
                        textFormat: Text.MarkdownText
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        font: Tokens.font.body.medium
                        color: Colours.palette.m3onSurface
                    }
                }

                StyledRect {
                    Layout.alignment: Qt.AlignRight
                    visible: root.selectedNote !== null
                    radius: Tokens.rounding.full
                    color: Colours.tPalette.m3surfaceContainerHigh
                    implicitWidth: editedLabel.implicitWidth + Tokens.padding.medium * 2
                    implicitHeight: editedLabel.implicitHeight + Tokens.padding.small * 2

                    StyledText {
                        id: editedLabel
                        anchors.centerIn: parent
                        text: root.selectedNote ? Tr.tr("Edited %1").arg(new Date(root.selectedNote.updated).toLocaleTimeString(Qt.locale(), "hh:mm")) : ""
                        font: Tokens.font.body.small
                        opacity: 0.7
                        color: Colours.palette.m3onSurfaceVariant
                    }
                }
            }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: Tokens.spacing.large
                visible: root.selectedNote === null

                StyledRect {
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: 96
                    implicitHeight: 96
                    radius: Tokens.rounding.full
                    color: Colours.tPalette.m3surfaceContainer

                    MaterialIcon {
                        id: emptyIcon

                        anchors.centerIn: parent
                        text: "sticky_note_2"
                        fontStyle: Tokens.font.icon.builders.extraLarge.scale(1.5).build()
                        color: Colours.palette.m3onSurfaceVariant
                        opacity: 0.6

                        SequentialAnimation on scale {
                            loops: Animation.Infinite
                            running: root.selectedNote === null
                            NumberAnimation {
                                to: 1.06
                                duration: Tokens.anim.durations.expressiveSlowEffects
                                easing: Tokens.anim.expressiveSlowEffects
                            }
                            NumberAnimation {
                                to: 1
                                duration: Tokens.anim.durations.expressiveSlowEffects
                                easing: Tokens.anim.expressiveSlowEffects
                            }
                        }
                    }
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: Tr.tr("Select a note or create one")
                    font: Tokens.font.body.medium
                    opacity: 0.6
                    color: Colours.palette.m3onSurfaceVariant
                }
            }
        }
    }

    component FormatButton: Item {
        id: fb

        required property string icon

        signal clicked

        implicitWidth: 32
        implicitHeight: 32

        StateLayer {
            radius: Tokens.rounding.full
            color: Colours.palette.m3onSurface
            onClicked: fb.clicked()
        }

        MaterialIcon {
            anchors.centerIn: parent
            text: fb.icon
            color: Colours.palette.m3onSurfaceVariant
            fontStyle: Tokens.font.icon.medium
        }
    }

    // A TextEdit that keeps the note as plain markdown but shows it styled while you type:
    // markers stay visible but dimmed, bold looks bold, and so on.
    component LiveEdit: TextEdit {
        id: ed

        property string source
        property var noteId
        property color dimColour
        property color accentColour
        property color codeColour

        // Switches itself off if Qt's rich text doesn't round-trip the note exactly.
        property bool live: true

        property bool ready: false
        property bool busy: false
        property string current: ""
        property real lastEdit: 0
        property int lastPos: 0
        property var undoStack: []
        property var redoStack: []

        signal edited(string text)

        // <pure>
        function runBefore(src, i, ch) {
            let n = 0;
            while (i - 1 - n >= 0 && src[i - 1 - n] === ch)
                n++;
            return n;
        }

        function runAfter(src, i, ch) {
            let n = 0;
            while (i + n < src.length && src[i + n] === ch)
                n++;
            return n;
        }

        // Adds or removes bold, italic, strikethrough or code around the selection.
        function toggleInline(src, s, e, kind) {
            const ch = {
                bold: "*",
                italic: "*",
                strike: "~",
                code: "`"
            }[kind];
            const len = {
                bold: 2,
                italic: 1,
                strike: 2,
                code: 1
            }[kind];
            const mark = ch.repeat(len);

            // Content between any markers the selection already includes.
            let a = s;
            let b = e;
            while (a < b && src[a] === ch)
                a++;
            while (b > a && src[b - 1] === ch)
                b--;
            if (a >= b && s !== e) {
                a = s;
                b = s;
            }

            const run = Math.min(runBefore(src, a, ch), runAfter(src, b, ch));
            const on = kind === "bold" ? run >= 2 : kind === "italic" ? run % 2 === 1 : run >= len;
            if (on)
                return {
                    src: src.slice(0, a - len) + src.slice(a, b) + src.slice(b + len),
                    s: a - len,
                    e: b - len
                };
            return {
                src: src.slice(0, a) + mark + src.slice(a, b) + mark + src.slice(b),
                s: a + len,
                e: b + len
            };
        }

        // Adds or removes a list or quote prefix on every line the selection touches.
        function toggleLines(src, s, e, kind) {
            const ls = s === 0 ? 0 : src.lastIndexOf("\n", s - 1) + 1;
            const endRef = e > s && src[e - 1] === "\n" ? e - 1 : e;
            let le = src.indexOf("\n", endRef);
            if (le < 0)
                le = src.length;
            const lines = src.slice(ls, le).split("\n");

            const any = /^(\s*)(?:[-*+]\s\[[ xX]\]\s|[-*+]\s|\d+[.)]\s)/;
            const own = {
                bullet: /^(\s*)[-*+]\s(?!\[[ xX]\]\s)/,
                task: /^(\s*)[-*+]\s\[[ xX]\]\s/,
                numbered: /^(\s*)\d+[.)]\s/,
                quote: /^(\s*)>\s?/
            }[kind];

            const filled = lines.filter(l => l.trim() !== "");
            const allOn = filled.length > 0 && filled.every(l => own.test(l));
            let n = 0;
            const out = lines.map(l => {
                if (l.trim() === "")
                    return l;
                if (allOn)
                    return l.replace(own, "$1");
                const indent = /^\s*/.exec(l)[0];
                const base = kind === "quote" ? l.slice(indent.length) : l.replace(any, "$1").slice(indent.length);
                n++;
                const prefix = kind === "bullet" ? "- " : kind === "task" ? "- [ ] " : kind === "numbered" ? n + ". " : "> ";
                return indent + prefix + base;
            });

            const joined = out.join("\n");
            const next = src.slice(0, ls) + joined + src.slice(le);
            if (s === e) {
                const pos = Math.max(ls, s + out[0].length - lines[0].length);
                return {
                    src: next,
                    s: pos,
                    e: pos
                };
            }
            return {
                src: next,
                s: ls,
                e: ls + joined.length
            };
        }

        // None, #, ##, ### on the line the caret is in.
        function cycleHeading(src, s, e) {
            const ls = s === 0 ? 0 : src.lastIndexOf("\n", s - 1) + 1;
            let le = src.indexOf("\n", ls);
            if (le < 0)
                le = src.length;
            const line = src.slice(ls, le);
            const m = /^(#{1,6})\s+/.exec(line);
            const level = m ? Math.min(m[1].length, 3) : 0;
            const next = (level + 1) % 4;
            const out = (next ? "#".repeat(next) + " " : "") + line.slice(m ? m[0].length : 0);
            const delta = out.length - line.length;
            return {
                src: src.slice(0, ls) + out + src.slice(le),
                s: Math.max(ls, s + delta),
                e: Math.max(ls, e + delta)
            };
        }

        // [selection](url) with "url" selected, or [text](url) with "text" selected.
        function makeLink(src, s, e) {
            const sel = src.slice(s, e);
            const label = sel || "text";
            const next = src.slice(0, s) + "[" + label + "](url)" + src.slice(e);
            if (sel)
                return {
                    src: next,
                    s: s + label.length + 3,
                    e: s + label.length + 6
                };
            return {
                src: next,
                s: s + 1,
                e: s + 5
            };
        }

        // Per-character style flags for one line.
        function styleLine(line, inFence) {
            const BOLD = 1, ITALIC = 2, STRIKE = 4, CODE = 8, DIM = 16, ACCENT = 32, HEAD = 64;
            const n = line.length;
            const f = new Array(n).fill(0);
            let level = 0;
            if (inFence) {
                f.fill(CODE);
                return {
                    f: f,
                    level: 0
                };
            }

            let start = 0;
            let m;
            if ((m = /^(#{1,6})(\s+)/.exec(line))) {
                level = Math.min(m[1].length, 3);
                start = m[0].length;
                for (let i = 0; i < n; i++)
                    f[i] = i < start ? DIM | HEAD : HEAD;
            } else if (/^\s*([-*_])(\s*\1){2,}\s*$/.test(line)) {
                f.fill(DIM);
                return {
                    f: f,
                    level: 0
                };
            } else {
                if ((m = /^(\s*>+\s?)/.exec(line))) {
                    for (let i = 0; i < m[0].length; i++)
                        f[i] = DIM;
                    start = m[0].length;
                }
                const l = /^(\s*)([-*+]|\d+[.)])(\s+)(\[[ xX]\]\s+)?/.exec(line.slice(start));
                if (l) {
                    const a = start + l[1].length;
                    for (let i = a; i < a + l[2].length; i++)
                        f[i] = ACCENT;
                    if (l[4]) {
                        const c = a + l[2].length + l[3].length;
                        for (let i = c; i < c + 3; i++)
                            f[i] = ACCENT;
                    }
                    start += l[0].length;
                }
            }

            // Inline styles. Consumed characters are masked so later patterns skip them.
            let work = line.slice(0, start).replace(/[\s\S]/g, "\u0001") + line.slice(start);
            const mask = (a, b) => {
                work = work.slice(0, a) + "\u0001".repeat(b - a) + work.slice(b);
            };
            const flag = (a, b, v) => {
                for (let i = a; i < b; i++)
                    f[i] |= v;
            };
            const wordChar = i => i >= 0 && i < n && /\w/.test(line[i]);
            let r;

            const code = /`([^`]+)`/g;
            while ((r = code.exec(work))) {
                const a = r.index, b = a + r[0].length;
                flag(a, b, CODE);
                flag(a, a + 1, DIM);
                flag(b - 1, b, DIM);
                mask(a, b);
            }

            const bold = /(\*\*|__)(\S(?:.*?\S)?)\1/g;
            while ((r = bold.exec(work))) {
                const a = r.index, len = r[1].length, b = a + r[0].length;
                if (r[1] === "__" && (wordChar(a - 1) || wordChar(b)))
                    continue;
                flag(a, a + len, DIM);
                flag(b - len, b, DIM);
                flag(a + len, b - len, BOLD);
                mask(a, a + len);
                mask(b - len, b);
            }

            const strike = /~~(\S(?:.*?\S)?)~~/g;
            while ((r = strike.exec(work))) {
                const a = r.index, b = a + r[0].length;
                flag(a, a + 2, DIM);
                flag(b - 2, b, DIM);
                flag(a + 2, b - 2, STRIKE);
                mask(a, a + 2);
                mask(b - 2, b);
            }

            const star = /\*([^\s*](?:[^*]*[^\s*])?)\*/g;
            while ((r = star.exec(work))) {
                const a = r.index, b = a + r[0].length;
                flag(a, a + 1, DIM);
                flag(b - 1, b, DIM);
                flag(a + 1, b - 1, ITALIC);
            }

            const under = /_([^\s_](?:[^_]*[^\s_])?)_/g;
            while ((r = under.exec(work))) {
                const a = r.index, b = a + r[0].length;
                if (wordChar(a - 1) || wordChar(b))
                    continue;
                flag(a, a + 1, DIM);
                flag(b - 1, b, DIM);
                flag(a + 1, b - 1, ITALIC);
            }

            return {
                f: f,
                level: level
            };
        }

        // Turns a line and its flags into rich text runs.
        function runs(line, f, level, col) {
            const BOLD = 1, ITALIC = 2, STRIKE = 4, CODE = 8, DIM = 16, ACCENT = 32, HEAD = 64;
            const esc = s => s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
            const size = level === 1 ? "x-large" : level === 2 ? "large" : "";
            let out = "";
            let i = 0;
            while (i < line.length) {
                let j = i + 1;
                while (j < line.length && f[j] === f[i])
                    j++;
                const fl = f[i];
                const css = [];
                if (fl & CODE)
                    css.push("font-family:monospace", "background-color:" + col.codeBg);
                if (fl & ACCENT)
                    css.push("color:" + col.accent, "font-weight:600");
                if (fl & DIM)
                    css.push("color:" + col.dim);
                if (fl & (BOLD | HEAD))
                    css.push("font-weight:700");
                if (fl & ITALIC)
                    css.push("font-style:italic");
                if (fl & STRIKE)
                    css.push("text-decoration: line-through");
                if ((fl & HEAD) && size)
                    css.push("font-size:" + size);
                const text = esc(line.slice(i, j));
                out += css.length ? '<span style="' + css.join("; ") + '">' + text + "</span>" : text;
                i = j;
            }
            return out;
        }

        // The whole note as rich text. Every source character stays exactly one character,
        // so positions in the editor are positions in the markdown.
        function htmlFor(src, col) {
            const margins = "margin-top:0px; margin-bottom:0px; margin-left:0px; margin-right:0px; -qt-block-indent:0; text-indent:0px;";
            let out = '<html><head><meta name="qrichtext" content="1" /><style type="text/css">p, li { white-space: pre-wrap; }</style></head><body>';
            let fence = false;
            for (const line of src.split("\n")) {
                if (line === "") {
                    out += '<p style="-qt-paragraph-type:empty; ' + margins + '"><br /></p>';
                    continue;
                }
                let st;
                if (/^\s*```/.test(line)) {
                    st = {
                        f: new Array(line.length).fill(16),
                        level: 0
                    };
                    fence = !fence;
                } else {
                    st = styleLine(line, fence);
                }
                out += '<p style="' + margins + '">' + runs(line, st.f, st.level, col) + "</p>";
            }
            return out + "</body></html>";
        }
        // </pure>

        function hex(c) {
            if (!c)
                return "#808080";
            const p = v => Math.round(v * 255).toString(16).padStart(2, "0");
            return "#" + p(c.r) + p(c.g) + p(c.b);
        }

        function plain() {
            if (!live)
                return text;
            return getText(0, length).replace(/[\u2028\u2029]/g, "\n");
        }

        // Shows src, styled, with the selection from..to.
        function render(src, from, to) {
            busy = true;
            if (live) {
                text = htmlFor(src, {
                    dim: hex(dimColour),
                    accent: hex(accentColour),
                    codeBg: hex(codeColour)
                });
                const back = plain();
                if (back !== src) {
                    let at = 0;
                    while (at < src.length && src[at] === back[at])
                        at++;
                    console.warn(`NotesTab: styled editing switched off, rich text changed the note (first difference at ${at}, lengths ${src.length} vs ${back.length})`);
                    live = false;
                }
            }
            if (!live)
                text = src;
            const a = Math.min(from, length);
            const b = Math.min(to, length);
            if (a === b)
                cursorPosition = a;
            else
                select(a, b);
            busy = false;
        }

        function load(src) {
            if (!ready)
                return;
            current = src;
            undoStack = [];
            redoStack = [];
            lastEdit = 0;
            render(src, 0, 0);
            lastPos = 0;
        }

        // Called after every change the user makes.
        function sync() {
            if (!ready || busy || inputMethodComposing)
                return;
            const src = plain();
            if (src === current)
                return;
            if (undoStack.length === 0 || Date.now() - lastEdit > 700) {
                undoStack.push({
                    src: current,
                    pos: lastPos
                });
                if (undoStack.length > 200)
                    undoStack.shift();
            }
            redoStack = [];
            lastEdit = Date.now();
            current = src;
            edited(src);
            if (live)
                regen.restart();
            lastPos = cursorPosition;
        }

        // Restyles after typing. Runs just after the keystroke so Qt has finished with it.
        function regenerate() {
            if (!live || busy || inputMethodComposing)
                return;
            if (plain() !== current) {
                sync();
                return;
            }
            render(current, cursorPosition, cursorPosition);
            lastPos = cursorPosition;
        }

        // Applies a toolbar change as one undo step.
        function commit(r) {
            undoStack.push({
                src: current,
                pos: lastPos
            });
            if (undoStack.length > 200)
                undoStack.shift();
            redoStack = [];
            lastEdit = 0;
            current = r.src;
            edited(r.src);
            render(r.src, r.s, r.e);
            lastPos = r.e;
            forceActiveFocus();
        }

        function restore(snap) {
            current = snap.src;
            edited(snap.src);
            render(snap.src, snap.pos, snap.pos);
            lastPos = snap.pos;
            lastEdit = 0;
        }

        function undoEdit() {
            if (undoStack.length === 0)
                return;
            const snap = undoStack.pop();
            redoStack.push({
                src: current,
                pos: cursorPosition
            });
            restore(snap);
        }

        function redoEdit() {
            if (redoStack.length === 0)
                return;
            const snap = redoStack.pop();
            undoStack.push({
                src: current,
                pos: cursorPosition
            });
            restore(snap);
        }

        function mdFormat(kind) {
            commit(toggleInline(current, selectionStart, selectionEnd, kind));
        }

        function mdLines(kind) {
            commit(toggleLines(current, selectionStart, selectionEnd, kind));
        }

        function mdHeading() {
            commit(cycleHeading(current, selectionStart, selectionEnd));
        }

        function mdLink() {
            commit(makeLink(current, selectionStart, selectionEnd));
        }

        textFormat: live ? TextEdit.RichText : TextEdit.PlainText

        onTextChanged: sync()
        onInputMethodComposingChanged: {
            if (!inputMethodComposing)
                sync();
        }
        onSourceChanged: {
            if (ready && source !== current)
                load(source);
        }
        onNoteIdChanged: load(source)

        Component.onCompleted: {
            ready = true;
            load(source);
        }

        Keys.onPressed: event => {
            if (!(event.modifiers & Qt.ControlModifier))
                return;
            if (event.key === Qt.Key_Z) {
                event.accepted = true;
                if (event.modifiers & Qt.ShiftModifier)
                    redoEdit();
                else
                    undoEdit();
            } else if (event.key === Qt.Key_Y) {
                event.accepted = true;
                redoEdit();
            } else if (event.key === Qt.Key_B) {
                event.accepted = true;
                mdFormat("bold");
            } else if (event.key === Qt.Key_I) {
                event.accepted = true;
                mdFormat("italic");
            }
        }

        Timer {
            id: regen

            interval: 0
            onTriggered: ed.regenerate()
        }
    }
}
