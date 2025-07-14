/**
 * @file App extension content script.
 *
 * The script initializes content script functionality by listening
 * for messages from the Safari extension. It uses a delayed dispatcher
 * to handle DOM events and sends a rule request message to the extension.
 */

import { type Configuration, ContentScript } from '@adguard/safari-extension';

import { setupDelayedEventDispatcher } from './delayedEventDispatcher';
import { log, initLogger } from './logger';

/**
 * Defines the shape of the message requesting rules from the extension backend.
 */
interface RequestRulesRequestMessage {
    /**
     * A pseudo-unique request ID for properly tracing the response to the
     * request that was sent by this instance of a SFSafariContentScript.
     * We will only accept responses to this specific request.
     *
     * The problem we are solving here is that Safari propagates responses from
     * the app extension down to subframes (and calling preventDefault and
     * stopPropagation does not stop it). So in order to avoid processing
     * responses from other instances of SFSafariContentScript, we use a
     * pseudo-unique request ID.
     */
    requestId: string;
    // The URL of the page that requested rules.
    url: string;
    // The top-level URL of the page that requested rules.
    topUrl: string | null;
    // The timestamp of the request.
    requestedAt: number;
}

/**
 * Defines the shape of the response message containing configuration data.
 */
interface RequestRulesResponseMessage {
    // Request ID of the corresponding request.
    requestId: string;
    // The configuration payload. If provided, it is used to initialize the
    // content script.
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

// Generate a pseudo-unique request ID for properly tracing the response to the
// request that was sent by this instance of a SFSafariContentScript.
// We will only accept responses to this specific request.
const requestId = Math.random().toString(36);

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

    if (message?.requestId !== requestId) {
        log('Received response for a different request ID: ', message?.requestId);
        return;
    }

    // If the configuration payload exists, run the ContentScript with it.
    if (message?.payload) {
        const configuration = message.payload as Configuration;
        new ContentScript(configuration).run();
        log('ContentScript applied');
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

/**
 * Returns the top-level URL of the current page or null if we're not
 * in an iframe.
 *
 * @returns {string | null} The top-level URL or null if we're not in an iframe.
 */
function getTopUrl(): string | null {
    try {
        if (window.top === window.self) {
            return null;
        }

        if (!window.top) {
            // window.top cannot be null under normal circumstances so assume
            // we're in an iframe.
            return 'https://third-party-domain.com/';
        }

        return window.top.location.href;
    } catch (ex) {
        log('Failed to get top URL: ', ex);

        // Return a random third-party domain as this error signals us
        // that we're in a third-party frame.
        return 'https://third-party-domain.com/';
    }
}

/**
 * Returns URL of the current page. If we're in an about:blank iframe, handles
 * it and returns the URL of the top page.
 */
function getUrl(): string {
    let url = window.location.href;
    const topUrl = getTopUrl();

    if (!url.startsWith('http') && topUrl) {
        // Handle the case of non-HTTP iframes, i.e. frames created by JS.
        // For instance, frames can be created as 'about:blank' or 'data:text/html'
        url = topUrl;
    }

    return url;
}

// Prepare the message to request configuration rules for the current page.
const message: RequestRulesRequestMessage = {
    requestId,
    url: getUrl(),
    topUrl: getTopUrl(),
    requestedAt: new Date().getTime(),
};

// Dispatch the "requestRules" message to the Safari extension.
safari.extension.dispatchMessage('requestRules', message);

// Register the event listener for incoming messages from the extension.
safari.self.addEventListener('message', handleMessage);
