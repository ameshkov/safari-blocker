/**
 * @file Background script for the WebExtension.
 *
 * This script handles messages from other parts of the extension,
 * communicates with a native messaging host, and uses a cache mechanism
 * to serve responses quickly while updating them in the background.
 */

import browser from 'webextension-polyfill';
import {
    type Configuration,
    setLogger,
    ConsoleLogger,
    LoggingLevel,
    BackgroundScript,
} from '@adguard/safari-extension';

import { MessageType, type Message } from '../common/message';

// Initialize the logger to be used by the `@adguard/safari-extension`.
// Change logging level to Debug if you need to see more details.
const log = new ConsoleLogger('[AdGuard Sample Web Extension]', LoggingLevel.Info);
setLogger(log);

/**
 * Global variable to track the engine timestamp.
 * This value is used to invalidate the cache when the underlying engine
 * is updated.
 */
let engineTimestamp = 0;

/**
 * BackgroundScript is used to apply filtering configuration to web pages.
 * Note, that it relies on the content script to be injected into the page
 * and available in the ISOLATED world via `adguard.contentScript` object.
 */
const backgroundScript = new BackgroundScript();

/**
 * Cache to store the rules for a given URL. The key is a URL (string) and
 * the value is a Configuration. Caching content script configurations allows us
 * to respond to content script requests quickly while also updating the cache
 * in the background.
 */
const cache = new Map<string, Configuration>();

/**
 * Returns a cache key for the given URL and top-level URL.
 *
 * @param url - Page URL for which the rules are requested.
 * @param topUrl - Top-level page URL (to distinguish between frames)
 * @returns The cache key.
 */
const cacheKey = (url: string, topUrl: string | undefined) => `${url}#${topUrl ?? ''}`;

/**
 * Makes a native messaging request to obtain rules for the given message.
 * Also handles cache invalidation if the engine timestamp has changed.
 *
 * @param request - Original request from the content script.
 * @param url - Page URL for which the rules are requested.
 * @param topUrl - Top-level page URL (to distinguish between frames)
 * @returns The response message from the native host.
 */
const requestConfiguration = async (
    request: Message,
    url: string,
    topUrl: string | undefined,
): Promise<Configuration | null> => {
    // Prepare the request payload.
    request.payload = {
        url,
        topUrl,
    };
    // Send the request to the native messaging host and wait for the response.
    const response = await browser.runtime.sendNativeMessage('application.id', request);
    const message = response as Message;

    if (!message || !message.payload) {
        // No configuration received for some reason.
        return null;
    }

    // Extract the configuration from the response payload.
    const configuration = message.payload as Configuration;

    // If the engine timestamp has been updated, clear the cache and update
    // the timestamp.
    if (configuration.engineTimestamp !== engineTimestamp) {
        cache.clear();
        engineTimestamp = configuration.engineTimestamp;
    }

    // Save the new message in the cache for the given URL.
    const key = cacheKey(url, topUrl);
    cache.set(key, configuration);

    return configuration;
};

/**
 * Tries to get rules from the cache. If not found, requests them from the
 * native host.
 *
 * @param message - The original message from the content script.
 * @param url - Page URL for which the rules are requested.
 * @param topUrl - Top-level page URL (to distinguish between frames)
 * @returns The response message from the native host.
 */
const getConfiguration = async (
    message: Message,
    url: string,
    topUrl: string | undefined,
): Promise<Configuration | null> => {
    const key = cacheKey(url, topUrl);

    // If there is already a cached response for this URL:
    if (cache.has(key)) {
        // Fire off a new request to update the cache in the background.
        requestConfiguration(message, url, topUrl);

        // Retrieve the cached response.
        const cachedConfiguration = cache.get(key);

        // Return the cached message immediately.
        if (cachedConfiguration) {
            return cachedConfiguration;
        }
    }

    // Await the native request to get a fresh response.
    const configuration = await requestConfiguration(message, url, topUrl);

    // Return the new response.
    return configuration;
};

/**
 * Message listener that intercepts messages sent to the background script.
 *
 * @param request Message from the content script.
 * @param sender The sender of the message.
 * @returns The response message from the native host.
 */
const handleMessages = async (request: unknown, sender: browser.Runtime.MessageSender): Promise<unknown> => {
    // Cast the incoming request to `Message`.
    const message = request as Message;

    const tabId = sender.tab?.id ?? 0;
    const frameId = sender.frameId ?? 0;
    let blankFrame = false;

    let url = sender.url || '';
    const topUrl = frameId === 0 ? undefined : sender.tab?.url;

    if (!url.startsWith('http') && topUrl) {
        // Handle the case of non-HTTP iframes, i.e. frames created by JS.
        // For instance, frames can be created as 'about:blank' or 'data:text/html'
        url = topUrl;
        blankFrame = true;
    }

    const configuration = await getConfiguration(message, url, topUrl);
    if (!configuration) {
        log.error('No configuration received for ', url);

        return {};
    }

    // Prepare the response.
    const response: Message = {
        type: MessageType.InitContentScript,
    };

    // In the current Safari version we cannot apply rules to blank frames from
    // the background: https://bugs.webkit.org/show_bug.cgi?id=296702
    //
    // In this case we fallback to using the content script to apply rules.
    // The downside here is that the content script cannot override website's
    // CSPs.
    if (!blankFrame) {
        await backgroundScript.applyConfiguration(
            tabId,
            frameId,
            configuration,
        );
    } else {
        // Pass the configuration to the content script.
        response.payload = configuration;
    }

    return response;
};

// Start handling messages from content scripts.
browser.runtime.onMessage.addListener(handleMessages);
