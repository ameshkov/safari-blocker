browser.runtime.onMessage.addListener(async (request, sender, sendResponse) => {

    request.timings["backgroundStart"] = new Date().getTime()

    let rules = await requestRules(request);

    return rules;
});

async function requestRules(request) {
    return new Promise((resolve) => {
        console.log('Requesting rules, ', performance.now());

        browser.runtime.sendNativeMessage("application.id", request, (response) => {
            console.log('Rules received, ', performance.now());

            response.timings["backgroundEnd"] = new Date().getTime()
            resolve(response);
        })
    })
}

// Инъекция скрипта на каждую страницу
browser.tabs.onUpdated.addListener((tabId, changeInfo, tab) => {
    if (changeInfo.status === 'complete' && /^https?:\/\//.test(tab.url)) {
        browser.scripting.executeScript({
            target: { tabId: tabId },
            world: "MAIN",
            func: () => {
                console.log('Injected script');

                try {
                    eval('console.log("This is inside eval")');
                } catch (ex) {
                    console.log('Failed to eval: ', ex);
                }
            }
        });
    }
});


// Фильтр для всех запросов
const filter = {
    urls: ["<all_urls>"]
};

// Слушатель для всех запросов
browser.webRequest.onBeforeRequest.addListener(
    (details) => {
        console.log("Запрос: ", details);
    },
    filter
);

// Слушатель для ошибок запросов
browser.webRequest.onErrorOccurred.addListener(
    (details) => {
        console.error("Ошибка запроса: ", details);
    },
    filter
);

// Обработка завершения запросов (опционально)
browser.webRequest.onCompleted.addListener(
    (details) => {
        console.log("Запрос завершён: ", details);
    },
    filter
);
