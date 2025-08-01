/**
 * @file Defines message interface.
 */

/**
 * Represents a type of message.
 */
enum MessageType {
    InitContentScript = 'InitContentScript',
}
/**
 * Represents a message that is used to communicate between the content script,
 * background script and the native application.
 */
interface Message {
    type: MessageType;

    /**
     * The payload of the message (if any).
     */
    payload?: unknown;
}

export {
    type Message,
    MessageType,
};
