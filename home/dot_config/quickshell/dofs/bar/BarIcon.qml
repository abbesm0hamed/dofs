import QtQuick

Item {
    id: root
    property string glyph: ""
    property int size: 16
    property color color: "white"
    implicitWidth: size
    implicitHeight: size
    readonly property rect inkBounds: metrics.tightBoundingRect
    readonly property real glyphScale: Math.max(1, size - 2) / Math.max(1, inkBounds.width, inkBounds.height)

    TextMetrics {
        id: metrics
        text: root.glyph
        font.family: "Lilex Nerd Font Mono"
        font.pixelSize: 64
        renderType: Text.QtRendering
    }
    Text {
        text: root.glyph
        textFormat: Text.PlainText
        font: metrics.font
        renderType: Text.QtRendering
        color: root.color
        transformOrigin: Item.TopLeft
        scale: root.glyphScale
        x: (root.width - root.inkBounds.width * scale) / 2 - root.inkBounds.x * scale
        y: (root.height - root.inkBounds.height * scale) / 2 - (baselineOffset + root.inkBounds.y) * scale
    }
}
