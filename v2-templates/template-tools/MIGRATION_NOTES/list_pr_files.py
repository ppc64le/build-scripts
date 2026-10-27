#!/usr/bin/env python3
"""
List all files from open upstream pull requests in ppc64le/build-scripts.

Outputs a CSV with columns: pr_number, pr_title, filename, status, owner, reviewers
"""

import csv
import os
import sys
import requests
from concurrent.futures import ThreadPoolExecutor, as_completed
from typing import Optional

GITHUB_API_BASE = "https://api.github.com"
REPO_OWNER = "ppc64le"
REPO_NAME = "build-scripts"
MAX_WORKERS = 10  # Number of parallel requests


def get_github_token() -> Optional[str]:
    """Get GitHub token from environment variable."""
    return os.environ.get("GITHUB_TOKEN")


def make_request(url: str, token: Optional[str] = None) -> dict:
    """Make a GitHub API request with optional authentication."""
    headers = {"Accept": "application/vnd.github.v3+json"}
    if token:
        headers["Authorization"] = f"token {token}"

    response = requests.get(url, headers=headers)

    if response.status_code == 403 and "rate limit" in response.text.lower():
        print("ERROR: GitHub API rate limit exceeded. Set GITHUB_TOKEN environment variable.", file=sys.stderr)
        sys.exit(1)

    response.raise_for_status()
    return response.json()


def get_open_pull_requests(token: Optional[str] = None) -> list:
    """Fetch all open pull requests from the repository."""
    prs = []
    page = 1
    per_page = 100

    while True:
        url = f"{GITHUB_API_BASE}/repos/{REPO_OWNER}/{REPO_NAME}/pulls?state=open&per_page={per_page}&page={page}"
        page_prs = make_request(url, token)

        if not page_prs:
            break

        prs.extend(page_prs)

        if len(page_prs) < per_page:
            break

        page += 1

    return prs


def get_pr_files(pr_number: int, token: Optional[str] = None) -> list:
    """Fetch all files changed in a pull request."""
    files = []
    page = 1
    per_page = 100

    while True:
        url = f"{GITHUB_API_BASE}/repos/{REPO_OWNER}/{REPO_NAME}/pulls/{pr_number}/files?per_page={per_page}&page={page}"
        page_files = make_request(url, token)

        if not page_files:
            break

        files.extend(page_files)

        if len(page_files) < per_page:
            break

        page += 1

    return files


def get_pr_reviewers(pr: dict, token: Optional[str] = None) -> str:
    """Get reviewers for a PR (both requested and those who submitted reviews)."""
    reviewers = set()
    pr_number = pr["number"]

    # Get requested reviewers from PR object
    for reviewer in pr.get("requested_reviewers", []):
        reviewers.add(reviewer["login"])

    # Get reviewers who have submitted reviews
    try:
        url = f"{GITHUB_API_BASE}/repos/{REPO_OWNER}/{REPO_NAME}/pulls/{pr_number}/reviews"
        reviews = make_request(url, token)
        for review in reviews:
            if review.get("user"):
                reviewers.add(review["user"]["login"])
    except requests.exceptions.RequestException:
        pass  # Skip if we can't fetch reviews

    return ", ".join(sorted(reviewers)) if reviewers else ""


def process_pr(pr: dict, token: Optional[str] = None) -> list:
    """Process a single PR and return all file rows for it."""
    pr_number = pr["number"]
    pr_title = pr["title"]
    owner = pr["user"]["login"]

    reviewers = get_pr_reviewers(pr, token)
    files = get_pr_files(pr_number, token)

    rows = []
    for file_info in files:
        filename = file_info["filename"]
        status = file_info["status"]
        rows.append([pr_number, pr_title, filename, status, owner, reviewers])

    return rows


def main():
    token = get_github_token()

    if not token:
        print("WARNING: No GITHUB_TOKEN set. API rate limits may apply.", file=sys.stderr)

    print("Fetching open pull requests...", file=sys.stderr)
    prs = get_open_pull_requests(token)
    print(f"Found {len(prs)} open pull requests.", file=sys.stderr)

    # CSV output to stdout
    writer = csv.writer(sys.stdout)
    writer.writerow(["pr_number", "pr_title", "filename", "status", "owner", "reviewers"])

    print(f"Fetching files from PRs using {MAX_WORKERS} parallel workers...", file=sys.stderr)

    all_rows = []
    completed = 0

    with ThreadPoolExecutor(max_workers=MAX_WORKERS) as executor:
        future_to_pr = {executor.submit(process_pr, pr, token): pr for pr in prs}

        for future in as_completed(future_to_pr):
            pr = future_to_pr[future]
            completed += 1

            try:
                rows = future.result()
                all_rows.extend(rows)
                print(f"[{completed}/{len(prs)}] PR #{pr['number']}: {len(rows)} files", file=sys.stderr)
            except Exception as e:
                print(f"[{completed}/{len(prs)}] PR #{pr['number']}: ERROR - {e}", file=sys.stderr)

    # Sort by PR number for consistent output
    all_rows.sort(key=lambda x: x[0])

    for row in all_rows:
        writer.writerow(row)

    print("Done.", file=sys.stderr)


if __name__ == "__main__":
    main()
