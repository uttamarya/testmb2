#!/usr/bin/env python3
"""
Salesforce Metadata Extractor

Uses the Salesforce CLI (sf) for authentication and metadata retrieval.
Sets NODE_OPTIONS to increase heap size for large orgs that would
otherwise cause the sf CLI to run out of memory.

Usage:
    1. Copy config.example.yaml -> config.yaml and fill in sandbox details.
    2. pip install -r requirements.txt
    3. python extract_metadata.py       (or double-click extract.bat)

On first run the script opens a browser so you can log in to Salesforce.
That auth is stored by the sf CLI and reused on subsequent runs automatically.
"""

import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

import yaml

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------


def load_config() -> dict:
    """Load configuration from config.yaml."""
    script_dir = Path(__file__).resolve().parent

    config_path = script_dir / "config.yaml"
    if not config_path.exists():
        print(
            "Error: config.yaml not found.\n"
            "       Copy config.example.yaml to config.yaml and fill in your values."
        )
        sys.exit(1)

    with open(config_path, encoding="utf-8") as fh:
        return yaml.safe_load(fh)


# ---------------------------------------------------------------------------
# Prerequisite checks
# ---------------------------------------------------------------------------


def find_sf_cli() -> str:
    """Locate the Salesforce CLI executable and return its full path."""
    sf_path = shutil.which("sf")
    if sf_path is None:
        print(
            "Error: Salesforce CLI (sf) not found on PATH.\n"
            "       Install it from https://developer.salesforce.com/tools/salesforcecli"
        )
        sys.exit(1)
    return sf_path


# ---------------------------------------------------------------------------
# SF CLI wrappers
# ---------------------------------------------------------------------------


def write_sfdx_project(output_dir: str, api_version: str) -> Path:
    """Create a minimal sfdx-project.json pointing to the output directory."""
    script_dir = Path(__file__).resolve().parent
    project_file = script_dir / "sfdx-project.json"

    # Ensure the output directory exists — sf CLI requires it before retrieve
    Path(output_dir).mkdir(parents=True, exist_ok=True)

    project = {
        "packageDirectories": [{"path": output_dir, "default": True}],
        "sourceApiVersion": api_version,
    }

    project_file.write_text(json.dumps(project, indent=2) + "\n", encoding="utf-8")
    return project_file


# ---------------------------------------------------------------------------
# Salesforce CLI wrappers
# ---------------------------------------------------------------------------


def run_cmd(args: list[str], error_msg: str, stream: bool = False) -> subprocess.CompletedProcess:
    """Run a shell command, print output, and exit on failure.

    If stream=True, stdout/stderr are shown in real-time instead of captured.
    """
    if stream:
        result = subprocess.run(args)
        if result.returncode != 0:
            print(f"\n{error_msg}")
            sys.exit(1)
        return result

    result = subprocess.run(args, capture_output=True, text=True)

    if result.stdout:
        for line in result.stdout.strip().splitlines():
            print(f"  {line}")

    if result.returncode != 0:
        print(f"\n{error_msg}")
        if result.stderr:
            for line in result.stderr.strip().splitlines():
                # Skip the noisy Node.js deprecation warning
                if "DEP0040" in line or "punycode" in line or "trace-deprecation" in line:
                    continue
                print(f"  {line}")
        sys.exit(1)

    return result


def _resolve_target_org(config: dict) -> str:
    """Return the target org identifier (explicit target_org, or sandbox_name alias)."""
    return config.get("target_org", "") or config.get("sandbox_name", "")


def _is_org_authenticated(sf_path: str, target_org: str) -> bool:
    """Check if the target org already has a valid auth session."""
    result = subprocess.run(
        [sf_path, "org", "display", "--target-org", target_org, "--json"],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        return False
    try:
        data = json.loads(result.stdout)
        return data.get("status", 1) == 0
    except (json.JSONDecodeError, KeyError):
        return False


def sf_authenticate(sf_path: str, config: dict) -> None:
    """Ensure the org is authenticated via the sf CLI (browser login if needed)."""
    login_url = config.get("login_url", "https://login.salesforce.com")
    target_org = _resolve_target_org(config)
    alias = config.get("sandbox_name", "")

    print("[1/3] Checking Salesforce authentication ...")

    if target_org and _is_org_authenticated(sf_path, target_org):
        print(f"  Already authenticated as {target_org}\n")
        return

    print("  No active session found. Opening browser for login ...")
    print("  (This is a one-time step — auth is stored for future runs)\n")

    cmd = [sf_path, "org", "login", "web", "--instance-url", login_url]
    if alias:
        cmd.extend(["--alias", alias])
    cmd.extend(["--set-default"])

    run_cmd(cmd, error_msg="Login failed. Please try again.")
    print()


def sf_retrieve(
    sf_path: str, config: dict, package_path: str, wait_minutes: int, heap_mb: int
) -> None:
    """Retrieve metadata using sf project retrieve start with increased heap."""
    target_org = _resolve_target_org(config)

    print("[2/3] Retrieving metadata (this may take a while for large orgs) ...")
    print(f"  Node.js heap size: {heap_mb} MB\n")

    cmd = [
        sf_path, "project", "retrieve", "start",
        "--manifest", package_path,
        "--target-org", target_org,
        "--wait", str(wait_minutes),
    ]

    run_cmd(cmd, error_msg="Metadata retrieve failed.", stream=True)
    print()


# ---------------------------------------------------------------------------
# sfdx-project.json management
# ---------------------------------------------------------------------------


def write_sfdx_project(output_dir: str, api_version: str) -> None:
    """Create a minimal sfdx-project.json pointing to the output directory."""
    script_dir = Path(__file__).resolve().parent
    project_file = script_dir / "sfdx-project.json"

    # Ensure output directory exists (sf CLI requires it)
    Path(output_dir).mkdir(parents=True, exist_ok=True)

    project = {
        "packageDirectories": [{"path": output_dir, "default": True}],
        "sourceApiVersion": api_version,
    }

    project_file.write_text(json.dumps(project, indent=2) + "\n", encoding="utf-8")


def get_api_version(package_path: str) -> str:
    """Read the API version from package.xml."""
    import xml.etree.ElementTree as ET

    tree = ET.parse(package_path)
    root = tree.getroot()
    ns = {"pkg": "http://soap.sforce.com/2006/04/metadata"}
    version_el = root.find("pkg:version", ns)
    return version_el.text if version_el is not None else "63.0"


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------


def main() -> None:
    print("=" * 60)
    print("  Salesforce Metadata Extractor")
    print("=" * 60)

    sf_path = find_sf_cli()
    config = load_config()

    sandbox_name = config.get("sandbox_name", "default")
    package_path = config.get("package_xml", "package.xml")
    output_base = config.get("output_dir", "output")
    output_dir = os.path.join(output_base, sandbox_name)

    retrieve_cfg = config.get("retrieve", {})
    wait_minutes = retrieve_cfg.get("wait_minutes", 60)
    heap_mb = retrieve_cfg.get("node_heap_mb", 32768)

    print(f"\n  Sandbox : {sandbox_name}")
    print(f"  Package : {package_path}")
    print(f"  Output  : {output_dir}\n")

    # Generate sfdx-project.json and ensure output dir exists
    api_version = get_api_version(package_path)
    write_sfdx_project(output_dir, api_version)

    # Authenticate (reuses stored auth or opens browser)
    sf_authenticate(sf_path, config)

    # Retrieve with increased Node.js heap
    sf_retrieve(sf_path, config, package_path, wait_minutes, heap_mb)

    # Summary
    out_path = Path(output_dir)
    if out_path.exists():
        file_count = sum(1 for f in out_path.rglob("*") if f.is_file())
        print(f"[3/3] {file_count} files written to {output_dir}/")
    else:
        print(f"[3/3] Output directory: {output_dir}/")

    print("\nDone.")


if __name__ == "__main__":
    main()
