.pragma library

function styleForTitle(title) {
    const primary = title === "Status reports"
    return {
        pixelSize: primary ? 16 : 14,
        bold: primary,
        color: primary ? "#2C2D2B" : "#64635E"
    }
}
