#!/usr/bin/env python3
import argparse
import hashlib
import json
import os
import pathlib
import shutil
import tempfile
import urllib.request


def checksum(path):
    digest = hashlib.sha256()
    with path.open("rb") as file:
        for chunk in iter(lambda: file.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def download(model, root):
    destination = root / model["directory"] / model["name"]
    destination.parent.mkdir(parents=True, exist_ok=True)

    if destination.exists() and checksum(destination) == model["sha256"]:
        print(f"using {destination}")
        return

    token_name = model.get("authEnv")
    request = urllib.request.Request(model["url"])
    if token_name and os.environ.get(token_name):
        request.add_header("Authorization", f"Bearer {os.environ[token_name]}")

    with tempfile.NamedTemporaryFile(dir=destination.parent, delete=False) as temporary:
        temporary_path = pathlib.Path(temporary.name)
        try:
            print(f"downloading {model['name']}")
            with urllib.request.urlopen(request) as response:
                shutil.copyfileobj(response, temporary)
            if checksum(temporary_path) != model["sha256"]:
                raise RuntimeError(f"checksum mismatch for {model['name']}")
            temporary_path.replace(destination)
        finally:
            temporary_path.unlink(missing_ok=True)


parser = argparse.ArgumentParser()
parser.add_argument("--manifest", type=pathlib.Path, required=True)
parser.add_argument("--root", type=pathlib.Path, required=True)
arguments = parser.parse_args()

with arguments.manifest.open() as manifest_file:
    manifest = json.load(manifest_file)

for model in manifest:
    try:
        download(model, arguments.root)
    except Exception:
        if model.get("required", True):
            raise
        print(f"skipping optional model {model['name']}")
