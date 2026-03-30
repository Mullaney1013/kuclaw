.pragma library

function cloneHistory(values) {
    return values ? values.slice() : []
}

function toggleSidebar(sidebarExpanded) {
    return !sidebarExpanded
}

function navigate(currentPage, backHistory, forwardHistory, nextPage) {
    const safeBack = cloneHistory(backHistory)
    const safeForward = cloneHistory(forwardHistory)

    if (currentPage === nextPage) {
        return {
            currentPage: currentPage,
            backHistory: safeBack,
            forwardHistory: safeForward
        }
    }

    safeBack.push(currentPage)

    return {
        currentPage: nextPage,
        backHistory: safeBack,
        forwardHistory: []
    }
}

function goBack(currentPage, backHistory, forwardHistory) {
    const safeBack = cloneHistory(backHistory)
    const safeForward = cloneHistory(forwardHistory)

    if (!safeBack.length) {
        return {
            currentPage: currentPage,
            backHistory: safeBack,
            forwardHistory: safeForward
        }
    }

    const previousPage = safeBack.pop()
    safeForward.unshift(currentPage)

    return {
        currentPage: previousPage,
        backHistory: safeBack,
        forwardHistory: safeForward
    }
}

function goForward(currentPage, backHistory, forwardHistory) {
    const safeBack = cloneHistory(backHistory)
    const safeForward = cloneHistory(forwardHistory)

    if (!safeForward.length) {
        return {
            currentPage: currentPage,
            backHistory: safeBack,
            forwardHistory: safeForward
        }
    }

    const nextPage = safeForward.shift()
    safeBack.push(currentPage)

    return {
        currentPage: nextPage,
        backHistory: safeBack,
        forwardHistory: safeForward
    }
}
