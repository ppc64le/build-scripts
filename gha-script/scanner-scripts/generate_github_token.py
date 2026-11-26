#!/usr/bin/env python3

import base64
import os
import sys
import time

import requests
from github import GithubIntegration


GITHUB_APP_ID = os.environ.get("GITHUB_APP_ID")
GITHUB_APP_KEY_RAW = os.environ.get("GITHUB_APP_KEY")
GITHUB_INSTALLATION_ID = os.environ.get("GITHUB_INSTALLATION_ID")

KEY_IS_BASE64 = (
    os.environ.get("GITHUB_APP_KEY_BASE64", "true").lower() != "false"
)

MAX_RETRIES = 3
RETRY_DELAY = 2


def fail(message):
    print(f"ERROR: {message}", file=sys.stderr)
    sys.exit(1)


if not GITHUB_APP_ID:
    fail("GITHUB_APP_ID environment variable is not set.")

if not GITHUB_APP_KEY_RAW:
    fail("GITHUB_APP_KEY environment variable is not set.")

if not GITHUB_INSTALLATION_ID:
    fail("GITHUB_INSTALLATION_ID environment variable is not set.")


# Decode private key if supplied as base64
if KEY_IS_BASE64:
    try:
        GITHUB_APP_KEY = base64.b64decode(
            GITHUB_APP_KEY_RAW
        ).decode("utf-8")
    except Exception as e:
        fail(f"Failed to base64-decode GITHUB_APP_KEY: {e}")
else:
    GITHUB_APP_KEY = GITHUB_APP_KEY_RAW


def generate_token():
    integration = GithubIntegration(
        int(GITHUB_APP_ID),
        GITHUB_APP_KEY,
    )

    for attempt in range(MAX_RETRIES):
        try:
            token_data = integration.get_access_token(
                int(GITHUB_INSTALLATION_ID)
            )

            if not token_data:
                raise RuntimeError(
                    "GitHub returned an empty installation token."
                )

            token = token_data.token

            # Check expiration
            if token_data.expires_at.timestamp() <= time.time():
                raise RuntimeError(
                    "GitHub returned an already-expired token."
                )

            # Validate token
            response = requests.get(
                "https://api.github.com/rate_limit",
                headers={
                    "Authorization": f"Bearer {token}",
                    "Accept": "application/vnd.github+json",
                    "X-GitHub-Api-Version": "2026-03-10",
                },
                timeout=10,
            )

            if response.ok:
                print(token)
                return

            print(
                f"Token validation failed: "
                f"HTTP {response.status_code}",
                file=sys.stderr,
            )

        except requests.exceptions.Timeout:
            if attempt < MAX_RETRIES - 1:
                print(
                    f"Request timeout on attempt {attempt + 1}, retrying...",
                    file=sys.stderr,
                )
                time.sleep(RETRY_DELAY * (attempt + 1))
            else:
                fail("Request timed out after maximum retries.")

        except Exception as e:
            if attempt < MAX_RETRIES - 1:
                print(
                    f"GitHub API error on attempt {attempt + 1}: {e}",
                    file=sys.stderr,
                )
                time.sleep(RETRY_DELAY * (attempt + 1))
            else:
                fail(f"Failed to generate GitHub App token: {e}")


if __name__ == "__main__":
    print(
        f"Generating GitHub App installation token "
        f"for App ID {GITHUB_APP_ID}...",
        file=sys.stderr,
    )

    generate_token()
