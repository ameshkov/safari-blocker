/**
 * @file Content script for the WebExtension.
 */
import browser from 'webextension-polyfill';
import { type Configuration, ContentScript } from 'safari-extension';

import { type TraceStage, type Message, MessageType } from '../common/message';

// eslint-disable-next-line no-console
console.log('Hello, world!');

const configuration: Configuration = {
    css: [],
    extendedCSS: [],
    js: [],
    scriptlets: [],
};

const contentScript: ContentScript = new ContentScript(configuration);
contentScript.run();

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

const requestRules = async () => {
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
};

/**
 * The entry point function of the content script.
 */
const main = async () => {
    await requestRules();
};

main().catch((error) => {
    // eslint-disable-next-line no-console
    console.error('Error in content script: ', error);
});
