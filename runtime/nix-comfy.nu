def fail [message: string, code: int = 1] {
  print -e $message
  exit $code
}

def run-command [command: string, args: list<string>] {
  let result = (do { ^$command ...$args } | complete)
  if $result.exit_code != 0 {
    print -e $result.stderr
    exit $result.exit_code
  }
  $result.stdout | str trim
}

def resolve-index [remote: string, indexFile: string, lockedRemote: string, lockedRevision: string] {
  let metadata = (run-command "nix" ["flake", "metadata", $remote, "--json"] | from json)
  if $metadata.locked.type != "github" {
    fail "NIX_COMFY_FLAKE must resolve to a GitHub flake"
  }

  let locked = $metadata.locked
  $"github:($locked.owner)/($locked.repo)/($locked.rev)\n" | save -f $lockedRemote
  $"($locked.rev)\n" | save -f $lockedRevision

  let indexPath = (run-command "nix" ["build", $"github:($locked.owner)/($locked.repo)/($locked.rev)#profile-index", "--no-link", "--print-out-paths"])
  cp $indexPath $indexFile
}

def profile-output [indexFile: string, profile: string] {
  let matches = (open $indexFile | where name == $profile)
  if ($matches | is-empty) {
    fail $"unknown profile: ($profile)" 2
  }
  $matches | get output | first
}

def valid-profile [profile: string] {
  $profile =~ '^[A-Za-z0-9._-]+$'
}

def main [...args: string] {
  let workspace = ($env.COMFYUI_WORKSPACE? | default "/workspace")
  let remote = ($env.NIX_COMFY_FLAKE? | default "github:DutchGerman/comfyui-nix-flake/master")
  let state = ($workspace | path join ".nix-comfy")
  mkdir $state $workspace

  # Runpod images do not have a Nix daemon. Use a local root store and append
  # these settings so an inherited value cannot override them.
  $env.NIX_REMOTE = "local"
  $env.NIX_CONFIG = (($env.NIX_CONFIG? | default "") + "
  experimental-features = nix-command flakes
  sandbox = false
  build-users-group =")

  let indexFile = ($state | path join "profile-index.json")
  let lockedRemote = ($state | path join "locked-flake")
  let lockedRevision = ($state | path join "locked-revision")

  let command = ($args | get 0? | default "")
  if $command in ["profiles", "install"] {
    let init = (do { ^nix-store --init } | complete)
    if $init.exit_code != 0 {
      fail "Nix local store is unavailable; provide a writable /nix store (or NIX_CONFIG store) before installing profiles"
    }
  }
  match $command {
    "profiles" => {
      resolve-index $remote $indexFile $lockedRemote $lockedRevision
      open $indexFile | each { |item| $item.name }
    }
    "install" => {
      let profile = ($args | get 1? | default "")
      if ($profile | is-empty) {
        fail "usage: nix-comfy install <profile>" 2
      }
      if not (valid-profile $profile) {
        fail $"invalid profile name: ($profile)" 2
      }

      resolve-index $remote $indexFile $lockedRemote $lockedRevision
      let output = (profile-output $indexFile $profile)
      let locked = (open $lockedRemote | str trim)
      let revision = (open $lockedRevision | str trim)
      let built = (run-command "nix" ["build", $"($locked)#($output)", "--no-link", "--print-out-paths"])
      let profilesRoot = ($workspace | path join "profiles")
      mkdir $profilesRoot
      let temporary = (mktemp -d ($profilesRoot | path join $".($profile).XXXXXX"))
      try {
        let root = $temporary
        mkdir ($root | path join "models") ($root | path join "workflows") ($root | path join "custom_nodes") ($root | path join "input") ($root | path join "output")
        cp ($built | path join "profile.json") ($root | path join "profile.json")
        let download = (which download-comfyui-models | get path.0?)
        if ($download | is-empty) {
          fail "model downloader is missing from the image"
        }
        run-command $download ["--manifest", ($built | path join "models.json"), "--root", ($root | path join "models")] | ignore
        ^cp -rL ($built | path join "workflows" ".") ($root | path join "workflows")
        ^cp -rL ($built | path join "input" ".") ($root | path join "input")
        ^cp -rL ($built | path join "custom_nodes" ".") ($root | path join "custom_nodes")
        $revision | save -f ($root | path join ".revision")
        touch ($root | path join ".complete")
        let current = ($profilesRoot | path join $profile)
        if (($current | path exists) and (($current | path type) != "symlink")) {
          mv $current ($profilesRoot | path join $".($profile).legacy.(random int 0..2147483647)")
        }
        rm -f ($profilesRoot | path join $".($profile).next")
        ln -s ($temporary | path basename) ($profilesRoot | path join $".($profile).next")
        mv -f ($profilesRoot | path join $".($profile).next") $current
      } catch { |error|
        rm -rf $temporary
        $error | print -e
        exit 1
      }
      rm -rf $temporary
      print $"installed ($profile) at ($revision)"
    }
    "start" => {
      mut profile = ($args | get 1? | default "")
      if (not ($profile | is-empty)) and not (valid-profile $profile) {
        fail $"invalid profile name: ($profile)" 2
      }
      if ($profile | is-empty) {
        let installed = (glob ($workspace | path join "profiles" "*") | where { |path| ($path | path type) == "symlink" })
        if ($installed | length) != 1 {
          fail $"specify a profile; installed profiles: (($installed | each { |path| $path | path basename }) | str join ', ' | default 'none')" 2
        }
        $profile = ($installed | first | path basename)
      }
      let root = ($workspace | path join "profiles" $profile)
      if not (($root | path join ".complete") | path exists) {
        fail $"profile ($profile) is not installed; run nix-comfy install ($profile)"
      }
      let profileData = (open ($root | path join "profile.json"))
      for item in ($profileData.runtime.environment? | default {} | transpose key value) {
        load-env {($item.key): $item.value}
      }
      let listen = ($env.COMFYUI_LISTEN? | default ($profileData.runtime.listen? | default "0.0.0.0"))
      let port = ($env.COMFYUI_PORT? | default ($profileData.runtime.port? | default 8188))
      let extraArgs = ($profileData.runtime.extraArgs? | default [])
      ^comfyui --listen $listen --port $port --base-directory $root ...$extraArgs ...($args | skip 2)
    }
    "status" => {
      for root in (glob ($workspace | path join "profiles" "*")) {
        let complete = ($root | path join ".complete")
        if ($complete | path exists) {
          let revision = (open ($root | path join ".revision") | str trim | default "unknown")
          print $"($root | path basename): ($revision)"
        }
      }
    }
    _ => {
      fail "usage: nix-comfy {profiles|install <profile>|start [profile]|status}" 2
    }
  }
}
