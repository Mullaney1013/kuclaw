.pragma library

function activateWorkspace(items, index) {
    if (!Array.isArray(items) || index < 0 || index >= items.length)
        return items

    return items.map(function(item, itemIndex) {
        return {
            title: item.title || "",
            detail: item.detail || "",
            trailing: item.trailing || "",
            active: itemIndex === index
        }
    })
}
