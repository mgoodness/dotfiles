---
name: jira
description: >
  Jira tickets in the OZZI project: read, search, create, comment, move, add to a sprint, or change
  description text.
---

# Jira (OZZI)

Assign new tickets to `michael.goodness@mlb.com` and add them to the active sprint. Every case below
ends on a check you run.

## Read or search

```sh
jira issue view OZZI-123 --plain --comments 5
jira issue list -q 'project = OZZI AND sprint in openSprints()' --plain --no-headers --columns key,status,summary
```

Done when every ticket the task names appears with its state.

## Create

Write the body to a Markdown file, then:

```sh
KEY=$(jira issue create -t Task -s "<summary>" -a michael.goodness@mlb.com -T body.md --no-input --raw | jq -r .key)
```

Then add it to the active sprint (Sprint). Done when `jira issue view "$KEY" --plain` shows the summary,
assignee and sprint.

## Comment

```sh
jira issue comment add OZZI-123 -T comment.md --no-input
```

Done when `jira issue view OZZI-123 --plain --comments 1` shows it.

## Move

```sh
jira issue move OZZI-123 "In Progress" --comment "<why>"
```

Done when `view` shows the new state.

## Sprint

```sh
SPRINT=$(jira sprint list --state active --plain --no-headers --columns id | head -1)
jira sprint add "$SPRINT" OZZI-123
jira sprint close "$SPRINT"
```

Done when `view` shows the sprint. Creating or starting a sprint goes through the Jira UI.

## Change description text

An existing description holds rich text (tables, panels, links). Change it with the helper in this skill's
`scripts/` folder, which edits text nodes in place and leaves the structure intact:

```sh
scripts/adf_replace.py OZZI-123 "old text" "new text"            # dry run: lists each node it would change
scripts/adf_replace.py --apply OZZI-123 "old text" "new text"    # PUT, re-read, verify
```

Confirm the dry run lists exactly the nodes you meant, then apply. Done when `--apply` prints
`verified: old text gone, new text present`. Text that spans nodes (a link or bold run inside it) reports
no match; edit each piece on its own.
