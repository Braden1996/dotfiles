"use strict";

// Update the two Flow Icons settings without normalising the rest of an
// editor's JSONC file. The licence is accepted only on stdin and is never
// printed, placed in argv, or written to a temporary file outside the target
// directory.

const fs = require("node:fs");
const path = require("node:path");

const LICENSE_SETTING = "flow-icons.licenseKey";
const IGNORED_SETTINGS = "settingsSync.ignoredSettings";

function fail(message) {
  process.stderr.write(`[xx] ${message}\n`);
  process.exit(1);
}

function skipTrivia(text, start) {
  let index = start;
  while (index < text.length) {
    if (/\s/.test(text[index])) {
      index += 1;
      continue;
    }
    if (text[index] === "/" && text[index + 1] === "/") {
      const newline = text.indexOf("\n", index + 2);
      return newline === -1 ? text.length : skipTrivia(text, newline + 1);
    }
    if (text[index] === "/" && text[index + 1] === "*") {
      const end = text.indexOf("*/", index + 2);
      if (end === -1) throw new Error("unterminated block comment");
      index = end + 2;
      continue;
    }
    break;
  }
  return index;
}

function parseString(text, start) {
  if (text[start] !== '"') throw new Error("expected a quoted property name");
  let index = start + 1;
  while (index < text.length) {
    if (text[index] === "\\") {
      index += 2;
      continue;
    }
    if (text[index] === '"') {
      const end = index + 1;
      return { end, value: JSON.parse(text.slice(start, end)) };
    }
    index += 1;
  }
  throw new Error("unterminated string");
}

function skipComposite(text, start) {
  const pairs = { "{": "}", "[": "]" };
  const stack = [pairs[text[start]]];
  let index = start + 1;
  while (index < text.length && stack.length > 0) {
    const char = text[index];
    if (char === '"') {
      index = parseString(text, index).end;
      continue;
    }
    if (char === "/" && text[index + 1] === "/") {
      const newline = text.indexOf("\n", index + 2);
      index = newline === -1 ? text.length : newline + 1;
      continue;
    }
    if (char === "/" && text[index + 1] === "*") {
      const end = text.indexOf("*/", index + 2);
      if (end === -1) throw new Error("unterminated block comment");
      index = end + 2;
      continue;
    }
    if (char === "{" || char === "[") {
      stack.push(pairs[char]);
      index += 1;
      continue;
    }
    if (char === "}" || char === "]") {
      if (stack.at(-1) !== char) throw new Error("mismatched JSON delimiter");
      stack.pop();
      index += 1;
      continue;
    }
    index += 1;
  }
  if (stack.length > 0) throw new Error("unterminated JSON value");
  return index;
}

function parseValueEnd(text, start) {
  if (text[start] === '"') return parseString(text, start).end;
  if (text[start] === "{" || text[start] === "[") {
    return skipComposite(text, start);
  }

  let index = start;
  while (index < text.length) {
    const char = text[index];
    if (
      char === "," ||
      char === "}" ||
      char === "]" ||
      /\s/.test(char) ||
      (char === "/" && (text[index + 1] === "/" || text[index + 1] === "*"))
    ) {
      break;
    }
    index += 1;
  }
  if (index === start) throw new Error("missing JSON value");
  return index;
}

function parseRoot(text) {
  let index = text.charCodeAt(0) === 0xfeff ? 1 : 0;
  index = skipTrivia(text, index);
  if (text[index] !== "{") throw new Error("settings must contain a JSON object");
  const openIndex = index;
  index += 1;
  const properties = [];

  while (index < text.length) {
    index = skipTrivia(text, index);
    if (text[index] === "}") {
      return { openIndex, closeIndex: index, properties };
    }

    const key = parseString(text, index);
    const keyStart = index;
    index = skipTrivia(text, key.end);
    if (text[index] !== ":") throw new Error(`missing colon after ${key.value}`);
    index = skipTrivia(text, index + 1);
    const valueStart = index;
    const valueEnd = parseValueEnd(text, valueStart);
    index = skipTrivia(text, valueEnd);

    let commaIndex = null;
    if (text[index] === ",") {
      commaIndex = index;
      index += 1;
    } else if (text[index] !== "}") {
      throw new Error(`missing comma after ${key.value}`);
    }

    properties.push({
      key: key.value,
      keyStart,
      valueStart,
      valueEnd,
      commaIndex,
    });
  }
  throw new Error("unterminated root object");
}

function lineIndent(text, index) {
  const lineStart = text.lastIndexOf("\n", index - 1) + 1;
  const candidate = text.slice(lineStart, index);
  return /^[\t ]*$/.test(candidate) ? candidate : "  ";
}

function setRootValue(text, key, encodedValue) {
  const root = parseRoot(text);
  const matches = root.properties.filter((property) => property.key === key);
  if (matches.length > 1) {
    throw new Error(`settings contain duplicate ${key} entries`);
  }
  if (matches.length === 1) {
    const property = matches[0];
    return (
      text.slice(0, property.valueStart) +
      encodedValue +
      text.slice(property.valueEnd)
    );
  }

  const newline = text.includes("\r\n") ? "\r\n" : "\n";
  const last = root.properties.at(-1);
  const indent = last ? lineIndent(text, last.keyStart) : "  ";
  const closeLineStart = text.lastIndexOf("\n", root.closeIndex - 1) + 1;
  const closePrefix = text.slice(closeLineStart, root.closeIndex);
  const insertionIndex = /^[\t ]*$/.test(closePrefix)
    ? closeLineStart
    : root.closeIndex;
  const trailingComma = Boolean(last && last.commaIndex !== null);
  const leadingNewline =
    insertionIndex > 0 && !text.slice(0, insertionIndex).endsWith(newline)
      ? newline
      : "";
  const insertion =
    leadingNewline +
    indent +
    `${JSON.stringify(key)}: ${encodedValue}` +
    (trailingComma ? "," : "") +
    newline;

  let withSeparator = text;
  let adjustedInsertionIndex = insertionIndex;
  if (last && last.commaIndex === null) {
    withSeparator =
      text.slice(0, last.valueEnd) + "," + text.slice(last.valueEnd);
    if (last.valueEnd <= insertionIndex) adjustedInsertionIndex += 1;
  }

  return (
    withSeparator.slice(0, adjustedInsertionIndex) +
    insertion +
    withSeparator.slice(adjustedInsertionIndex)
  );
}

function stripJsonc(text) {
  let output = "";
  let index = 0;
  while (index < text.length) {
    if (text[index] === '"') {
      const string = parseString(text, index);
      output += text.slice(index, string.end);
      index = string.end;
      continue;
    }
    if (text[index] === "/" && text[index + 1] === "/") {
      const newline = text.indexOf("\n", index + 2);
      if (newline === -1) break;
      output += "\n";
      index = newline + 1;
      continue;
    }
    if (text[index] === "/" && text[index + 1] === "*") {
      const end = text.indexOf("*/", index + 2);
      if (end === -1) throw new Error("unterminated block comment");
      output += " ";
      index = end + 2;
      continue;
    }
    output += text[index];
    index += 1;
  }
  return output.replace(/,(\s*[}\]])/g, "$1");
}

function ignoredSettings(text) {
  const property = parseRoot(text).properties.find(
    (candidate) => candidate.key === IGNORED_SETTINGS,
  );
  if (!property) return [];
  const value = JSON.parse(
    stripJsonc(text.slice(property.valueStart, property.valueEnd)),
  );
  if (!Array.isArray(value) || value.some((entry) => typeof entry !== "string")) {
    throw new Error(`${IGNORED_SETTINGS} must be an array of strings`);
  }
  return value;
}

function atomicWrite(target, contents) {
  const parent = path.dirname(target);
  fs.mkdirSync(parent, { recursive: true, mode: 0o700 });
  const temporary = path.join(
    parent,
    `.${path.basename(target)}.braden-dots.${process.pid}`,
  );
  let descriptor;
  try {
    descriptor = fs.openSync(temporary, "wx", 0o600);
    fs.writeFileSync(descriptor, contents, "utf8");
    fs.fsyncSync(descriptor);
    fs.closeSync(descriptor);
    descriptor = undefined;
    fs.renameSync(temporary, target);
    fs.chmodSync(target, 0o600);
  } catch (error) {
    if (descriptor !== undefined) fs.closeSync(descriptor);
    try {
      fs.unlinkSync(temporary);
    } catch {
      // Nothing to clean up.
    }
    throw error;
  }
}

if (process.argv.length !== 4 || process.argv[2] !== "set-flow-license") {
  fail("usage: node jsonc-setting.cjs set-flow-license <settings.json>");
}

const target = process.argv[3];
const license = fs.readFileSync(0, "utf8").trim();
if (!license) fail("Flow Icons licence lookup returned no value");
if (license.includes("\0")) fail("Flow Icons licence contains an invalid byte");

try {
  const original = fs.existsSync(target) ? fs.readFileSync(target, "utf8") : "{}\n";
  let updated = setRootValue(original, LICENSE_SETTING, JSON.stringify(license));
  const ignored = ignoredSettings(updated).filter(
    (setting) => setting !== `-${LICENSE_SETTING}`,
  );
  if (!ignored.includes(LICENSE_SETTING)) ignored.push(LICENSE_SETTING);
  updated = setRootValue(updated, IGNORED_SETTINGS, JSON.stringify(ignored));
  atomicWrite(target, updated);
} catch (error) {
  fail(`could not update ${target}: ${error.message}`);
}
