function createElement(type: 'button', definition: object): JQuery<HTMLButtonElement>
function createElement(type: 'div', definition: object): JQuery<HTMLDivElement>
function createElement(type: 'input', definition: object): JQuery<HTMLInputElement>
function createElement(type: 'button' | 'div' | 'input', definition: object): JQuery<HTMLButtonElement | HTMLDivElement | HTMLInputElement> {
  const el = document.createElement(type);
  for (const c in definition) {
    if (Array.isArray(definition[c]) && el[c].add) {
      el[c].add(...definition[c]);
    } else {
      el[c] = definition[c];
    }
  }
  return $(el);
}

export {createElement}