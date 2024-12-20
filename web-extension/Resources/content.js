console.log('Content script start: ', performance.now());


let start = new Date().getTime()
const message = {
    name: "requestRules",
    timings: {
        "content": start
    },
}

browser.storage.local.get('cache').then((cache) => {
    console.log('Storage response: ', performance.now());

    let end = new Date().getTime()
    let elapsed = end - start

    console.log('Elapsed storage: ', elapsed)
})

browser.storage.local.get('filterList').then((cache) => {
    console.log('Storage filterList response: ', performance.now());

    let end = new Date().getTime()
    let elapsed = end - start

    console.log('Elapsed filterList storage: ', elapsed)
})

browser.runtime.sendMessage(message).then((response) => {
    console.log('requestRules response, ', performance.now())

    let end = new Date().getTime()

    let elapsed = end - start;
    let elapsedContentToBackground = response.timings["backgroundStart"] - response.timings["content"];
    let elapsedBackgroundToNative = response.timings["native"] - response.timings["backgroundStart"];
    let elapsedNativeToBackground = response.timings["backgroundEnd"] - response.timings["native"];
    let elapsedBackgroundToContent = end - response.timings["backgroundEnd"];

    console.log('Elapsed total: ', elapsed);
    console.log('Elapsed content->background: ', elapsedContentToBackground);
    console.log('Elapsed background->native: ', elapsedBackgroundToNative);
    console.log('Elapsed native->background: ', elapsedNativeToBackground);
    console.log('Elapsed background->content: ', elapsedBackgroundToContent);

    browser.storage.local.set({
        'cache': response
    })
});


