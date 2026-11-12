#!/usr/bin/env python3
"""Replace text inside a Jira issue description without flattening its structure.

usage: adf_replace.py [--apply] ISSUE-KEY OLD NEW

Reads the description as Atlassian Document Format (ADF), swaps OLD for NEW inside
individual text nodes, and leaves every table, panel, link and mark in place.
Dry run by default: prints each changed node. With --apply: PUTs the result, re-reads
the issue, and exits 0 only when OLD is gone and NEW is present.

Config: server and login come from $JIRA_CONFIG_FILE; the token comes from $JIRA_API_TOKEN.
"""
import base64, json, os, re, sys, urllib.request


def config():
    text = open(os.environ["JIRA_CONFIG_FILE"]).read()
    pick = lambda k: re.search(rf"^{k}:\s*(\S+)", text, re.M).group(1)
    return pick("server").rstrip("/"), pick("login")


def call(method, url, login, body=None):
    auth = base64.b64encode(f"{login}:{os.environ['JIRA_API_TOKEN']}".encode()).decode()
    req = urllib.request.Request(url, method=method, data=body and json.dumps(body).encode())
    req.add_header("Authorization", f"Basic {auth}")
    req.add_header("Content-Type", "application/json")
    with urllib.request.urlopen(req) as r:
        raw = r.read()
    return json.loads(raw) if raw else None


def texts(node):
    if isinstance(node, dict):
        if node.get("type") == "text":
            yield node
        for v in node.values():
            yield from texts(v)
    elif isinstance(node, list):
        for v in node:
            yield from texts(v)


def main(argv):
    apply = "--apply" in argv
    args = [a for a in argv if a != "--apply"]
    if len(args) != 3:
        sys.exit(__doc__)
    key, old, new = args
    server, login = config()
    url = f"{server}/rest/api/3/issue/{key}"
    desc = call("GET", f"{url}?fields=description", login)["fields"]["description"]
    changed = 0
    for node in texts(desc):
        if old in node["text"]:
            node["text"] = node["text"].replace(old, new)
            changed += 1
            print(f"- node: ...{node['text'][:100]}")
    if not changed:
        sys.exit(f"no text node contains {old!r}; the text may span nodes (links, bold). Nothing changed.")
    print(f"{changed} text node(s) would change" if not apply else f"{changed} text node(s) changed")
    if not apply:
        return
    call("PUT", url, login, {"fields": {"description": desc}})
    after = json.dumps(call("GET", f"{url}?fields=description", login)["fields"]["description"])
    if old in after or new not in after:
        sys.exit("verification failed: re-read does not show the replacement")
    print("verified: old text gone, new text present")


main(sys.argv[1:])
