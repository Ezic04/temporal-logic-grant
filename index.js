import katex from 'katex';

class KatexMath extends HTMLElement {
    connectedCallback() {
        const content = this.getAttribute('content') || '';
        const displayMode = this.hasAttribute('display');

        katex.render(content, this, {
            displayMode,
            throwOnError: false,
            macros: {
                "\\f": "#1f(#2)"
            }
        });
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