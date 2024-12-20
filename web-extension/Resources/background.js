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
