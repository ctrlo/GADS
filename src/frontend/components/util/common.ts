type EventOrJQueryEvent = Event | JQuery.Event;

export const stopPropagation = (e: EventOrJQueryEvent) => {
    e.stopPropagation();
    e.preventDefault();
}
