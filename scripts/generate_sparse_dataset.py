#!/usr/bin/env python3
"""Generate Step6 sparsity-aware datasets with PyTorch."""

from __future__ import annotations

import argparse
import json
import math
from pathlib import Path
from typing import Dict

import torch


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output-dir", default="Step6/datafiles/step6_sparse_sample")
    parser.add_argument("--seed", type=int, default=2606)
    parser.add_argument("--tiles", type=int, default=2)
    parser.add_argument("--cores", type=int, default=4)
    parser.add_argument("--rows", type=int, default=8)
    parser.add_argument("--cols", type=int, default=8)
    parser.add_argument("--pr", type=int, default=8)
    parser.add_argument("--bw", type=int, default=8)
    parser.add_argument("--q-limit", type=int, default=12)
    parser.add_argument("--k-limit", type=int, default=10)
    parser.add_argument("--v-limit", type=int, default=11)
    parser.add_argument("--q-zero-prob", type=float, default=0.15)
    parser.add_argument("--k-zero-prob", type=float, default=0.15)
    parser.add_argument("--v-zero-prob", type=float, default=0.10)
    parser.add_argument("--low-row-prob", type=float, default=0.30)
    parser.add_argument("--b1-percentile", type=float, default=70.0)
    parser.add_argument("--b2-percentile", type=float, default=30.0)
    return parser.parse_args()


def sample_tensor(
    shape: torch.Size,
    magnitude: int,
    zero_prob: float,
    low_row_prob: float,
    generator: torch.Generator,
) -> torch.Tensor:
    data = torch.randint(
        low=-magnitude,
        high=magnitude + 1,
        size=shape,
        generator=generator,
        dtype=torch.int64,
    )
    if zero_prob > 0.0:
        zero_mask = torch.rand(shape, generator=generator) < zero_prob
        data = data.masked_fill(zero_mask, 0)
    if low_row_prob > 0.0:
        row_mask = torch.rand(shape[:-1], generator=generator) < low_row_prob
        data = torch.where(row_mask.unsqueeze(-1), torch.div(data, 2, rounding_mode="trunc"), data)
    return data


def trunc_divide(numer: torch.Tensor, denom: torch.Tensor) -> torch.Tensor:
    abs_q = torch.div(torch.abs(numer), torch.abs(denom), rounding_mode="trunc")
    same_sign = (numer >= 0) == (denom >= 0)
    return torch.where(same_sign, abs_q, -abs_q)


def wrap_s8(x: torch.Tensor) -> torch.Tensor:
    wrapped = torch.remainder(x, 256)
    wrapped = torch.where(wrapped >= 128, wrapped - 256, wrapped)
    return wrapped.to(torch.int64)


def percentile_to_int_threshold(values: torch.Tensor, percentile: float) -> Dict[str, float]:
    threshold_fp = torch.quantile(values.to(torch.float32), percentile / 100.0).item()
    threshold_int = int(math.ceil(threshold_fp))
    return {
        "threshold_fp": float(threshold_fp),
        "threshold_int": threshold_int,
    }


def write_matrix(path: Path, matrix: torch.Tensor) -> None:
    with path.open("w", encoding="utf-8") as fh:
        for row in matrix.tolist():
            fh.write("\t".join(str(int(v)) for v in row))
            fh.write("\n")


def write_vector(path: Path, vector: torch.Tensor) -> None:
    with path.open("w", encoding="utf-8") as fh:
        for value in vector.tolist():
            fh.write(f"{int(value)}\n")


def write_scalar(path: Path, value: int) -> None:
    with path.open("w", encoding="utf-8") as fh:
        fh.write(f"{int(value)}\n")


def emit_core_dataset(
    out_dir: Path,
    prefix: str,
    tensors: Dict[str, torch.Tensor],
    tile_idx: int,
    core_idx: int,
) -> None:
    out_dir.mkdir(parents=True, exist_ok=True)

    write_matrix(out_dir / f"{prefix}qdata.txt", tensors["q"][tile_idx, core_idx])
    write_matrix(out_dir / f"{prefix}kdata.txt", tensors["k"][tile_idx, core_idx])
    write_matrix(out_dir / f"{prefix}vdata.txt", tensors["v"][tile_idx, core_idx])
    write_matrix(out_dir / f"{prefix}qk_full.txt", tensors["qk_full"][tile_idx, core_idx])
    write_matrix(out_dir / f"{prefix}qk_b1.txt", tensors["qk_b1"][tile_idx, core_idx])
    write_matrix(out_dir / f"{prefix}norm_full.txt", tensors["norm_full"][tile_idx, core_idx])
    write_matrix(out_dir / f"{prefix}norm_b2_only.txt", tensors["norm_b2_only"][tile_idx, core_idx])
    write_matrix(out_dir / f"{prefix}norm_b1.txt", tensors["norm_b1"][tile_idx, core_idx])
    write_matrix(out_dir / f"{prefix}norm_b1_b2.txt", tensors["norm_b1_b2"][tile_idx, core_idx])
    write_matrix(out_dir / f"{prefix}z_full.txt", tensors["z_full"][tile_idx, core_idx])
    write_matrix(out_dir / f"{prefix}z_b2_only.txt", tensors["z_b2_only"][tile_idx, core_idx])
    write_matrix(out_dir / f"{prefix}z_b1.txt", tensors["z_b1"][tile_idx, core_idx])
    write_matrix(out_dir / f"{prefix}z_b1_b2.txt", tensors["z_b1_b2"][tile_idx, core_idx])
    write_matrix(out_dir / f"{prefix}b1_keep_mask.txt", tensors["b1_keep"][tile_idx, core_idx])
    write_vector(out_dir / f"{prefix}b2_only_keep_mask.txt", tensors["b2_only_keep"][tile_idx, core_idx])
    write_vector(out_dir / f"{prefix}b2_keep_mask.txt", tensors["b2_keep"][tile_idx, core_idx])
    write_vector(out_dir / f"{prefix}row_abs_full.txt", tensors["row_abs_full"][tile_idx, core_idx])
    write_vector(out_dir / f"{prefix}row_abs_b1.txt", tensors["row_abs_b1"][tile_idx, core_idx])
    write_vector(out_dir / f"{prefix}denom_full.txt", tensors["denom_full"][tile_idx, core_idx])
    write_vector(out_dir / f"{prefix}denom_b1.txt", tensors["denom_b1"][tile_idx, core_idx])
    write_scalar(out_dir / f"{prefix}b1_threshold.txt", tensors["b1_threshold_int"][tile_idx, core_idx].item())
    write_scalar(out_dir / f"{prefix}b2_only_threshold.txt", tensors["b2_only_threshold_int"][tile_idx, core_idx].item())
    write_scalar(out_dir / f"{prefix}b2_threshold.txt", tensors["b2_threshold_int"][tile_idx, core_idx].item())


def emit_tile_dir(tile_dir: Path, tile_idx: int, tensors: Dict[str, torch.Tensor], num_cores: int) -> None:
    tile_dir.mkdir(parents=True, exist_ok=True)

    write_vector(tile_dir / "b1_thresholds.txt", tensors["b1_threshold_int"][tile_idx])
    write_vector(tile_dir / "b2_only_thresholds.txt", tensors["b2_only_threshold_int"][tile_idx])
    write_vector(tile_dir / "b2_thresholds.txt", tensors["b2_threshold_int"][tile_idx])

    for core_idx in range(num_cores):
        emit_core_dataset(tile_dir / f"core{core_idx}", "", tensors, tile_idx, core_idx)
        emit_core_dataset(tile_dir, f"core{core_idx}_", tensors, tile_idx, core_idx)


def main() -> None:
    args = parse_args()
    out_dir = Path(args.output_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    generator = torch.Generator(device="cpu")
    generator.manual_seed(args.seed)

    q = sample_tensor(
        shape=torch.Size([args.tiles, args.cores, args.rows, args.pr]),
        magnitude=args.q_limit,
        zero_prob=args.q_zero_prob,
        low_row_prob=args.low_row_prob,
        generator=generator,
    )
    k = sample_tensor(
        shape=torch.Size([args.tiles, args.cores, args.cols, args.pr]),
        magnitude=args.k_limit,
        zero_prob=args.k_zero_prob,
        low_row_prob=args.low_row_prob,
        generator=generator,
    )
    v = sample_tensor(
        shape=torch.Size([args.tiles, args.cores, args.rows, args.pr]),
        magnitude=args.v_limit,
        zero_prob=args.v_zero_prob,
        low_row_prob=args.low_row_prob,
        generator=generator,
    )

    qk_full = torch.matmul(q, k.transpose(-1, -2))
    qk_abs = torch.abs(qk_full)

    b1_keep = torch.zeros_like(qk_abs, dtype=torch.int64)
    qk_b1 = torch.zeros_like(qk_full)
    b1_threshold_fp = torch.zeros((args.tiles, args.cores), dtype=torch.float32)
    b1_threshold_int = torch.zeros((args.tiles, args.cores), dtype=torch.int64)

    for tile_idx in range(args.tiles):
        for core_idx in range(args.cores):
            b1_meta = percentile_to_int_threshold(qk_abs[tile_idx, core_idx].flatten(), args.b1_percentile)
            b1_threshold_fp[tile_idx, core_idx] = b1_meta["threshold_fp"]
            b1_threshold_int[tile_idx, core_idx] = b1_meta["threshold_int"]
            b1_keep[tile_idx, core_idx] = (
                qk_abs[tile_idx, core_idx] >= b1_meta["threshold_int"]
            ).to(torch.int64)
            qk_b1[tile_idx, core_idx] = qk_full[tile_idx, core_idx] * b1_keep[tile_idx, core_idx]

    row_abs_full = qk_abs.sum(dim=-1)
    row_abs_b1 = torch.abs(qk_b1).sum(dim=-1)

    b2_only_keep = torch.zeros_like(row_abs_full, dtype=torch.int64)
    b2_keep = torch.zeros_like(row_abs_b1, dtype=torch.int64)
    b2_only_threshold_fp = torch.zeros((args.tiles, args.cores), dtype=torch.float32)
    b2_only_threshold_int = torch.zeros((args.tiles, args.cores), dtype=torch.int64)
    b2_threshold_fp = torch.zeros((args.tiles, args.cores), dtype=torch.float32)
    b2_threshold_int = torch.zeros((args.tiles, args.cores), dtype=torch.int64)

    for tile_idx in range(args.tiles):
        for core_idx in range(args.cores):
            b2_only_meta = percentile_to_int_threshold(row_abs_full[tile_idx, core_idx].flatten(), args.b2_percentile)
            b2_only_threshold_fp[tile_idx, core_idx] = b2_only_meta["threshold_fp"]
            b2_only_threshold_int[tile_idx, core_idx] = b2_only_meta["threshold_int"]
            b2_only_keep[tile_idx, core_idx] = (
                row_abs_full[tile_idx, core_idx] >= b2_only_meta["threshold_int"]
            ).to(torch.int64)

            b2_meta = percentile_to_int_threshold(row_abs_b1[tile_idx, core_idx].flatten(), args.b2_percentile)
            b2_threshold_fp[tile_idx, core_idx] = b2_meta["threshold_fp"]
            b2_threshold_int[tile_idx, core_idx] = b2_meta["threshold_int"]
            b2_keep[tile_idx, core_idx] = (
                row_abs_b1[tile_idx, core_idx] >= b2_meta["threshold_int"]
            ).to(torch.int64)

    denom_full = torch.clamp(row_abs_full >> 7, min=1)
    denom_b1 = torch.clamp(row_abs_b1 >> 7, min=1)

    norm_full = trunc_divide(qk_full, denom_full.unsqueeze(-1))
    norm_b2_only = norm_full * b2_only_keep.unsqueeze(-1)
    norm_b1 = trunc_divide(qk_b1, denom_b1.unsqueeze(-1))
    norm_b1_b2 = norm_b1 * b2_keep.unsqueeze(-1)

    stage2_k_full = wrap_s8(norm_full)
    stage2_k_b2_only = wrap_s8(norm_b2_only)
    stage2_k_b1 = wrap_s8(norm_b1)
    stage2_k_b1_b2 = wrap_s8(norm_b1_b2)

    z_full = torch.matmul(v, stage2_k_full.transpose(-1, -2))
    z_b2_only = torch.matmul(v, stage2_k_b2_only.transpose(-1, -2))
    z_b1 = torch.matmul(v, stage2_k_b1.transpose(-1, -2))
    z_b1_b2 = torch.matmul(v, stage2_k_b1_b2.transpose(-1, -2))

    tensors = {
        "q": q,
        "k": k,
        "v": v,
        "qk_full": qk_full,
        "qk_b1": qk_b1,
        "norm_full": norm_full,
        "norm_b2_only": norm_b2_only,
        "norm_b1": norm_b1,
        "norm_b1_b2": norm_b1_b2,
        "z_full": z_full,
        "z_b2_only": z_b2_only,
        "z_b1": z_b1,
        "z_b1_b2": z_b1_b2,
        "b1_keep": b1_keep,
        "b2_only_keep": b2_only_keep,
        "b2_keep": b2_keep,
        "row_abs_full": row_abs_full,
        "row_abs_b1": row_abs_b1,
        "denom_full": denom_full,
        "denom_b1": denom_b1,
        "b1_threshold_int": b1_threshold_int,
        "b2_only_threshold_int": b2_only_threshold_int,
        "b2_threshold_int": b2_threshold_int,
    }

    for tile_idx in range(args.tiles):
        tile_dir = out_dir / f"tile{tile_idx:02d}"
        emit_tile_dir(tile_dir, tile_idx, tensors, args.cores)
        for core_idx in range(args.cores):
            emit_core_dataset(out_dir, f"tile{tile_idx:02d}_core{core_idx}_", tensors, tile_idx, core_idx)

    summary = {
        "seed": args.seed,
        "shape": {
            "tiles": args.tiles,
            "cores": args.cores,
            "rows": args.rows,
            "cols": args.cols,
            "pr": args.pr,
            "bw": args.bw,
        },
        "ranges": {
            "q_limit": args.q_limit,
            "k_limit": args.k_limit,
            "v_limit": args.v_limit,
        },
        "distribution": {
            "q_zero_prob": args.q_zero_prob,
            "k_zero_prob": args.k_zero_prob,
            "v_zero_prob": args.v_zero_prob,
            "low_row_prob": args.low_row_prob,
        },
        "b1": {
            "target_percentile": args.b1_percentile,
            "threshold_fp_per_tile_core": b1_threshold_fp.tolist(),
            "threshold_int_per_tile_core": b1_threshold_int.tolist(),
            "actual_keep_ratio": float(b1_keep.to(torch.float32).mean().item()),
            "actual_skip_ratio": float((1.0 - b1_keep.to(torch.float32)).mean().item()),
            "per_tile_core_keep_ratio": b1_keep.to(torch.float32).mean(dim=(-1, -2)).tolist(),
        },
        "b2_only": {
            "target_percentile": args.b2_percentile,
            "threshold_fp_per_tile_core": b2_only_threshold_fp.tolist(),
            "threshold_int_per_tile_core": b2_only_threshold_int.tolist(),
            "actual_keep_ratio": float(b2_only_keep.to(torch.float32).mean().item()),
            "actual_skip_ratio": float((1.0 - b2_only_keep.to(torch.float32)).mean().item()),
            "per_tile_core_keep_ratio": b2_only_keep.to(torch.float32).mean(dim=-1).tolist(),
        },
        "b2": {
            "target_percentile": args.b2_percentile,
            "threshold_fp_per_tile_core": b2_threshold_fp.tolist(),
            "threshold_int_per_tile_core": b2_threshold_int.tolist(),
            "actual_keep_ratio": float(b2_keep.to(torch.float32).mean().item()),
            "actual_skip_ratio": float((1.0 - b2_keep.to(torch.float32)).mean().item()),
            "per_tile_core_keep_ratio": b2_keep.to(torch.float32).mean(dim=-1).tolist(),
        },
    }

    with (out_dir / "manifest.json").open("w", encoding="utf-8") as fh:
        json.dump(summary, fh, indent=2)
        fh.write("\n")

    print(json.dumps(summary, indent=2))


if __name__ == "__main__":
    main()
