import QtQuick

Item {
    id: root
    property string glyph: ""
    property int size: 13
    property string fontFamily: "Lilex Nerd Font Mono"
    property color color: "white"
    implicitWidth: size
    implicitHeight: size
    readonly property rect inkBounds: metrics.tightBoundingRect
    // Match the visible height of label capitals, not the font's line box.
    readonly property real glyphScale: Math.max(1, reference.tightBoundingRect.height) / Math.max(1, inkBounds.width, inkBounds.height)

    TextMetrics {
        id: reference
        text: "M"
        font.family: root.fontFamily
        font.pixelSize: root.size
        renderType: Text.QtRendering
    }

    TextMetrics {
        id: metrics
        text: root.glyph
        font.family: root.fontFamily
        font.pixelSize: root.size
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
