#!/usr/bin/env python3
"""Fail closed on source or bundled approved-asset identity mismatches."""
from pathlib import Path
import argparse, hashlib, json
parser=argparse.ArgumentParser()
parser.add_argument('--app', type=Path)
args=parser.parse_args()
root=Path(__file__).resolve().parents[1]
folder=(args.app if args.app else root/'ios/LENOX')/'ApprovedAssets'
specs={
    'lenox-intro.mp4':(2278410,'85f30b59c4287db67d4123961bf3e77c22dae340d449e97845c5078eefece668'),
    'lenox-android-hero.png':(389384,'4a09a937f442b1d246b0f352f40f9e0bc4036ef37bb8d3d1ad4aeb0784564221'),
}
assert folder.is_dir() and not folder.is_symlink(), folder
assert {p.name for p in folder.iterdir()}==set(specs), 'Unexpected or missing resource'
for name,(size,digest) in specs.items():
    p=folder/name
    assert not p.is_symlink() and p.is_file(), p
    b=p.read_bytes()
    assert len(b)==size and hashlib.sha256(b).hexdigest()==digest, name
print(json.dumps({'approved_assets':'PASS','bundled_app_checked':bool(args.app),'assets':[{'path':k,'bytes':v[0],'sha256':v[1]} for k,v in specs.items()]}))
