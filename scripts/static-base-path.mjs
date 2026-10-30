import { readdirSync, readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import katex from "katex";
import { katexOptions } from "../katex-options.js";

const [baseArg] = process.argv.slice(2);
if (!baseArg) {
    throw new Error("usage: static-base-path.mjs /base-path");
}
const basePath = baseArg.replace(/\/+$/, "");

const decodeEntities = (text) =>
    text
        .replaceAll("&lt;", "<")
        .replaceAll("&gt;", ">")
        .replaceAll("&quot;", '"')
        .replaceAll("&#39;", "'")
        .replaceAll("&amp;", "&");

const attribute = (attributes, name) =>
    attributes.match(new RegExp(`\\b${name}="([^"]*)"`))?.[1];

const renderMath = (html) =>
    html.replace(
        /<katex-math((?:\s+[\w-]+="[^"]*")*)\s*><\/katex-math>/g,
        (_, attributes) =>
            katex.renderToString(
                decodeEntities(attribute(attributes, "content") ?? ""),
                katexOptions({
                    displayMode: attribute(attributes, "display") !== undefined,
                    throwOnError: true,
                })
            )
    );

const stripScripts = (html) =>
    html
        .replace(/<script\b[^>]*>[\s\S]*?<\/script>/g, "")
        .replace(/<link rel="(?:module)?preload"[^>]*>/g, "");

const prefixLinks = (html) =>
    html.replace(/\b(href|src)="\/+/g, `$1="${basePath}/`);

const prefixCssUrls = (css) =>
    css.replace(/url\((["']?)\/+/g, `url($1${basePath}/`);

const transformers = [
    [".html", (html) => prefixLinks(renderMath(stripScripts(html)))],
    [".css", prefixCssUrls],
];

readdirSync("dist", { recursive: true, withFileTypes: true })
    .filter((entry) => entry.isFile())
    .forEach((entry) => {
        const transformer = transformers.find(([extension]) => entry.name.endsWith(extension));
        if (transformer) {
            const path = join(entry.parentPath, entry.name);
            try {
                writeFileSync(path, transformer[1](readFileSync(path, "utf8")));
            } catch (error) {
                throw new Error(`${path}: ${error.message}`, { cause: error });
            }
        }
    });
