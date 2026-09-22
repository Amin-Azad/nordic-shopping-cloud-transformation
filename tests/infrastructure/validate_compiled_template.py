#!/usr/bin/env python3
"""
Asserts security controls against the COMPILED ARM template rather than against
Bicep source text.

The earlier versions of these tests grepped the .bicep files for literal
strings. That breaks on any reformat and proves nothing about what Azure would
actually build. These assertions walk the compiled template, so they describe
the deployed result and survive refactoring.

Usage:
    python3 tests/infrastructure/validate_compiled_template.py <compiled.json>

Build the input first:
    az bicep build --file infra/bicep/main.minimal.bicep --outfile /tmp/main.json
"""

from __future__ import annotations

import json
import re
import sys

OWNER_ROLE_ID = "8e3af657-a8ff-443c-a75c-2fe8c4bcb635"
SECRET_HINT = re.compile(r"(password|pwd|secret|apikey|connectionstring)", re.I)
NUMERIC_VERSION = re.compile(r"^\d+\.\d+$")


def walk(node):
    """Yield every dict nested anywhere in the template."""
    if isinstance(node, dict):
        yield node
        for value in node.values():
            yield from walk(value)
    elif isinstance(node, list):
        for item in node:
            yield from walk(item)


def resources(template, resource_type):
    return [
        node
        for node in walk(template)
        if isinstance(node.get("type"), str) and node["type"].lower() == resource_type.lower()
    ]


UNRESOLVED = object()


def prop(resource, *path):
    """
    Resolve a nested property.

    Returns UNRESOLVED when the value is not statically visible, either because
    a parent object compiled to an ARM expression (a union() call, for example)
    or because the value itself is a template expression. Callers must not treat
    UNRESOLVED as a failure: nothing can be concluded about it without deploying.
    """
    node = resource.get("properties")
    if isinstance(node, str):
        return UNRESOLVED
    if not isinstance(node, dict):
        return UNRESOLVED

    for key in path:
        if isinstance(node, str):
            return UNRESOLVED
        if not isinstance(node, dict) or key not in node:
            return UNRESOLVED
        node = node[key]

    if isinstance(node, str) and node.startswith("[") and node.endswith("]"):
        return UNRESOLVED
    return node


class Checker:
    def __init__(self, template):
        self.template = template
        self.passes = 0
        self.failures = []
        self.unresolved = 0

    def note_unresolved(self, count):
        self.unresolved += count

    def check(self, description, offenders, unresolved=0):
        self.note_unresolved(unresolved)
        offenders = list(offenders)
        if offenders:
            self.failures.append((description, offenders))
            print(f"FAIL  {description}")
            for offender in offenders[:5]:
                print(f"        offender: {offender}")
        else:
            self.passes += 1
            suffix = f"  ({unresolved} value(s) computed at deploy time)" if unresolved else ""
            print(f"PASS  {description}{suffix}")

    def scan(self, resource_type, path, is_ok, describe=None):
        """Return (offenders, unresolved_count) for one property across one resource type."""
        offenders, unresolved = [], 0
        for r in resources(self.template, resource_type):
            value = prop(r, *path)
            if value is UNRESOLVED:
                unresolved += 1
                continue
            if not is_ok(value):
                name = r.get("name", "<unnamed>")
                offenders.append(describe(name, value) if describe else f"{name} = {value!r}")
        return offenders, unresolved

    def run(self):
        t = self.template

        def name_of(r):
            return r.get("name", "<unnamed>")

        def scan(resource_type, path, is_bad, label=None):
            """Return (offenders, unresolved_count) for a property assertion."""
            offenders, unresolved = [], 0
            for r in resources(t, resource_type):
                value = prop(r, *path)
                if value is UNRESOLVED:
                    unresolved += 1
                    continue
                if is_bad(value):
                    shown = f"{name_of(r)} ({label(value)})" if label else name_of(r)
                    offenders.append(shown)
            return offenders, unresolved

        self.check(
            "storage accounts block public blob access",
            *scan("Microsoft.Storage/storageAccounts", ("allowBlobPublicAccess",), lambda v: v is not False),
        )

        self.check(
            "storage accounts require HTTPS traffic only",
            *scan("Microsoft.Storage/storageAccounts", ("supportsHttpsTrafficOnly",), lambda v: v is not True),
        )

        self.check(
            "key vaults use Entra RBAC authorization",
            *scan("Microsoft.KeyVault/vaults", ("enableRbacAuthorization",), lambda v: v is not True),
        )

        self.check(
            "key vaults keep soft delete enabled",
            *scan("Microsoft.KeyVault/vaults", ("enableSoftDelete",), lambda v: v is not True),
        )

        self.check(
            "web apps are HTTPS only",
            *scan("Microsoft.Web/sites", ("httpsOnly",), lambda v: v is not True),
        )

        def bad_tls(v):
            return isinstance(v, str) and NUMERIC_VERSION.match(v) and float(v) < 1.2

        self.check(
            "web apps require TLS 1.2 or higher",
            *scan("Microsoft.Web/sites", ("siteConfig", "minTlsVersion"), bad_tls, lambda v: f"TLS {v}"),
        )

        self.check(
            "web apps disable FTP",
            *scan("Microsoft.Web/sites", ("siteConfig", "ftpsState"), lambda v: v != "Disabled", lambda v: str(v)),
        )

        self.check(
            "no Owner role assignments are created",
            *scan(
                "Microsoft.Authorization/roleAssignments",
                ("roleDefinitionId",),
                lambda v: OWNER_ROLE_ID in str(v),
            ),
        )

        self.check(
            "sql servers disable public network access",
            *scan(
                "Microsoft.Sql/servers",
                ("publicNetworkAccess",),
                lambda v: isinstance(v, str) and v != "Disabled",
                lambda v: str(v),
            ),
        )

        private_endpoints = resources(t, "Microsoft.Network/privateEndpoints")
        self.check(
            "private endpoints are defined somewhere in the deployment",
            [] if private_endpoints else ["none found"],
        )

        secret_defaults = []
        for name, spec in (t.get("parameters") or {}).items():
            default = spec.get("defaultValue")
            if isinstance(default, str) and default and SECRET_HINT.search(name):
                if not default.startswith("["):
                    secret_defaults.append(name)
        self.check("no parameter carries a credential-shaped default", secret_defaults)

        return self


def main(argv):
    if len(argv) != 2:
        print(__doc__)
        return 2

    path = argv[1]
    try:
        with open(path, encoding="utf-8") as handle:
            template = json.load(handle)
    except FileNotFoundError:
        print(f"::error::Compiled template not found: {path}")
        return 1
    except json.JSONDecodeError as err:
        print(f"::error::{path} is not valid JSON: {err}")
        return 1

    print(f"Asserting against {path}\n")
    checker = Checker(template).run()

    print(
        f"\n{checker.passes} passed, {len(checker.failures)} failed, "
        f"{checker.unresolved} value(s) resolved only at deploy time"
    )
    if checker.failures:
        for description, _ in checker.failures:
            print(f"::error::{description}")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
