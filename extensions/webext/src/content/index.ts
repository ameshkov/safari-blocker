/**
 * @file Content script for the WebExtension.
 *
 * This script runs in the context of a frame, and it's responsible for:
 * - Notifying the background script that the frame is available.
 * - Exposing content script to other scripts in the ISOLATED world, so that
 *   they were used by scripts injected by `browser.scripting.executeScript`.
 * - Delaying page load events to give time to injected scripts to initialize.
 */

import browser from 'webextension-polyfill';
import {
    ContentScript,
    setLogger,
    ConsoleLogger,
    LoggingLevel,
    setupDelayedEventDispatcher,
    type Configuration,
} from '@adguard/safari-extension';

import { type Message, MessageType } from '../common/message';

// Initialize the logger to be used by the `@adguard/safari-extension`.
// Change logging level to Debug if you need to see more details.
const log = new ConsoleLogger('[AdGuard Sample Web Extension]', LoggingLevel.Info);
setLogger(log);

// Initialize the delayed event dispatcher. This may intercept DOMContentLoaded
// and load events. The delay of 1000ms is used as a buffer to capture critical
// initial events while waiting for the rules response.
const cancelDelayedDispatchAndDispatch = setupDelayedEventDispatcher(1000);

// Declare global window object with `adguard` property so that we could
// expose ContentScript to other scripts in the ISOLATED world, this way
// it can be called by scripts injected by `browser.scripting.executeScript`.
declare global {
    interface Window {
        adguard: {
            contentScript: ContentScript;
        };
    }
}

/**
 * Main entry point function for the content script.
 *
 * This function:
 * 1. Exposes `adguard.contentScript` to other scripts in the ISOLATED world.
 * 2. Notifies the background page of the page that is loading. Background page
 *    will handle this event and insert necessary CSS and JS to this frame.
 * 3. When the background page responds, cancels any delayed events and flushes
 *    captured events.
 */
const main = async () => {
    // First of all, make sure that the content script is exposed to the
    // scripts that will be called by background script.
    window.adguard = {
        contentScript: new ContentScript(),
    };

    const message: Message = {
        type: MessageType.InitContentScript,
    };

    // Send the message to the background script and await the response.
    const response = await browser.runtime.sendMessage(message) as Message | undefined;

    // If the background page returned payload with configuration, it means
    // that it cannot apply it on its own and commands the content script
    // to do that.
    if (response?.payload) {
        const configuration = response.payload as Configuration;
        window.adguard.contentScript.applyConfiguration(configuration);
    }

    // After processing, cancel any pending delayed event dispatch and process
    // any queued events immediately.
    cancelDelayedDispatchAndDispatch();
};

// Execute the main function and catch any runtime errors.
main().catch((error) => {
    log.error('Error in content script: ', error);
});
