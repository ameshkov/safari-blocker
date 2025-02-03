/*
 * WebExtension v1.0.0 (build date: Sat, 01 Feb 2025 16:09:49 GMT)
 * (c) 2025 ameshkov
 * Released under the ISC license
 * https://github.com/ameshkov/safari-blocker
 */
(function (browser) {
  'use strict';

  /**
   * @file Background script for the WebExtension.
   */
  // TODO(ameshkov): !!! TEMPORARY !!!
  const cache = new Map();
  const requestRules = async request => {
    const response = await browser.runtime.sendNativeMessage('application.id', request);
    const message = response;
    message.trace.backgroundEnd = new Date().getTime();
    // TODO(ameshkov): !!! TEMPORARY !!!
    const {
      url
    } = request.payload;
    cache.set(url, message);
    return message;
  };
  browser.runtime.onMessage.addListener(async request => {
    const message = request;
    // TODO(ameshkov): !!! TEMPORARY !!!
    const {
      url
    } = message.payload;
    if (cache.has(url)) {
      // Trigger the request again to get the latest rules.
      requestRules(message);
      const cachedMessage = cache.get(url);
      const now = new Date().getTime();
      if (cachedMessage) {
        cachedMessage.trace.contentStart = message.trace.contentStart;
        cachedMessage.trace.backgroundStart = now;
        cachedMessage.trace.backgroundEnd = now;
        cachedMessage.trace.nativeStart = now;
        cachedMessage.trace.nativeEnd = now;
      }
      return cachedMessage;
    }
    message.trace.backgroundStart = new Date().getTime();
    const responseMessage = await requestRules(message);
    return responseMessage;
  });
  // browser.runtime.onMessage.addListener(async (request, sender, sendResponse) => {
  //     request.timings["backgroundStart"] = new Date().getTime()
  //     let rules = await requestRules(request);
  //     return rules;
  // });
  // async function requestRules(request) {
  //     return new Promise((resolve) => {
  //         console.log('Requesting rules, ', performance.now());
  //         browser.runtime.sendNativeMessage("application.id", request, (response) => {
  //             console.log('Rules received, ', performance.now());
  //             response.timings["backgroundEnd"] = new Date().getTime()
  //             resolve(response);
  //         })
  //     })
  // }
  // // Инъекция скрипта на каждую страницу
  // browser.tabs.onUpdated.addListener((tabId, changeInfo, tab) => {
  //     if (changeInfo.status === 'complete' && /^https?:\/\//.test(tab.url)) {
  //         browser.scripting.executeScript({
  //             target: { tabId: tabId },
  //             world: "MAIN",
  //             func: () => {
  //                 console.log('Injected script');
  //                 try {
  //                     eval('console.log("This is inside eval")');
  //                 } catch (ex) {
  //                     console.log('Failed to eval: ', ex);
  //                 }
  //             }
  //         });
  //     }
  // });
  // // Фильтр для всех запросов
  // const filter = {
  //     urls: ["<all_urls>"]
  // };
  // // Слушатель для всех запросов
  // browser.webRequest.onBeforeRequest.addListener(
  //     (details) => {
  //         console.log("Запрос: ", details);
  //     },
  //     filter
  // );
  // // Слушатель для ошибок запросов
  // browser.webRequest.onErrorOccurred.addListener(
  //     (details) => {
  //         console.error("Ошибка запроса: ", details);
  //     },
  //     filter
  // );
  // // Обработка завершения запросов (опционально)
  // browser.webRequest.onCompleted.addListener(
  //     (details) => {
  //         console.log("Запрос завершён: ", details);
  //     },
  //     filter
  // );
})(browser);
