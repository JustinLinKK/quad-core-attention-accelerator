#!/usr/bin/env python3
"""Generate a B2-only dataset tailored for the Step6 fullchip testbench."""

from __future__ import annotations

import json
import shutil
import subprocess
import sys
from pathlib import Path


def main() -> None:
    out_dir = Path("Step6/datafiles/fullchip_b2_case")
    if out_dir.exists():
        shutil.rmtree(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    cmd = [
        sys.executable,
        "Step6/scripts/generate_sparse_dataset.py",
        "--output-dir",
        str(out_dir),
        "--seed",
        "2606",
        "--tiles",
        "2",
        "--cores",
        "4",
        "--rows",
        "8",
        "--cols",
        "8",
        "--pr",
        "8",
        "--bw",
        "8",
        "--q-zero-prob",
        "0.10",
        "--k-zero-prob",
        "0.10",
        "--v-zero-prob",
        "0.10",
        "--low-row-prob",
        "0.35",
        "--b1-percentile",
        "70.0",
        "--b2-percentile",
        "30.0",
    ]
    subprocess.run(cmd, check=True)

    manifest_path = out_dir / "manifest.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))

    print(json.dumps({
        "output_dir": str(out_dir),
        "tiles": manifest["shape"]["tiles"],
        "cores": manifest["shape"]["cores"],
        "b2_only_thresholds": manifest["b2_only"]["threshold_int_per_tile_core"],
        "b2_only_keep_ratio": manifest["b2_only"]["actual_keep_ratio"],
        "b2_only_skip_ratio": manifest["b2_only"]["actual_skip_ratio"],
    }, indent=2))


if __name__ == "__main__":
    main()
