/**
 * @file App extension content script.
 *
 * The script initializes content script functionality by listening
 * for messages from the Safari extension. It uses a delayed dispatcher
 * to handle DOM events and sends a rule request message to the extension.
 */

import { type Configuration, ContentScript } from 'safari-extension';

import { setupDelayedEventDispatcher } from './delayedEventDispatcher';
import { log, initLogger } from './logger';

/**
 * Defines the shape of the message requesting rules from the extension backend.
 */
interface RequestRulesRequestMessage {
    // The URL of the page that requested rules.
    url: string;
    // The timestamp of the request.
    requestedAt: number;
}

/**
 * Defines the shape of the response message containing configuration data.
 */
interface RequestRulesResponseMessage {
    // The configuration payload. If provided, it is used to initialize the content script.
    payload: Configuration | undefined;
    // Flag to indicate whether verbose logging should be enabled.
    verbose: boolean | undefined;
    // Timestamp when the request was made.
    requestedAt: number;
}

log('Content script is starting...');

// Initialize the delayed event dispatcher. This may intercept DOMContentLoaded
// and load events. The delay of 100ms is used as a buffer to capture critical
// initial events while waiting for the rules response.
const cancelDelayedDispatchAndDispatch = setupDelayedEventDispatcher(100);

/**
 * Callback function to handle response messages from the Safari extension.
 *
 * This function processes the rules response message:
 * - If a configuration payload is received, it instantiates and runs the
 *   ContentScript.
 * - It logs the elapsed time between the request and the response for
 *   performance monitoring.
 * - It toggles verbose logging based on the configuration included in
 *   the response.
 * - It cancels any pending delayed event dispatch logic to allow the page's
 *   natural event flow.
 *
 * @param event SafariExtensionMessageEvent - The message event from the
 * extension.
 */
const handleMessage = (event: SafariExtensionMessageEvent) => {
    log('Received message: ', event);

    // Cast the received event message to our expected
    // RequestRulesResponseMessage type.
    const message = event.message as RequestRulesResponseMessage;

    // If the configuration payload exists, run the ContentScript with it.
    if (message?.payload) {
        new ContentScript(message.payload).run();
    }

    // Compute the elapsed time since the rules request was initiated.
    const elapsed = new Date().getTime() - (message?.requestedAt ?? 0);
    log('Elapsed on messaging: ', elapsed);

    // Initialize the logger using the verbose flag from the response:
    // If verbose, use a prefix; otherwise, disable logging.
    if (message?.verbose) {
        initLogger('log', '[AdGuard Sample App Extension]');
    } else {
        initLogger('discard', '');
    }

    // Cancel the pending delayed event dispatch and process any queued events.
    cancelDelayedDispatchAndDispatch();
};

// Prepare the message to request configuration rules for the current page.
const message: RequestRulesRequestMessage = {
    url: window.location.href,
    requestedAt: new Date().getTime(),
};

// Dispatch the "requestRules" message to the Safari extension.
safari.extension.dispatchMessage('requestRules', message);

// Register the event listener for incoming messages from the extension.
safari.self.addEventListener('message', handleMessage);
