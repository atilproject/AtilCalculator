"""STORY-003b TC-4 — TDD-RED: Playwright E2E for keyboard input flow.

AC4: an E2E test that exercises digit entry → result via keyboard.

This is the load-bearing regression pin for the deferred-components
commit. It boots a real uvicorn server in a subprocess (on a free
port), opens Chromium against http://127.0.0.1:<port>/, dispatches
real keyboard events, and asserts the <atilcalc-display> result.

The test is skipped if `playwright` is not installed (CI may not
have a browser). The full install command is:
    pip install -e ".[dev]" && playwright install chromium
"""

from __future__ import annotations

import os
import socket
import subprocess
import time
import urllib.request
from pathlib import Path

import pytest

playwright = pytest.importorskip("playwright", reason="playwright not installed")
from playwright.sync_api import (  # noqa: E402  (importorskip above)
    Browser,
    sync_playwright,
)

# Path 2 fix per Issue #876 — module-level skip if chromium binary is absent.
# The browser fixture below already skips on launch failure, but doing so AFTER
# the `server` fixture has spawned the uvicorn subprocess causes the cold-start
# flake (uvicorn cold-start > SUBPROCESS_TIMEOUT_S on self-hosted VM, then
# communicate(timeout=1) fires the spurious failure before the skip takes effect).
# Probing chromium.executable_path BEFORE the server fixture avoids the
# subprocess launch entirely when the binary is missing (the typical CI state
# where the playwright Python lib IS installed via `pip install -e .[dev]`
# but the browser binary is NOT — see [dev] extras line 109 in pyproject.toml).
try:
    with sync_playwright() as _pw_probe:
        _chromium_exec = _pw_probe.chromium.executable_path
    if not _chromium_exec or not Path(_chromium_exec).exists():
        pytest.skip(
            "chromium browser binary not installed "
            "(run `playwright install chromium`); "
            "skipped at module level per Issue #876 Path 2 cold-start flake RCA"
        )
except Exception as _pw_exc:
    pytest.skip(
        f"playwright chromium probe failed ({type(_pw_exc).__name__}: {_pw_exc}); "
        "run `playwright install chromium` to enable E2E locally"
    )

REPO_ROOT = Path(__file__).resolve().parents[2]
RUN_SERVER_SH = REPO_ROOT / "scripts" / "run-server.sh"


def _free_port() -> int:
    """Return an OS-allocated free TCP port (SO_REUSEADDR)."""
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.bind(("127.0.0.1", 0))
        return s.getsockname()[1]


def _wait_for_healthz(base_url: str, timeout_s: float = 5.0) -> bool:
    """Poll /healthz until 200 or timeout. Returns True on 200."""
    deadline = time.time() + timeout_s
    while time.time() < deadline:
        try:
            with urllib.request.urlopen(f"{base_url}/healthz", timeout=0.5) as r:
                if r.status == 200:
                    return True
        except Exception:
            time.sleep(0.1)
    return False


@pytest.fixture(scope="module")
def server():
    """Boot a uvicorn subprocess on a free port, return its base URL.

    The server uses ATC_HOST=127.0.0.1 (loopback, dev-safe per ADR-0019
    security boundary) and a random free port. Cleanup kills the
    subprocess on teardown.

    Sprint 22 PIVOT (Issue #708) Faz 1.2 env-aware subprocess timeout per arch
    Option B verdict cmt 4842471072:
      - timeout_s = 10.0 for self-hosted cold start (VM 192.168.1.197)
      - timeout_s = 5.0 for github-hosted + local (faster cold start)
    The constant SUBPROCESS_TIMEOUT_S comes from tests/conftest.py (Sprint 22
    PIVOT Faz 1.2 d-test d100 TC3 regression guard).
    """
    from tests.conftest import SUBPROCESS_TIMEOUT_S
    if not RUN_SERVER_SH.exists():
        pytest.skip(f"scripts/run-server.sh missing (expected at {RUN_SERVER_SH})")
    port = _free_port()
    env = {
        **os.environ,
        "ATC_HOST": "127.0.0.1",
        "ATC_PORT": str(port),
        "PATH": os.environ.get("PATH", ""),
    }
    proc = subprocess.Popen(
        ["bash", str(RUN_SERVER_SH)],
        env=env,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    base_url = f"http://127.0.0.1:{port}"
    try:
        # Env-aware timeout: 10s for self-hosted, 5s for github-hosted + local.
        if not _wait_for_healthz(base_url, timeout_s=SUBPROCESS_TIMEOUT_S):
            # Cleanup: terminate the proc FIRST, then drain stderr.
            # PR #836 RCA (cycle #4249): proc.communicate(timeout=cleanup_timeout)
            # on a still-alive uvicorn raised subprocess.TimeoutExpired even
            # though uvicorn had already logged 'Application startup complete.'
            # — the cleanup timeout of 2s (computed as int(SUBPROCESS_TIMEOUT_S/5))
            # was insufficient to drain the pipe buffer during the failure path.
            # Fix: send SIGTERM, wait briefly for graceful exit, then drain
            # via communicate() — proc is dead → EOF is instant, no blocking.
            # Sister-pattern: ADR-0019 amend 3 §Runner-aware multipliers.
            proc.terminate()
            # Cap the graceful-shutdown wait at 5s (long enough for uvicorn to
            # flush, short enough to avoid blocking CI on a stuck proc).
            wait_budget = min(SUBPROCESS_TIMEOUT_S, 5)
            try:
                proc.wait(timeout=wait_budget)
            except subprocess.TimeoutExpired:
                proc.kill()
                proc.wait(timeout=1)
            # Proc is now dead — communicate() drains the buffered pipes
            # immediately and returns EOF. A 1s ceiling here is paranoia;
            # under normal conditions the call returns in microseconds.
            stdout, stderr = proc.communicate(timeout=1)
            pytest.fail(
                f"Server did not become healthy at {base_url} within "
                f"{SUBPROCESS_TIMEOUT_S}s.\n"
                f"stdout: {stdout.decode(errors='replace')}\n"
                f"stderr: {stderr.decode(errors='replace')}"
            )
        yield base_url
    finally:
        proc.terminate()
        # Env-aware proc.wait timeout: 60% of SUBPROCESS_TIMEOUT_S (3s on
        # github-hosted, 6s on self-hosted), enough for graceful shutdown.
        wait_timeout = max(int(SUBPROCESS_TIMEOUT_S * 0.6), 2)
        try:
            proc.wait(timeout=wait_timeout)
        except subprocess.TimeoutExpired:
            proc.kill()
            proc.wait(timeout=1)


@pytest.fixture(scope="module")
def browser() -> Browser:
    """Launch a Chromium browser for the E2E session.

    Skips the module (and therefore all tests in this file) if the
    chromium browser binary is missing. CI runners do not run
    ``playwright install chromium``; this guard prevents the
    "Executable doesn't exist at .../chromium_headless_shell-..." crash
    and turns it into a clean skip with a hint to install the binary
    locally for E2E runs.

    Locally, run:
        pip install -e ".[dev]" && playwright install chromium
    """
    with sync_playwright() as p:
        try:
            b = p.chromium.launch(headless=True)
        except Exception as exc:
            pytest.skip(
                f"chromium browser binary not installed ({type(exc).__name__}); "
                f"run 'playwright install chromium' to enable E2E locally. "
                f"Underlying: {exc}"
            )
            return  # unreachable; pytest.skip raises internally
        try:
            yield b
        finally:
            b.close()


def _result_text(page) -> str:
    """Read the result line of <atilcalc-display> (in shadow DOM)."""
    return page.evaluate(
        """() => {
            const display = document.querySelector('atilcalc-display');
            if (!display || !display.shadowRoot) return '';
            const result = display.shadowRoot.getElementById('result');
            return result ? result.textContent : '';
        }"""
    )


def test_e2e_simple_addition(server, browser) -> None:
    """AC4 happy path: `1` `+` `2` `Enter` → result `3`."""
    page = browser.new_page()
    try:
        page.goto(server + "/", wait_until="load")
        page.wait_for_selector("atilcalc-display")
        # Bring the page to the front so keyboard events go to it.
        page.bring_to_front()
        page.locator("body").click()  # focus the page
        for key in ("1", "+", "2", "Enter"):
            page.keyboard.press(key)
        # Wait for the FSM to call /api/evaluate and update the display.
        page.wait_for_function(
            "() => { const d = document.querySelector('atilcalc-display');"
            "  return d && d.shadowRoot && d.shadowRoot.getElementById('result')"
            "    && d.shadowRoot.getElementById('result').textContent === '3'; }",
            timeout=3000,
        )
        assert _result_text(page) == "3", f"expected '3', got {_result_text(page)!r}"
    finally:
        page.close()


def test_e2e_three_term_addition(server, browser) -> None:
    """AC4 second case: `1` `+` `2` `+` `3` `Enter` → result `6`."""
    page = browser.new_page()
    try:
        page.goto(server + "/", wait_until="load")
        page.wait_for_selector("atilcalc-display")
        page.bring_to_front()
        page.locator("body").click()
        for key in ("1", "+", "2", "+", "3", "Enter"):
            page.keyboard.press(key)
        page.wait_for_function(
            "() => { const d = document.querySelector('atilcalc-display');"
            "  return d && d.shadowRoot && d.shadowRoot.getElementById('result')"
            "    && d.shadowRoot.getElementById('result').textContent === '6'; }",
            timeout=3000,
        )
        assert _result_text(page) == "6", f"expected '6', got {_result_text(page)!r}"
    finally:
        page.close()


def test_e2e_multiplication(server, browser) -> None:
    """AC4 third case: `7` `*` `8` `Enter` → result `56`."""
    page = browser.new_page()
    try:
        page.goto(server + "/", wait_until="load")
        page.wait_for_selector("atilcalc-display")
        page.bring_to_front()
        page.locator("body").click()
        for key in ("7", "*", "8", "Enter"):
            page.keyboard.press(key)
        page.wait_for_function(
            "() => { const d = document.querySelector('atilcalc-display');"
            "  return d && d.shadowRoot && d.shadowRoot.getElementById('result')"
            "    && d.shadowRoot.getElementById('result').textContent === '56'; }",
            timeout=3000,
        )
        assert _result_text(page) == "56", f"expected '56', got {_result_text(page)!r}"
    finally:
        page.close()
