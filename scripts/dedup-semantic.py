#!/usr/bin/env python3
# dedup-semantic.py — Semantic deduplication for Obsidian vault notes
# Usage: python3 dedup-semantic.py [vault_path] [--threshold 0.85] [--dry-run]
# Requires: pip install sentence-transformers (optional, falls back to Jaccard)

import sys
import os
import re
import json
import argparse
from pathlib import Path
from collections import defaultdict

VAULT = Path(os.path.expanduser("~/KnowledgeBase"))
THRESHOLD = 0.85
DRY_RUN = False
USE_EMBEDDINGS = False
MODEL = None

try:
    from sentence_transformers import SentenceTransformer
    import numpy as np
    USE_EMBEDDINGS = True
except ImportError:
    pass


def extract_text(filepath: Path) -> tuple[str, str, str]:
    content = filepath.read_text(encoding="utf-8", errors="ignore")
    frontmatter = {}
    if content.startswith("---"):
        parts = content.split("---", 2)
        if len(parts) >= 3:
            for line in parts[1].strip().split("\n"):
                if ":" in line:
                    k, v = line.split(":", 1)
                    frontmatter[k.strip()] = v.strip()
            content = parts[2]
    content = re.sub(r"```.*?```", "", content, flags=re.DOTALL)
    content = re.sub(r"\[\[.*?\]\]", "", content)
    content = re.sub(r"#+ ", " ", content)
    content = re.sub(r"\s+", " ", content).strip()
    title = frontmatter.get("title", filepath.stem)
    return title, content, str(filepath)


def load_vault(vault: Path) -> list[tuple[str, str, str]]:
    notes = []
    for f in vault.rglob("*.md"):
        rel = str(f.relative_to(vault))
        if rel.startswith(".obsidian") or rel.startswith("_templates"):
            continue
        title, text, path = extract_text(f)
        if len(text) > 50:
            notes.append((title, text, path))
    return notes


def jaccard_similarity(a: str, b: str) -> float:
    words_a = set(a.lower().split())
    words_b = set(b.lower().split())
    if not words_a or not words_b:
        return 0.0
    return len(words_a & words_b) / len(words_a | words_b)


def find_duplicates(notes: list, threshold: float) -> list[dict]:
    results = []
    if USE_EMBEDDINGS:
        model = SentenceTransformer("all-MiniLM-L6-v2")
        texts = [n[1][:2000] for n in notes]
        embeddings = model.encode(texts, show_progress_bar=True)
        for i in range(len(notes)):
            for j in range(i + 1, len(notes)):
                sim = float(np.dot(embeddings[i], embeddings[j]) /
                            (np.linalg.norm(embeddings[i]) * np.linalg.norm(embeddings[j])))
                if sim >= threshold:
                    results.append({
                        "note_a": notes[i][2],
                        "note_b": notes[j][2],
                        "title_a": notes[i][0],
                        "title_b": notes[j][0],
                        "similarity": round(sim, 4),
                        "method": "cosine-embedding"
                    })
    else:
        for i in range(len(notes)):
            for j in range(i + 1, len(notes)):
                sim = jaccard_similarity(notes[i][1], notes[j][1])
                if sim >= threshold:
                    results.append({
                        "note_a": notes[i][2],
                        "note_b": notes[j][2],
                        "title_a": notes[i][0],
                        "title_b": notes[j][0],
                        "similarity": round(sim, 4),
                        "method": "jaccard"
                    })
    return sorted(results, key=lambda r: r["similarity"], reverse=True)


def action_for_score(score: float) -> str:
    if score >= 0.95:
        return "MERGE (likely duplicate)"
    elif score >= 0.85:
        return "REVIEW (possibly related)"
    else:
        return "CHECK (low similarity)"


def main():
    parser = argparse.ArgumentParser(description="Semantic duplicate finder for Obsidian vaults")
    parser.add_argument("vault", nargs="?", default=str(VAULT), help="Vault path")
    parser.add_argument("--threshold", type=float, default=THRESHOLD, help="Similarity threshold (0-1)")
    parser.add_argument("--dry-run", action="store_true", help="Report only, no writes")
    parser.add_argument("--json", action="store_true", help="Output as JSON")
    args = parser.parse_args()

    vault = Path(os.path.expanduser(args.vault))
    if not vault.exists():
        print(f"Vault not found: {vault}", file=sys.stderr)
        sys.exit(1)

    print(f"Scanning vault: {vault}")
    print(f"Method: {'sentence-transformers (cosine)' if USE_EMBEDDINGS else 'Jaccard (fallback)'}")
    print(f"Threshold: {args.threshold}")
    print()

    notes = load_vault(vault)
    print(f"Loaded {len(notes)} notes with content > 50 chars")
    print()

    results = find_duplicates(notes, args.threshold)

    if args.json:
        print(json.dumps(results, indent=2, ensure_ascii=False))
    else:
        if not results:
            print("No near-duplicates found.")
        for r in results:
            action = action_for_score(r["similarity"])
            print(f"  [{r['similarity']:.3f}] {action}")
            print(f"    A: {r['title_a']} ({r['note_a']})")
            print(f"    B: {r['title_b']} ({r['note_b']})")
            print(f"    method: {r['method']}")
            print()

        print(f"Found {len(results)} potential duplicates (threshold={args.threshold})")


if __name__ == "__main__":
    main()
