export const katexOptions = ({ displayMode, throwOnError }) => ({
    displayMode,
    throwOnError,
    macros: {
        "\\f": "#1f(#2)"
    }
});
