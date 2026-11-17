"""Run repeatable real-TUI scenarios through a separate nvim-mcp server per case."""

import argparse
import asyncio
import json
from pathlib import Path
import sys
import tempfile

from scenarios import CASES


def field(key, value):
    # A flat TOON object uses JSON-compatible quoted scalar strings.
    print(f"{key}: {json.dumps(value, ensure_ascii=False)}", flush=True)


class Parser(argparse.ArgumentParser):
    def error(self, message):
        field("error", message)
        field("help", "Run python tests/e2e/run.py --help for valid selections")
        raise SystemExit(2)


async def execute(args):
    try:
        from harness import Audit, MCPError
    except ImportError:
        field("error", "The runner's Python environment does not contain the MCP client")
        field("help", "Install tests/e2e/requirements.txt into a venv, then run this script with that Python")
        return 1
    output = Path(args.output).expanduser().resolve() if args.output else Path(tempfile.mkdtemp(prefix="nvim-e2e-"))
    if args.output and output.exists() and any(output.iterdir()):
        raise ValueError(f"Evidence directory is not empty: {output}")
    output.mkdir(parents=True, exist_ok=True)
    selected = list(CASES) if args.all or args.case else args.suite
    results = []
    for suite in selected:
        for name, scenario in CASES[suite].items():
            case = f"{suite}-{name}"
            if args.case and case not in args.case:
                continue
            status, detail = "pass", ""
            try:
                async with Audit(case, output_dir=output) as audit:
                    await scenario(audit)
            except AssertionError as error:
                status, detail = "fail", str(error)
            except MCPError as error:
                status, detail = "fail", str(error)
            except Exception as error:
                status, detail = "blocked", str(error)
            results.append({"case": case, "status": status, "detail": detail})
            preview = detail if len(detail) <= 500 else detail[:500] + "... (full detail in results.json)"
            field("case", f"{case}: {status}" + (f"; {preview}" if detail else ""))
    result_path = output / "results.json"
    result_path.write_text(json.dumps({"results": results}, ensure_ascii=False, indent=2) + "\n")
    for status in ["pass", "fail", "blocked"]:
        field(status, sum(result["status"] == status for result in results))
    field("evidence", str(output))
    return int(any(result["status"] != "pass" for result in results))


def main():
    parser = Parser(
            description="Isolated Neovim TUI/MCP regression scenarios. No arguments lists available suites.",
            epilog="Examples: run.py --suite smoke; run.py --suite core; run.py --all --output /tmp/audit-new",
    )
    select = parser.add_mutually_exclusive_group()
    select.add_argument("--suite", action="append", choices=list(CASES), help="Suite to execute; repeatable")
    select.add_argument("--case", action="append", choices=[f"{suite}-{name}" for suite, cases in CASES.items() for name in
                                                            cases], help="Individual case to execute; repeatable")
    select.add_argument("--all", action="store_true", help="Run all suites, including known anomaly reproductions")
    parser.add_argument("--output", help="New evidence directory; default creates a unique directory in /tmp")
    args = parser.parse_args()
    if not args.suite and not args.all and not args.case:
        field("bin", str(Path(__file__).resolve()))
        field("description", "Run isolated Neovim TUI scenarios through MCP")
        for suite, cases in CASES.items():
            field(suite, ", ".join(cases))
        field("help", "Run python tests/e2e/run.py --suite smoke, or --all for every saved scenario")
        return 0
    try:
        return asyncio.run(execute(args))
    except (OSError, ValueError) as error:
        field("error", str(error))
        field("help", "Use a new writable --output directory and verify the documented prerequisites")
        return 1


if __name__ == "__main__":
    sys.exit(main())
