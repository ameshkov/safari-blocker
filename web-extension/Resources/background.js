/*
 * WebExtension v1.0.0 (build date: Thu, 10 Apr 2025 14:35:22 GMT)
 * (c) 2025 ameshkov
 * Released under the ISC license
 * https://github.com/ameshkov/safari-blocker
 */
(function (browser) {
  'use strict';

  /**
   * @file Background script for the WebExtension.
   *
   * This script handles messages from other parts of the extension,
   * communicates with a native messaging host, and uses a cache mechanism
   * to serve responses quickly while updating them in the background.
   */
  // Global variable to track the engine timestamp.
  // This value is used to invalidate the cache when the underlying engine
  // is updated.
  let engineTimestamp = 0;
  // Cache to store the rules for a given URL. The key is a URL (string) and
  // the value is a ResponseMessage. Caching responses allows us to respond to
  // content script requests quickly while also updating the cache in the
  // background.
  const cache = new Map();
  /**
   * Makes a native messaging request to obtain rules for the given message.
   * Also handles cache invalidation if the engine timestamp has changed.
   *
   * @param request - The incoming message containing the URL and trace info.
   * @returns The response message from the native host.
   */
  const requestRules = async request => {
    // Send the request to the native messaging host and wait for the response.
    const response = await browser.runtime.sendNativeMessage('application.id', request);
    const message = response;
    // Mark the end of background processing in the trace.
    message.trace.backgroundEnd = new Date().getTime();
    // Extract the URL from the request payload.
    const {
      url
    } = request.payload;
    // Extract the configuration from the response payload.
    const configuration = message.payload;
    // If the engine timestamp has been updated, clear the cache and update
    // the timestamp.
    if (configuration.engineTimestamp !== engineTimestamp) {
      cache.clear();
      engineTimestamp = configuration.engineTimestamp;
    }
    // Save the new message in the cache for the given URL.
    cache.set(url, message);
    return message;
  };
  /**
   * Message listener that intercepts messages sent to the background script.
   * It tries to immediately return a cached response if available while also
   * updating the cache in the background.
   */
  browser.runtime.onMessage.addListener(async request => {
    // Cast the incoming request as a Message.
    const message = request;
    // Extract the URL from the message payload.
    const {
      url
    } = message.payload;
    // If there is already a cached response for this URL:
    if (cache.has(url)) {
      // Fire off a new request to update the cache in the background.
      requestRules(message);
      // Retrieve the cached response.
      const cachedMessage = cache.get(url);
      // Get the current time for updating trace values.
      const now = new Date().getTime();
      if (cachedMessage) {
        // Update all relevant trace timestamps so that the caller can see
        // recent trace data.
        cachedMessage.trace.contentStart = message.trace.contentStart;
        cachedMessage.trace.backgroundStart = now;
        cachedMessage.trace.backgroundEnd = now;
        cachedMessage.trace.nativeStart = now;
        cachedMessage.trace.nativeEnd = now;
      }
      // Return the cached message immediately.
      return cachedMessage;
    }
    // If there is no cached response, mark the start time for background
    // processing.
    message.trace.backgroundStart = new Date().getTime();
    // Await the native request to get a fresh response.
    const responseMessage = await requestRules(message);
    // Return the new response.
    return responseMessage;
  });
})(browser);
