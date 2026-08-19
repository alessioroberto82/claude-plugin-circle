#!/usr/bin/env python3

import argparse
import shutil
from pathlib import Path


SHARED_RESOURCES = (
    "handoff-digest-template.md",
    "soul.md",
    "templates/business/business-requirements.md",
    "templates/business/compliance-report.md",
    "templates/business/customer-experience.md",
    "templates/business/quarterly-plan.md",
    "templates/business/validation-plan.md",
    "templates/docs/adr.md",
    "templates/docs/module-architecture-swift.md",
    "templates/docs/module-architecture.md",
    "templates/docs/reusable-ui-swift.md",
    "templates/docs/reusable-ui.md",
    "templates/personal/goals.md",
    "templates/personal/life-design.md",
    "templates/personal/privacy-audit.md",
    "templates/personal/progress-plan.md",
    "templates/personal/weekly-plan.md",
    "templates/software/PRD.md",
    "templates/software/architecture.md",
    "templates/software/security-audit.md",
    "work-summary-template.md",
)


def main() -> int:
    parser = argparse.ArgumentParser(description="Sync resources shared by the Claude and Codex plugins.")
    parser.add_argument("--check", action="store_true", help="Report drift without changing files.")
    args = parser.parse_args()

    root = Path(__file__).resolve().parents[1]
    source_root = root / "plugin/resources"
    target_root = root / "plugins/circle/resources"
    drift = []
    updated = 0

    for relative in SHARED_RESOURCES:
        source = source_root / relative
        target = target_root / relative
        if not source.is_file():
            parser.error(f"missing canonical resource: {source.relative_to(root)}")
        if target.is_file() and source.read_bytes() == target.read_bytes():
            continue
        if args.check:
            drift.append(relative)
            continue
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(source, target)
        updated += 1

    if drift:
        print("Shared resource drift:")
        for relative in drift:
            print(f"- {relative}")
        return 1

    action = "verified" if args.check else f"synced ({updated} updated)"
    print(f"Shared resources {action}: {len(SHARED_RESOURCES)} files")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
