import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root
    required property var service
    required property string roleName
    required property string imageSource
    required property string revision
    property int current: -1
    property int pending: -1
    property string loadingSource: ""
    property string displayedSource: ""
    property string loadingRevision: ""
    property string displayedRevision: ""
    property string error: ""
    readonly property string surfaceKey: (screen ? screen.name : "unknown") + ":" + roleName
    readonly property var buffers: [first, second]
    readonly property bool ready: current >= 0 && buffers[current].status === Image.Ready
        && displayedSource === imageSource && displayedRevision === revision
    visible: current >= 0
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "#0d0e11"
    mask: Region {}
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "dofs-wallpaper-" + roleName
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    function load() {
        if (!imageSource) return;
        pending = current === 0 ? 1 : 0;
        loadingSource = imageSource;
        loadingRevision = revision;
        error = "";
        buffers[pending].source = "";
        buffers[pending].source = imageSource;
    }
    function loaded(index, status) {
        if (index !== pending) return;
        if (status === Image.Ready) {
            var previous = current;
            displayedSource = loadingSource;
            displayedRevision = loadingRevision;
            current = index;
            pending = -1;
            if (previous >= 0 && previous !== current) buffers[previous].source = "";
        } else if (status === Image.Error) {
            error = "Cannot load " + roleName + " wallpaper: " + imageSource;
            pending = -1;
        }
    }
    function report() { service.report(surfaceKey, ready, error); }
    onImageSourceChanged: refresh.restart()
    onRevisionChanged: refresh.restart()
    onReadyChanged: report()
    onErrorChanged: report()
    Component.onCompleted: { refresh.restart(); report(); }
    Component.onDestruction: service.forget(surfaceKey)
    Timer { id: refresh; interval: 0; onTriggered: root.load() }
    Image {
        id: first
        anchors.fill: parent
        visible: root.current === 0
        fillMode: Image.PreserveAspectCrop
        sourceSize.width: root.screen ? Math.ceil(root.screen.width * root.screen.devicePixelRatio) : 0
        sourceSize.height: root.screen ? Math.ceil(root.screen.height * root.screen.devicePixelRatio) : 0
        asynchronous: true
        cache: false
        onStatusChanged: root.loaded(0, status)
    }
    Image {
        id: second
        anchors.fill: parent
        visible: root.current === 1
        fillMode: Image.PreserveAspectCrop
        sourceSize.width: root.screen ? Math.ceil(root.screen.width * root.screen.devicePixelRatio) : 0
        sourceSize.height: root.screen ? Math.ceil(root.screen.height * root.screen.devicePixelRatio) : 0
        asynchronous: true
        cache: false
        onStatusChanged: root.loaded(1, status)
    }
}
