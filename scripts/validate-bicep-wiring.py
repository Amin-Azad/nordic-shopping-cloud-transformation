#!/usr/bin/env python3
"""
Static wiring check for the Bicep tree.

This does NOT replace `az bicep build`. It catches the errors that are easy to
make when templates call shared modules:

  * a module call passing a parameter the target module does not declare
  * a module call omitting a parameter the target module requires
  * a reference to a module output that does not exist
  * a module path that does not resolve on disk

Run it before pushing:  python3 scripts/validate-bicep-wiring.py
"""

from __future__ import annotations

import os
import re
import sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "infra", "bicep")
ROOT = os.path.normpath(ROOT)

PARAM_RE = re.compile(r"^param\s+(\w+)\s+([^\n=]+?)(\s*=\s*(.*))?$", re.M)
OUTPUT_RE = re.compile(r"^output\s+(\w+)\s+", re.M)
MODULE_RE = re.compile(r"^module\s+(\w+)\s+'([^']+)'\s*=", re.M)


def strip_comments(text: str) -> str:
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
    out = []
    for line in text.splitlines():
        # Leave '//' alone when it sits inside a quoted string (URLs, resource IDs).
        if "//" in line:
            quote = None
            cut = None
            i = 0
            while i < len(line):
                ch = line[i]
                if quote:
                    if ch == quote:
                        quote = None
                elif ch in "'\"":
                    quote = ch
                elif ch == "/" and i + 1 < len(line) and line[i + 1] == "/":
                    cut = i
                    break
                i += 1
            if cut is not None:
                line = line[:cut]
        out.append(line)
    return "\n".join(out)


ALLOWED_RE = re.compile(r"@allowed\(\s*\[(.*?)\]\s*\)", re.S)


def allowed_values_before(src: str, param_offset: int):
    """Collect @allowed values attached to the param declared at param_offset."""
    head = src[:param_offset]
    tail = head.rstrip()
    if not tail.endswith(")"):
        return None
    match = None
    for m in ALLOWED_RE.finditer(head):
        if m.end() >= len(tail) - 1:
            match = m
    if not match:
        return None
    body = match.group(1)
    values = re.findall(r"'([^']*)'", body)
    if values:
        return set(values)
    numbers = re.findall(r"-?\d+", body)
    return set(numbers) if numbers else None


def parse_file(path: str) -> dict:
    raw = open(path, encoding="utf-8").read()
    src = strip_comments(raw)
    params, required, types, allowed = {}, set(), {}, {}
    for m in re.finditer(r"^param\s+(\w+)\s+([^\n=]+?)(\s*=\s*(.*))?$", src, re.M):
        name, ptype, has_default, _ = m.groups()
        ptype = ptype.strip()
        params[name] = ptype
        types[name] = ptype
        if not has_default:
            required.add(name)
        # union types such as 'dev' | 'test' | 'prod' are allow-lists too
        if "|" in ptype and "'" in ptype:
            allowed[name] = set(re.findall(r"'([^']*)'", ptype))
        else:
            vals = allowed_values_before(src, m.start())
            if vals:
                allowed[name] = vals
    return {
        "path": path,
        "src": src,
        "params": params,
        "required": required,
        "types": types,
        "allowed": allowed,
        "outputs": set(OUTPUT_RE.findall(src)),
    }


def literal_value(block: str, key_offset: int):
    """
    Return (kind, value) for a literal argument, or None when the value is an
    expression, a symbol reference, or anything else not statically knowable.
    """
    rest = block[key_offset:]
    colon = rest.find(":")
    if colon == -1:
        return None
    value = rest[colon + 1:]
    line = value.split("\n", 1)[0].strip()

    if not line:
        return None
    if line.startswith("'") and line.endswith("'") and line.count("'") == 2:
        return ("string", line[1:-1])
    if line in ("true", "false"):
        return ("bool", line == "true")
    if re.fullmatch(r"-?\d+", line):
        return ("int", int(line))
    if line.startswith("["):
        return ("array", None)
    if line.startswith("{"):
        return ("object", None)
    return None


def block_after(src: str, start: int) -> tuple[str, int]:
    """Return the balanced { ... } block beginning at or after `start`."""
    open_at = src.find("{", start)
    if open_at == -1:
        return "", start
    depth, i, quote = 0, open_at, None
    while i < len(src):
        ch = src[i]
        if quote:
            if ch == quote:
                quote = None
        elif ch in "'\"":
            quote = ch
        elif ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0:
                return src[open_at : i + 1], i + 1
        i += 1
    return src[open_at:], len(src)


def top_level_keys(block: str) -> dict[str, int]:
    """Keys at depth 1 of a { ... } block, mapped to their offset."""
    keys, depth, i, quote = {}, 0, 0, None
    line_start = True
    while i < len(block):
        ch = block[i]
        if quote:
            if ch == quote:
                quote = None
            i += 1
            continue
        if ch in "'\"":
            quote = ch
            i += 1
            continue
        if ch in "{[":
            depth += 1
        elif ch in "}]":
            depth -= 1
        elif depth == 1 and line_start and not ch.isspace():
            m = re.match(r"([A-Za-z_]\w*)\s*:", block[i:])
            if m:
                keys[m.group(1)] = i
                i += m.end()
                line_start = False
                continue
        if ch == "\n":
            line_start = True
        elif not ch.isspace():
            line_start = False
        i += 1
    return keys


def main() -> int:
    files = {}
    for dirpath, _dirs, names in os.walk(ROOT):
        for n in names:
            if n.endswith(".bicep"):
                p = os.path.join(dirpath, n)
                files[os.path.normpath(p)] = parse_file(p)

    errors, warnings, checked = [], [], 0

    for path, info in sorted(files.items()):
        src = info["src"]
        rel = os.path.relpath(path, ROOT)
        symbols = {}

        for m in MODULE_RE.finditer(src):
            symbol, modpath = m.group(1), m.group(2)
            target = os.path.normpath(os.path.join(os.path.dirname(path), modpath))
            if target not in files:
                errors.append(f"{rel}: module '{symbol}' points at missing file {modpath}")
                continue
            symbols[symbol] = files[target]
            tgt = files[target]
            trel = os.path.relpath(target, ROOT)

            body, _ = block_after(src, m.end())
            keys = top_level_keys(body)
            if "params" not in keys:
                if tgt["required"]:
                    errors.append(
                        f"{rel}: module '{symbol}' has no params block but {trel} "
                        f"requires {sorted(tgt['required'])}"
                    )
                continue

            params_block, _ = block_after(body, keys["params"])
            passed = set(top_level_keys(params_block))
            checked += 1

            unknown = passed - set(tgt["params"])
            if unknown:
                errors.append(
                    f"{rel}: module '{symbol}' passes parameter(s) {sorted(unknown)} "
                    f"not declared in {trel}"
                )

            missing = tgt["required"] - passed
            if missing:
                errors.append(
                    f"{rel}: module '{symbol}' omits required parameter(s) "
                    f"{sorted(missing)} of {trel}"
                )

            # Literal values only: anything referencing another symbol is skipped,
            # because its value is not knowable without compiling.
            keys_in_params = top_level_keys(params_block)
            for pname, offset in keys_in_params.items():
                if pname not in tgt["params"]:
                    continue
                literal = literal_value(params_block, offset)
                if literal is None:
                    continue
                declared = tgt["types"].get(pname, "")
                kind, value = literal

                if declared in ("string", "int", "bool", "array", "object"):
                    if kind != declared:
                        errors.append(
                            f"{rel}: module '{symbol}' passes {kind} to "
                            f"'{pname}' but {trel} declares it {declared}"
                        )
                        continue

                allowed = tgt["allowed"].get(pname)
                if allowed and kind == "string" and value not in allowed:
                    errors.append(
                        f"{rel}: module '{symbol}' passes '{value}' to '{pname}' "
                        f"but {trel} allows only {sorted(allowed)}"
                    )

        for ref in re.finditer(r"\b(\w+)!?\.outputs\.(\w+)", src):
            sym, out = ref.group(1), ref.group(2)
            if sym in symbols and out not in symbols[sym]["outputs"]:
                trel = os.path.relpath(symbols[sym]["path"], ROOT)
                errors.append(f"{rel}: '{sym}.outputs.{out}' is not an output of {trel}")

        for ref in re.finditer(r"\b(\w+)\.outputs\.", src):
            sym = ref.group(1)
            if sym in symbols:
                decl = re.search(
                    r"^module\s+" + sym + r"\s+'[^']+'\s*=\s*if\s*\(", src, re.M
                )
                if decl and f"{sym}!." not in src:
                    warnings.append(
                        f"{rel}: '{sym}' is a conditional module but is dereferenced "
                        f"without '!'; confirm every use is guarded"
                    )
                    break

    # ---- parameter files must match the template they target ----
    param_files = 0
    for dirpath, _dirs, names in os.walk(ROOT):
        for n in names:
            if not n.endswith(".bicepparam"):
                continue
            pf = os.path.join(dirpath, n)
            prel = os.path.relpath(pf, ROOT)
            text = strip_comments(open(pf, encoding="utf-8").read())
            using = re.search(r"^using\s+'([^']+)'", text, re.M)
            if not using:
                errors.append(f"{prel}: no using statement")
                continue
            target = os.path.normpath(os.path.join(os.path.dirname(pf), using.group(1)))
            if target not in files:
                errors.append(f"{prel}: using points at missing file {using.group(1)}")
                continue
            tgt = files[target]
            trel = os.path.relpath(target, ROOT)
            assigned = set(re.findall(r"^param\s+(\w+)\s*=", text, re.M))
            param_files += 1

            orphan = assigned - set(tgt["params"])
            if orphan:
                errors.append(
                    f"{prel}: assigns parameter(s) {sorted(orphan)} "
                    f"not declared in {trel}"
                )
            unset = tgt["required"] - assigned
            if unset:
                errors.append(
                    f"{prel}: leaves required parameter(s) {sorted(unset)} "
                    f"of {trel} unset"
                )

    print(
        f"Parsed {len(files)} Bicep files, checked {checked} module calls "
        f"and {param_files} parameter files.\n"
    )
    for w in sorted(set(warnings)):
        print(f"WARN  {w}")
    for e in errors:
        print(f"ERROR {e}")

    if errors:
        print(f"\n{len(errors)} wiring error(s). Fix these before running az bicep build.")
        return 1
    print("\nNo wiring errors found.")
    print("This is a static check only. Still run: az bicep build --file infra/bicep/main.minimal.bicep")
    return 0


if __name__ == "__main__":
    sys.exit(main())
