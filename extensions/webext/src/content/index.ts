/**
 * @file Content script for the WebExtension.
 *
 * This script runs in the context of a web page, and it's responsible for:
 * - Requesting necessary configuration (rules) from the background script.
 * - Initializing the content script by applying those configurations.
 * - Managing event dispatching with a slight delay to capture important page
 * events.
 */

import browser from 'webextension-polyfill';
import { type Configuration, ContentScript } from 'safari-extension';

import { log, initLogger } from './logger';
import { setupDelayedEventDispatcher } from './delayedEventDispatcher';
import {
    type TraceStage,
    type Message,
    type ResponseMessage,
    MessageType,
} from '../common/message';

// Log that the content script process has started.
log('Content script is starting...');

// Initialize the delayed event dispatcher. This may intercept DOMContentLoaded
// and load events. The delay of 100ms is used as a buffer to capture critical
// initial events while waiting for the rules response.
const cancelDelayedDispatchAndDispatch = setupDelayedEventDispatcher(100);

/**
 * Creates a trace object with the current time.
 *
 * The trace object is used to record timestamps at various stages of the
 * messaging process:
 * - contentStart: When the content script starts.
 * - contentEnd: When the content script finishes processing the message response.
 * - backgroundStart: When the background script starts processing.
 * - backgroundEnd: When the background script completes processing.
 * - nativeStart: When a native process (if any) starts.
 * - nativeEnd: When the native process completes processing.
 *
 * @returns The trace object used for logging message processing timings.
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

    // Log the elapsed timings in a structured format.
    log('Elapsed on messaging: ', {
        'Total elapsed': elapsed,
        'Content->Background': elapsedContentToBackground,
        'Background->Native': elapsedBackgroundToNative,
        'Native inside': elapsedNative,
        'Native->Background': elapsedNativeToBackground,
        'Background->Content': elapsedBackgroundToContent,
    });
};

/**
 * Sends a message to request configuration/rules from the background script.
 *
 * This function creates a messaging request including:
 * - A type indicating that rules are requested.
 * - A trace object containing the start time.
 * - The current page URL as part of the payload.
 *
 * After sending the message, the function waits for a response and updates the
 * trace information. It then configures the logger based on the verbosity
 * setting provided in the response.
 *
 * @returns The response message containing the configuration and updated trace.
 */
const requestRules = async (): Promise<ResponseMessage> => {
    // Create a message with the type RequestRules and attach the current URL
    // and trace info.
    const message: Message = {
        type: MessageType.RequestRules,
        trace: createTrace(),
        payload: {},
    };

    // Send the message to the background script and await the response.
    const response = await browser.runtime.sendMessage(message);

    // Cast the response to a ResponseMessage to access its specific properties.
    const responseMessage = response as ResponseMessage;
    // Update the trace to mark the end of the content script processing.
    responseMessage.trace.contentEnd = new Date().getTime();

    // Initialize the logger:
    // - If verbose logging is enabled, use console logging.
    // - Otherwise, discard the logs to reduce console noise.
    if (responseMessage.verbose) {
        initLogger('log', '[AdGuard Sample Web Extension]');
    } else {
        initLogger('discard', '');
    }

    // Print trace timing details to the console.
    printTrace(responseMessage.trace);

    return responseMessage;
};

/**
 * Main entry point function for the content script.
 *
 * This function:
 * 1. Requests configuration (rules) from the background script.
 * 2. Checks and applies the configuration if available.
 * 3. Instantiates and runs the ContentScript to apply filtering or modifications.
 * 4. Cancels any delayed events and flushes captured events.
 */
const main = async () => {
    // Request rules/configuration from background
    const responseMessage = await requestRules();

    if (responseMessage) {
        // Extract the payload from the response, which contains the configuration.
        const { payload, verbose } = responseMessage;
        const configuration = payload as Configuration;

        if (configuration) {
            // Instantiate and run the content script with the provided configuration.
            new ContentScript(configuration).run(verbose, '[AdGuard Sample Web Extension]');
            log('ContentScript applied');
        }
    }

    // After processing, cancel any pending delayed event dispatch and process
    // any queued events immediately.
    cancelDelayedDispatchAndDispatch();
};

// Execute the main function and catch any runtime errors.
main().catch((error) => {
    log('Error in content script: ', error);
});
