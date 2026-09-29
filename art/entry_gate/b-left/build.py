"""Throwaway B placement study: reuse the approved candidate geometry at 1:1."""
import importlib.util
from pathlib import Path

ROOT = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location("ab_gate", ROOT.parent / "ab/build.py")
ab = importlib.util.module_from_spec(spec)
spec.loader.exec_module(ab)


def main():
    for name, x in (("left16", 3396), ("left24", 3388)):
        target = ROOT / name
        target.mkdir(exist_ok=True)
        ab.CANDIDATE_X = x  # Keep the deck foundation matched to actual world x.
        states = [("open", 0, False, False)]
        states += [(f"warning-{i}", depth, True, False)
                   for i, depth in enumerate((8, 16, 28, 44, 62, 80))]
        states += [("closed", 160, False, True)]
        for state, depth, warning, closed in states:
            art = ab.wall_variant(depth, warning, closed)
            art.image.save(target / f"{state}.png")
            (target / f"{state}.svg").write_text(
                '<svg xmlns="http://www.w3.org/2000/svg" width="128" height="288" '
                'viewBox="0 0 128 288" shape-rendering="crispEdges">\n'
                + '\n'.join(art.svg) + '\n</svg>\n', encoding="utf-8")
    print("B variants built at x3396/x3388; y263 and original geometry preserved")


if __name__ == "__main__":
    main()
