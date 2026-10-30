import katex from 'katex';
import { katexOptions } from './katex-options.js';

class KatexMath extends HTMLElement {
    connectedCallback() {
        const content = this.getAttribute('content') || '';
        const displayMode = this.hasAttribute('display');

        katex.render(content, this, katexOptions({ displayMode, throwOnError: false }));
    }
}

customElements.define('katex-math', KatexMath);

export default {
    load: async function (elmLoaded) {
        await elmLoaded;
    },
    flags: function () {
        return "";
    }
};
