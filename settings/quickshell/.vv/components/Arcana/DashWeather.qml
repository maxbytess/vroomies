import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    required property var th
    property bool active: false
    property string city: ""

    property real lat: NaN
    property real lon: NaN
    property string placeName: ""
    property real temp: NaN
    property int code: -1
    property var forecast: []
    property string errorText: ""
    property double lastFetch: 0
    property bool busy: false
    readonly property bool hasData: !isNaN(temp)
    readonly property string nf: "JetBrainsMono Nerd Font"

    function icon(c) {
        var cp = 0xF0590
        if (c === 0) cp = 0xF0599
        else if (c === 1 || c === 2) cp = 0xF0595
        else if (c === 45 || c === 48) cp = 0xF0591
        else if ((c >= 51 && c <= 67) || (c >= 80 && c <= 82)) cp = 0xF0597
        else if ((c >= 71 && c <= 77) || c === 85 || c === 86) cp = 0xF0598
        else if (c >= 95) cp = 0xF0593
        return String.fromCodePoint(cp)
    }
    function condition(c) {
        if (c === 0) return "Clear"
        if (c >= 1 && c <= 3) return "Cloudy"
        if (c === 45 || c === 48) return "Foggy"
        if (c >= 51 && c <= 57) return "Drizzle"
        if ((c >= 61 && c <= 67) || (c >= 80 && c <= 82)) return "Rain"
        if ((c >= 71 && c <= 77) || c === 85 || c === 86) return "Snow"
        if (c >= 95) return "Thunderstorm"
        return "Unknown"
    }

    function refresh() {
        if (busy) return
        busy = true
        errorText = ""
        if (!isNaN(lat)) { fetchForecast(); return }
        if (city.length > 0) {
            geoProc.command = ["curl", "-s", "-m", "10",
                "https://geocoding-api.open-meteo.com/v1/search?name=" + encodeURIComponent(city) + "&count=1&language=en&format=json"]
            geoProc.running = true
        } else {
            ipProc.command = ["curl", "-s", "-m", "10", "http://ip-api.com/json/?fields=status,lat,lon,city"]
            ipProc.running = true
        }
    }
    function fetchForecast() {
        fcProc.command = ["curl", "-s", "-m", "10",
            "https://api.open-meteo.com/v1/forecast?latitude=" + lat + "&longitude=" + lon +
            "&current=temperature_2m,weather_code&daily=weather_code,temperature_2m_max,temperature_2m_min" +
            "&forecast_days=4&timezone=auto"]
        fcProc.running = true
    }
    function fail(msg) { errorText = msg; busy = false }

    onActiveChanged: if (active && Date.now() - lastFetch > 20 * 60 * 1000) refresh()
    Component.onCompleted: if (active) refresh()

    Process {
        id: geoProc
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var r = JSON.parse(text).results[0]
                    root.lat = r.latitude; root.lon = r.longitude; root.placeName = r.name
                    root.fetchForecast()
                } catch (e) { root.fail("Location not found") }
            }
        }
    }
    Process {
        id: ipProc
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var r = JSON.parse(text)
                    if (r.status !== "success") throw new Error("ip")
                    root.lat = r.lat; root.lon = r.lon; root.placeName = r.city || ""
                    root.fetchForecast()
                } catch (e) { root.fail("No network / location") }
            }
        }
    }
    Process {
        id: fcProc
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var d = JSON.parse(text)
                    root.temp = d.current.temperature_2m
                    root.code = d.current.weather_code
                    var f = []
                    for (var i = 1; i < d.daily.time.length; i++)
                        f.push({ day: d.daily.time[i], code: d.daily.weather_code[i],
                                 high: d.daily.temperature_2m_max[i], low: d.daily.temperature_2m_min[i] })
                    root.forecast = f
                    root.lastFetch = Date.now()
                    root.busy = false
                } catch (e) { root.fail("Weather unavailable") }
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 16

        RowLayout {
            Layout.alignment: Qt.AlignVCenter
            spacing: 12
            Text {
                text: root.icon(root.code)
                color: root.th.fg
                font.family: root.nf; font.pixelSize: 40
            }
            ColumnLayout {
                spacing: 0
                Text {
                    visible: root.hasData
                    text: Math.round(root.temp) + "°C"
                    color: root.th.fg
                    font.family: root.th.fontFam
                    font.pixelSize: 28; font.bold: true
                }
                Text {
                    text: root.hasData
                        ? root.condition(root.code) + (root.placeName.length > 0 ? " · " + root.placeName : "")
                        : (root.errorText.length > 0 ? root.errorText : "Loading weather…")
                    color: root.th.muted
                    font.family: root.th.fontFam; font.pixelSize: 11
                }
            }
        }

        Item { Layout.fillWidth: true }

        RowLayout {
            Layout.alignment: Qt.AlignVCenter
            visible: root.hasData && root.forecast.length > 0
            spacing: 18
            Repeater {
                model: root.forecast
                ColumnLayout {
                    required property var modelData
                    spacing: 1
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: Qt.formatDate(new Date(modelData.day + "T12:00:00"), "ddd")
                        color: root.th.muted
                        font.family: root.th.fontFam; font.pixelSize: 10
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.icon(modelData.code)
                        color: root.th.accent
                        font.family: root.nf; font.pixelSize: 18
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: Math.round(modelData.high) + "°/" + Math.round(modelData.low) + "°"
                        color: root.th.muted
                        font.family: root.th.fontFam; font.pixelSize: 9
                    }
                }
            }
        }
    }
}
