/**
 * @file Handles delaying and dispatching of DOMContentLoaded and load events.
 */

/**
 * The interceptors delay the events until either a response is received or the
 * timeout expires. If the events have already fired, no interceptors are added.
 *
 * @param timeout - Timeout in milliseconds after which the events are forced
 *                  (if not already handled).
 * @returns A function which, when invoked, cancels the timeout and dispatches
 *         (or removes) the interceptors.
 */
export function setupDelayedEventDispatcher(timeout = 100): () => void {
    interface Interceptor {
        name: string;
        options: EventInit;
        intercepted: boolean;
        listener: EventListener;
    }

    const interceptors: Interceptor[] = [];
    const events = [
        {
            name: 'DOMContentLoaded',
            options: { bubbles: true, cancelable: false },
        },
        {
            name: 'load',
            options: { bubbles: false, cancelable: false },
        },
    ];

    events.forEach((ev) => {
        const interceptor: Interceptor = {
            name: ev.name,
            options: ev.options,
            intercepted: false,
            listener: (event: Event) => {
                // Prevent immediate propagation.
                event.stopImmediatePropagation();
                interceptor.intercepted = true;

                // TODO(ameshkov): !!! REMOVE THIS LOG
                console.log(`${ev.name} event intercepted.`);
            },
        };
        interceptors.push(interceptor);

        window.addEventListener(ev.name, interceptor.listener, { capture: true });
    });

    let dispatched = false;
    const dispatchEvents = (trigger: string) => {
        if (dispatched) return;
        dispatched = true;
        interceptors.forEach((interceptor) => {
            // Remove the interceptor listener.
            window.removeEventListener(interceptor.name, interceptor.listener, { capture: true });
            if (interceptor.intercepted) {
                // If intercepted, dispatch the event manually so downstream listeners eventually receive it.
                const newEvent = new Event(interceptor.name, interceptor.options);
                window.dispatchEvent(newEvent);

                // TODO(ameshkov): !!! REMOVE THIS LOG
                console.log(`${interceptor.name} event re-dispatched due to ${trigger}.`);
            } else {
                // TODO(ameshkov): !!! REMOVE THIS LOG
                console.log(`Interceptor for ${interceptor.name} removed due to ${trigger}.`);
            }
        });
    };

    // Set a timer to automatically dispatch the events after the timeout.
    const timer = setTimeout(() => {
        dispatchEvents('timeout');
    }, timeout);

    // Return a function to cancel the timer and dispatch events immediately.
    return () => {
        clearTimeout(timer);
        dispatchEvents('response received');
    };
}
