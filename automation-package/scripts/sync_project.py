#!/usr/bin/env python3
"""Idempotent GitHub repository and Projects v2 synchronizer."""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
from dataclasses import dataclass
from datetime import date
from pathlib import Path
from typing import Any, Iterable


class SyncError(RuntimeError):
    """Raised when synchronization cannot continue safely."""


@dataclass
class CommandResult:
    stdout: str
    stderr: str
    returncode: int


class Runner:
    def __init__(self, verbose: bool = False) -> None:
        self.verbose = verbose

    def run(self, args: list[str], *, check: bool = True, input_text: str | None = None) -> CommandResult:
        if self.verbose:
            print("+ " + " ".join(args), file=sys.stderr)
        completed = subprocess.run(
            args,
            input=input_text,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )
        result = CommandResult(completed.stdout.strip(), completed.stderr.strip(), completed.returncode)
        if check and result.returncode != 0:
            detail = result.stderr or result.stdout or "command returned no diagnostic"
            raise SyncError(f"Command failed ({result.returncode}): {' '.join(args)}\n{detail}")
        return result

    def json(self, args: list[str], *, check: bool = True) -> Any:
        result = self.run(args, check=check)
        if result.returncode != 0:
            return None
        try:
            return json.loads(result.stdout or "null")
        except json.JSONDecodeError as exc:
            raise SyncError(f"Invalid JSON from {' '.join(args)}: {exc}") from exc


FIELD_TYPENAMES = {
    "ProjectV2SingleSelectField": "SINGLE_SELECT",
    "ProjectV2Field": None,
    "ProjectV2IterationField": "ITERATION",
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config", default="planning/project.json", help="Source-of-truth JSON file")
    parser.add_argument("--dry-run", action="store_true", help="Validate and print planned operations without GitHub calls")
    parser.add_argument("--limit", type=int, default=None, help="Process at most N issues")
    parser.add_argument("--resume", action="store_true", help="Skip issue keys recorded in the state file")
    parser.add_argument("--resume-from", help="Begin at the specified issue key")
    parser.add_argument("--state-file", default=".sync-state.json", help="Progress file used for resumable execution")
    parser.add_argument("--verbose", action="store_true", help="Print external commands")
    return parser.parse_args()


def unique(items: Iterable[str], label: str) -> None:
    seen: set[str] = set()
    duplicates: set[str] = set()
    for item in items:
        if item in seen:
            duplicates.add(item)
        seen.add(item)
    if duplicates:
        raise SyncError(f"Duplicate {label}: {', '.join(sorted(duplicates))}")


def valid_iso_date(value: str, context: str) -> None:
    try:
        date.fromisoformat(value)
    except ValueError as exc:
        raise SyncError(f"Invalid date for {context}: {value}") from exc


def validate(config: dict[str, Any]) -> None:
    required = ["owner", "repository", "project", "fields", "labels", "milestones", "issues"]
    missing = [key for key in required if key not in config]
    if missing:
        raise SyncError(f"Missing top-level keys: {', '.join(missing)}")

    unique((field["name"] for field in config["fields"]), "field names")
    unique((label["name"] for label in config["labels"]), "label names")
    unique((m["title"] for m in config["milestones"]), "milestone titles")
    unique((issue["key"] for issue in config["issues"]), "issue keys")
    unique((issue["title"] for issue in config["issues"]), "issue titles")

    fields = {field["name"]: field for field in config["fields"]}
    labels = {label["name"] for label in config["labels"]}
    milestones = {m["title"] for m in config["milestones"]}

    for field in config["fields"]:
        field_type = field["type"]
        if field_type not in {"SINGLE_SELECT", "TEXT", "NUMBER", "DATE"}:
            raise SyncError(f"Unsupported field type {field_type!r} for {field['name']}")
        if field_type == "SINGLE_SELECT":
            options = field.get("options", [])
            if not options:
                raise SyncError(f"Single-select field {field['name']} has no options")
            unique(options, f"options in field {field['name']}")

    for milestone in config["milestones"]:
        due_on = milestone.get("due_on", "")
        if not re.fullmatch(r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z", due_on):
            raise SyncError(f"Milestone {milestone['title']} has invalid due_on: {due_on}")
        valid_iso_date(due_on[:10], milestone["title"])

    for issue in config["issues"]:
        if not re.fullmatch(r"[A-Z][A-Z0-9]+-\d{3,}", issue["key"]):
            raise SyncError(f"Invalid issue key: {issue['key']}")
        if issue["milestone"] not in milestones:
            raise SyncError(f"Issue {issue['key']} references unknown milestone: {issue['milestone']}")
        unknown_labels = set(issue.get("labels", [])) - labels
        if unknown_labels:
            raise SyncError(f"Issue {issue['key']} references unknown labels: {sorted(unknown_labels)}")
        for field_name, value in issue.get("fields", {}).items():
            if field_name not in fields:
                raise SyncError(f"Issue {issue['key']} references unknown field: {field_name}")
            spec = fields[field_name]
            if spec["type"] == "SINGLE_SELECT" and value not in spec["options"]:
                raise SyncError(f"Issue {issue['key']} has invalid option {value!r} for {field_name}")
            if spec["type"] == "NUMBER" and not isinstance(value, (int, float)):
                raise SyncError(f"Issue {issue['key']} requires a numeric value for {field_name}")
            if spec["type"] == "DATE":
                valid_iso_date(str(value), f"{issue['key']} {field_name}")
            if spec["type"] == "TEXT" and not isinstance(value, str):
                raise SyncError(f"Issue {issue['key']} requires text for {field_name}")


def load_json(path: Path) -> dict[str, Any]:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as exc:
        raise SyncError(f"Configuration file not found: {path}") from exc
    except json.JSONDecodeError as exc:
        raise SyncError(f"Invalid JSON in {path}: {exc}") from exc
    if not isinstance(data, dict):
        raise SyncError("The configuration root must be an object.")
    return data


def print_dry_run(config: dict[str, Any], issues: list[dict[str, Any]]) -> None:
    repo = f"{config['owner']}/{config['repository']['name']}"
    print("DRY RUN: no GitHub commands will be executed")
    print(f"Repository: {repo}")
    print(f"Project: {config['project']['title']}")
    print(f"Labels: {len(config['labels'])}")
    print(f"Milestones: {len(config['milestones'])}")
    print(f"Fields: {len(config['fields'])}")
    print(f"Issues selected: {len(issues)}")
    for issue in issues:
        print(f"- {issue['key']}: {issue['title']} -> {issue['milestone']}")


def gh_exists() -> bool:
    return shutil.which("gh") is not None


def ensure_auth(runner: Runner) -> None:
    runner.run(["gh", "auth", "status"])
    if not os.environ.get("GH_TOKEN"):
        print("Requesting GitHub Projects OAuth scope...", file=sys.stderr)
        runner.run(["gh", "auth", "refresh", "-h", "github.com", "-s", "project"])


def repo_slug(config: dict[str, Any]) -> str:
    return f"{config['owner']}/{config['repository']['name']}"


def ensure_repository(runner: Runner, config: dict[str, Any]) -> None:
    slug = repo_slug(config)
    exists = runner.run(["gh", "repo", "view", slug, "--json", "nameWithOwner"], check=False)
    if exists.returncode != 0:
        visibility = config["repository"].get("visibility", "public")
        runner.run([
            "gh", "repo", "create", slug,
            f"--{visibility}",
            "--description", config["repository"]["description"],
            "--disable-wiki",
        ])
    edit_cmd = [
        "gh", "repo", "edit", slug,
        "--description", config["repository"]["description"],
        "--enable-issues=true",
        "--enable-wiki=false",
    ]
    homepage = config["repository"].get("homepage")
    if homepage:
        edit_cmd += ["--homepage", homepage]
    topics = config["repository"].get("topics", [])
    for topic in topics:
        edit_cmd += ["--add-topic", topic]
    runner.run(edit_cmd)


def ensure_labels(runner: Runner, config: dict[str, Any]) -> None:
    slug = repo_slug(config)
    existing = runner.json([
        "gh", "api", "--method", "GET", f"repos/{slug}/labels", "-f", "per_page=100"
    ]) or []
    by_name = {item["name"]: item for item in existing}
    for label in config["labels"]:
        if label["name"] in by_name:
            runner.run([
                "gh", "api", "--method", "PATCH",
                f"repos/{slug}/labels/{label['name']}",
                "-f", f"new_name={label['name']}",
                "-f", f"color={label['color']}",
                "-f", f"description={label.get('description', '')}",
            ])
        else:
            runner.run([
                "gh", "api", "--method", "POST", f"repos/{slug}/labels",
                "-f", f"name={label['name']}",
                "-f", f"color={label['color']}",
                "-f", f"description={label.get('description', '')}",
            ])


def ensure_milestones(runner: Runner, config: dict[str, Any]) -> dict[str, int]:
    slug = repo_slug(config)
    existing = runner.json([
        "gh", "api", "--method", "GET", f"repos/{slug}/milestones",
        "-f", "state=all", "-f", "per_page=100",
    ]) or []
    by_title = {item["title"]: item for item in existing}
    result: dict[str, int] = {}
    for milestone in config["milestones"]:
        fields = [
            "-f", f"title={milestone['title']}",
            "-f", f"description={milestone.get('description', '')}",
            "-f", f"due_on={milestone['due_on']}",
            "-f", "state=open",
        ]
        if milestone["title"] in by_title:
            number = by_title[milestone["title"]]["number"]
            runner.run(["gh", "api", "--method", "PATCH", f"repos/{slug}/milestones/{number}", *fields])
            result[milestone["title"]] = number
        else:
            created = runner.json(["gh", "api", "--method", "POST", f"repos/{slug}/milestones", *fields])
            result[milestone["title"]] = int(created["number"])
    return result


def list_payload(payload: Any, key: str) -> list[dict[str, Any]]:
    if isinstance(payload, list):
        return payload
    if isinstance(payload, dict):
        value = payload.get(key, [])
        if isinstance(value, list):
            return value
    return []


def ensure_project(runner: Runner, config: dict[str, Any]) -> tuple[str, int]:
    owner = config["owner"]
    title = config["project"]["title"]
    payload = runner.json(["gh", "project", "list", "--owner", owner, "--limit", "100", "--format", "json"]) or {}
    projects = list_payload(payload, "projects")
    found = next((p for p in projects if p.get("title") == title), None)
    if found is None:
        found = runner.json(["gh", "project", "create", "--owner", owner, "--title", title, "--format", "json"])
    project_id = found.get("id")
    number = int(found.get("number"))
    if not project_id:
        details = runner.json(["gh", "project", "view", str(number), "--owner", owner, "--format", "json"])
        project_id = details["id"]
    runner.run([
        "gh", "project", "edit", str(number), "--owner", owner,
        "--title", title,
        "--description", config["project"].get("short_description", ""),
        "--readme", config["project"].get("readme", ""),
        "--visibility", "PUBLIC",
    ])
    return project_id, number


def normalize_field(raw: dict[str, Any]) -> dict[str, Any]:
    type_name = raw.get("type") or raw.get("__typename")
    normalized = FIELD_TYPENAMES.get(type_name, type_name)
    if normalized is None:
        data_type = raw.get("dataType") or raw.get("data_type")
        normalized = str(data_type).upper() if data_type else "TEXT"
    return {
        "id": raw["id"],
        "name": raw["name"],
        "type": normalized,
        "options": raw.get("options", []),
    }


def ensure_fields(runner: Runner, config: dict[str, Any], project_number: int) -> dict[str, dict[str, Any]]:
    owner = config["owner"]
    payload = runner.json([
        "gh", "project", "field-list", str(project_number), "--owner", owner,
        "--limit", "100", "--format", "json",
    ]) or {}
    raw_fields = list_payload(payload, "fields")
    current = {f["name"]: normalize_field(f) for f in raw_fields}

    for spec in config["fields"]:
        if spec["name"] not in current:
            cmd = [
                "gh", "project", "field-create", str(project_number),
                "--owner", owner,
                "--name", spec["name"],
                "--data-type", spec["type"],
                "--format", "json",
            ]
            if spec["type"] == "SINGLE_SELECT":
                cmd += ["--single-select-options", ",".join(spec["options"])]
            created = runner.json(cmd)
            current[spec["name"]] = normalize_field(created)

    payload = runner.json([
        "gh", "project", "field-list", str(project_number), "--owner", owner,
        "--limit", "100", "--format", "json",
    ]) or {}
    raw_fields = list_payload(payload, "fields")
    result = {f["name"]: normalize_field(f) for f in raw_fields}
    expected_types = {spec["name"]: spec["type"] for spec in config["fields"]}
    for name, field in result.items():
        if name in expected_types:
            field["type"] = expected_types[name]
    return result


def existing_issues(runner: Runner, config: dict[str, Any]) -> dict[str, dict[str, Any]]:
    slug = repo_slug(config)
    payload = runner.json([
        "gh", "issue", "list", "--repo", slug, "--state", "all", "--limit", "1000",
        "--json", "number,title,url",
    ]) or []
    result: dict[str, dict[str, Any]] = {}
    for item in payload:
        match = re.match(r"^\[([A-Z][A-Z0-9]+-\d{3,})\]", item["title"])
        if match:
            result[match.group(1)] = item
    return result


def sync_issue(runner: Runner, config: dict[str, Any], issue: dict[str, Any], existing: dict[str, dict[str, Any]]) -> dict[str, Any]:
    slug = repo_slug(config)
    title = f"[{issue['key']}] {issue['title']}"
    label_arg = ",".join(issue.get("labels", []))
    if issue["key"] in existing:
        item = existing[issue["key"]]
        cmd = [
            "gh", "issue", "edit", str(item["number"]), "--repo", slug,
            "--title", title, "--body", issue["body"], "--milestone", issue["milestone"],
        ]
        if label_arg:
            cmd += ["--add-label", label_arg]
        runner.run(cmd)
        return item

    cmd = [
        "gh", "issue", "create", "--repo", slug,
        "--title", title, "--body", issue["body"], "--milestone", issue["milestone"],
    ]
    if label_arg:
        cmd += ["--label", label_arg]
    created = runner.run(cmd)
    url = created.stdout.splitlines()[-1].strip()
    if not url.startswith("https://"):
        raise SyncError(f"Unable to determine URL for created issue {issue['key']}: {created.stdout}")
    number = int(url.rstrip("/").split("/")[-1])
    item = {"number": number, "title": title, "url": url}
    existing[issue["key"]] = item
    return item


def project_items(runner: Runner, config: dict[str, Any], project_number: int) -> dict[str, str]:
    payload = runner.json([
        "gh", "project", "item-list", str(project_number), "--owner", config["owner"],
        "--limit", "1000", "--format", "json",
    ]) or {}
    items = list_payload(payload, "items")
    result: dict[str, str] = {}
    for item in items:
        content = item.get("content") or {}
        url = content.get("url")
        if url:
            result[url] = item["id"]
    return result


def ensure_project_item(runner: Runner, config: dict[str, Any], project_number: int, issue_url: str, existing_items: dict[str, str]) -> str:
    if issue_url in existing_items:
        return existing_items[issue_url]
    created = runner.json([
        "gh", "project", "item-add", str(project_number), "--owner", config["owner"],
        "--url", issue_url, "--format", "json",
    ])
    item_id = created["id"]
    existing_items[issue_url] = item_id
    return item_id


def option_id(field: dict[str, Any], value: str) -> str:
    for option in field.get("options", []):
        if option.get("name") == value:
            return option["id"]
    raise SyncError(f"Field {field['name']} does not contain option {value!r}")


def set_field_value(runner: Runner, project_id: str, item_id: str, field: dict[str, Any], value: Any) -> None:
    cmd = [
        "gh", "project", "item-edit",
        "--id", item_id,
        "--project-id", project_id,
        "--field-id", field["id"],
    ]
    field_type = field["type"]
    if field_type == "SINGLE_SELECT":
        cmd += ["--single-select-option-id", option_id(field, str(value))]
    elif field_type == "DATE":
        cmd += ["--date", str(value)]
    elif field_type == "NUMBER":
        cmd += ["--number", str(value)]
    elif field_type == "TEXT":
        cmd += ["--text", str(value)]
    else:
        raise SyncError(f"Unsupported runtime field type {field_type!r} for {field['name']}")
    runner.run(cmd)


def read_state(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {"completed_issue_keys": []}
    try:
        state = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise SyncError(f"Invalid state file {path}: {exc}") from exc
    if not isinstance(state.get("completed_issue_keys", []), list):
        raise SyncError(f"Invalid state file {path}: completed_issue_keys must be a list")
    return state


def write_state(path: Path, state: dict[str, Any]) -> None:
    temp = path.with_suffix(path.suffix + ".tmp")
    temp.write_text(json.dumps(state, indent=2) + "\n", encoding="utf-8")
    temp.replace(path)


def select_issues(config: dict[str, Any], args: argparse.Namespace, state: dict[str, Any]) -> list[dict[str, Any]]:
    issues = list(config["issues"])
    if args.resume_from:
        positions = {issue["key"]: index for index, issue in enumerate(issues)}
        if args.resume_from not in positions:
            raise SyncError(f"Unknown --resume-from key: {args.resume_from}")
        issues = issues[positions[args.resume_from]:]
    if args.resume:
        completed = set(state.get("completed_issue_keys", []))
        issues = [issue for issue in issues if issue["key"] not in completed]
    if args.limit is not None:
        if args.limit < 0:
            raise SyncError("--limit cannot be negative")
        issues = issues[:args.limit]
    return issues


def main() -> int:
    args = parse_args()
    config_path = Path(args.config).resolve()
    state_path = Path(args.state_file).resolve()
    config = load_json(config_path)
    validate(config)
    state = read_state(state_path)
    issues = select_issues(config, args, state)

    if args.dry_run:
        print_dry_run(config, issues)
        return 0

    if not gh_exists():
        raise SyncError("GitHub CLI 'gh' is not installed. Run with --dry-run for offline validation.")

    runner = Runner(verbose=args.verbose)
    ensure_auth(runner)
    ensure_repository(runner, config)
    ensure_labels(runner, config)
    ensure_milestones(runner, config)
    project_id, project_number = ensure_project(runner, config)
    fields = ensure_fields(runner, config, project_number)
    missing_fields = {spec["name"] for spec in config["fields"]} - set(fields)
    if missing_fields:
        raise SyncError(f"Project fields were not created or discovered: {sorted(missing_fields)}")

    known_issues = existing_issues(runner, config)
    known_items = project_items(runner, config, project_number)
    completed = set(state.get("completed_issue_keys", []))

    for index, issue in enumerate(issues, start=1):
        print(f"[{index}/{len(issues)}] Synchronizing {issue['key']}...", file=sys.stderr)
        github_issue = sync_issue(runner, config, issue, known_issues)
        item_id = ensure_project_item(runner, config, project_number, github_issue["url"], known_items)
        for field_name, value in issue.get("fields", {}).items():
            set_field_value(runner, project_id, item_id, fields[field_name], value)
        completed.add(issue["key"])
        state["completed_issue_keys"] = sorted(completed)
        state["project_number"] = project_number
        state["last_completed_issue_key"] = issue["key"]
        write_state(state_path, state)

    print(f"Completed. Open with: gh project view {project_number} --owner {config['owner']} --web")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except SyncError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        raise SystemExit(2)
