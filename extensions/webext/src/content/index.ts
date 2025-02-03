/**
 * @file Content script for the WebExtension.
 */
import browser from 'webextension-polyfill';
import { type Configuration, ContentScript } from 'safari-extension';

import { type TraceStage, type Message, MessageType } from '../common/message';

const startTime = new Date().getTime();

console.log('Web-Extension content script start time:', performance.now());

/**
 * Creates a trace object with the current time.
 *
 * @returns The trace object.
 */
const createTrace = (): Record<TraceStage, number> => {
    return {
        contentStart: new Date().getTime(),
        contentEnd: 0,
        backgroundStart: 0,
        backgroundEnd: 0,
        nativeStart: 0,
        nativeEnd: 0,
    };
};

/**
 * Prints trace information to the console.
 *
 * @param {Record<TraceStage, number>} trace - The trace object.
 */
const printTrace = (trace: Record<TraceStage, number>) => {
    const elapsed = trace.contentEnd - trace.contentStart;
    const elapsedContentToBackground = trace.backgroundStart - trace.contentStart;
    const elapsedBackgroundToNative = trace.nativeStart - trace.backgroundStart;
    const elapsedNative = trace.nativeEnd - trace.nativeStart;
    const elapsedNativeToBackground = trace.nativeEnd - trace.backgroundEnd;
    const elapsedBackgroundToContent = trace.contentEnd - trace.backgroundEnd;

    // eslint-disable-next-line no-console
    console.log('Elapsed total: ', elapsed);
    // eslint-disable-next-line no-console
    console.log('Elapsed content->background: ', elapsedContentToBackground);
    // eslint-disable-next-line no-console
    console.log('Elapsed background->native: ', elapsedBackgroundToNative);
    // eslint-disable-next-line no-console
    console.log('Elapsed inside native: ', elapsedNative);
    // eslint-disable-next-line no-console
    console.log('Elapsed native->background: ', elapsedNativeToBackground);
    // eslint-disable-next-line no-console
    console.log('Elapsed background->content: ', elapsedBackgroundToContent);
};

const requestRules = async (): Promise<Message> => {
    // Create a message to request rules.
    const message: Message = {
        type: MessageType.RequestRules,
        trace: createTrace(),
        payload: {
            url: window.location.href,
        },
    };

    const response = await browser.runtime.sendMessage(message);

    const responseMessage = response as Message;
    responseMessage.trace.contentEnd = new Date().getTime();

    printTrace(responseMessage.trace);

    return responseMessage;
};

/**
 * The entry point function of the content script.
 */
const main = async () => {
    const responseMessage = await requestRules();

    if (responseMessage) {
        const { payload } = responseMessage;
        const configuration = payload as Configuration;

        if (configuration) {
            new ContentScript(configuration).run();

            console.log('Elapsed before rules: ', new Date().getTime() - startTime);
        }
    }
};

main().catch((error) => {
    // eslint-disable-next-line no-console
    console.error('Error in content script: ', error);
});

// // Intercept DOMContentLoaded once, prevent its default behavior, then
// // manually re-dispatch it after a delay.
// window.addEventListener(
//     'DOMContentLoaded',
//     (originalEvent) => {
//         // Prevent other DOMContentLoaded listeners from getting this immediately.
//         originalEvent.stopImmediatePropagation();

//         console.log('DOMContentLoaded event intercepted!');

//         // Dispatch after 2 seconds (example) to "postpone"
//         setTimeout(() => {
//             const domEvent = new Event('DOMContentLoaded', {
//                 bubbles: true,
//                 cancelable: false,
//             });
//             window.dispatchEvent(domEvent);

//             console.log('DOMContentLoaded event manually re-dispatched.');
//         }, 2000);
//     },
//     // Use capture: true so we intercept early.
//     // Use once: true so our manual dispatch doesn't re-trigger this listener.
//     { capture: true, once: true }
// );

// // Intercept the "load" event similarly and re-dispatch.
// window.addEventListener(
//     'load',
//     (originalEvent) => {
//         // Prevent other load listeners from getting this immediately.
//         originalEvent.stopImmediatePropagation();

//         console.log('Load event intercepted!');

//         // Delay re-dispatch
//         setTimeout(() => {
//             const loadEvent = new Event('load', {
//                 bubbles: false,
//                 cancelable: false,
//             });
//             window.dispatchEvent(loadEvent);

//             console.log('Load event manually re-dispatched.');
//         }, 2000);
//     },
//     { capture: true, once: true }
// );
