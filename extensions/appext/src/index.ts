/**
 * @file App extension content script.
 */

import { type Configuration, ContentScript } from 'safari-extension';

import { setupDelayedEventDispatcher } from './delayedEventDispatcher';

interface RequestRulesMessage {
    payload: Configuration | undefined;
}

const start = new Date().getTime();
console.log('App-Extension content script start time:', performance.now());

// Initialize the delayed event dispatcher. This may intercept DOMContentLoaded and load events.
// TODO(ameshkov): !!! EXPLAIN WHY 100ms
const cancelDelayedDispatchAndDispatch = setupDelayedEventDispatcher(100);

/**
 * Handles the Safari message for "requestRules".
 *
 * When a response arrives, if it includes a configuration payload the ContentScript is run.
 * Regardless of message content, we immediately cancel any pending delayed dispatch logic.
 *
 * If the response is received before our interceptors are triggered, this function removes the interceptors
 * so that the page's natural DOMContentLoaded/load event flow is preserved.
 *
 * @param event SafariExtensionMessageEvent
 */
const handleMessage = (event: SafariExtensionMessageEvent) => {
    console.log('Elapsed on messaging App Extension:', new Date().getTime() - start);
    console.log('Received message:', event);

    const message = event.message as RequestRulesMessage;
    if (message?.payload) {
        new ContentScript(message.payload).run();
    }

    // Cancel delayed events interception and dispatch intercepted events if needed.
    cancelDelayedDispatchAndDispatch();
};

// Send a message to request rules for the current page.
safari.extension.dispatchMessage('requestRules', {
    url: window.location.href,
});

// Listen for the response.
safari.self.addEventListener('message', handleMessage);
