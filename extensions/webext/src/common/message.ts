/**
 * @file Defines message interface.
 */

/**
 * Represents a type of message.
 */
enum MessageType {
    RequestRules = 'requestRules',
}

/**
 * Represents a stage of the trace.
 */
type TraceStage = 'contentStart' | 'contentEnd' | 'backgroundStart' | 'backgroundEnd' | 'nativeStart' | 'nativeEnd';

/**
 * Represents a message that is used to communicate between the content script,
 * background script and the native application.
 */
interface Message {
    type: MessageType;

    /**
     * A trace of the message. This trace allows measuring the time of the
     * message processing.
     * The key is the stage of the trace, the value is the timestamp of the
     * stage (in ms).
     */
    trace: Record<TraceStage, number>;

    /**
     * The payload of the message (if any).
     */
    payload: unknown;
}

export { type Message, MessageType, type TraceStage };
