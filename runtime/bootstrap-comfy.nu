def fail [message: string, code: int = 1] {
  print -e $message
  exit $code
}

def metadata [remote: string] {
  try {
    ^nix flake metadata $remote --json | from json
  } catch {
    fail $"unable to resolve flake metadata for ($remote)"
  }
}

def cached-runtime [state: path] {
  let revisionFile = ($state | path join "locked-revision")
  if not ($revisionFile | path exists) {
    return null
  }
  let revision = (open $revisionFile | str trim)
  let runtime = ($state | path join "runtime" $"($revision).nu")
  if ($runtime | path exists) { $runtime } else { null }
}

def fetch-runtime [state: path, locked: record] {
  if $locked.type != "github" {
    fail "NIX_COMFY_FLAKE must resolve to a GitHub flake"
  }
  let revision = $locked.rev
  let runtimeDir = ($state | path join "runtime")
  let runtime = ($runtimeDir | path join $"($revision).nu")
  if ($runtime | path exists) {
    return $runtime
  }
  mkdir $runtimeDir
  let url = $"https://raw.githubusercontent.com/($locked.owner)/($locked.repo)/($revision)/runtime/nix-comfy.nu"
  print $"fetching runtime CLI ($revision)"
  try {
    let temporary = ($runtimeDir | path join $".($revision).next")
    http get $url | save -f $temporary
    mv -f $temporary $runtime
  } catch {
    rm -f ($runtimeDir | path join $".($revision).next")
    fail $"unable to fetch runtime CLI from ($url)"
  }
  $runtime
}

def main [...args: string] {
  let workspace = ($env.COMFYUI_WORKSPACE? | default "/workspace")
  let remote = ($env.NIX_COMFY_FLAKE? | default "github:DutchGerman/comfyui-nix-flake/master")
  # Configure Nix before resolving the flake; bootstrap metadata lookup happens
  # before the fetched runtime can apply its own environment.
  $env.NIX_REMOTE = "local"
  $env.NIX_CONFIG = (($env.NIX_CONFIG? | default "") + "
  experimental-features = nix-command flakes
  sandbox = false
  build-users-group =")
  let state = ($workspace | path join ".nix-comfy")
  mkdir $state $workspace
  let command = ($args | get 0? | default "")
  let fallback = ($env.NIX_COMFY_FALLBACK? | default "")
  mut runtime = (cached-runtime $state)

  if $command in ["profiles", "install"] {
    let locked = (metadata $remote).locked
    $runtime = (fetch-runtime $state $locked)
  } else if $runtime == null {
    if not ($fallback | is-empty) {
      $runtime = $fallback
    } else {
      let locked = (metadata $remote).locked
      $runtime = (fetch-runtime $state $locked)
    }
  }

  if $runtime == null {
    fail "runtime CLI is unavailable"
  }
  ^nu $runtime ...$args
}
