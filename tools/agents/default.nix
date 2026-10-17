{ inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      jail = inputs.jail-nix.lib.init pkgs;
      inherit (jail) combinators;
      commonPkgs = with pkgs; [
        bashInteractive
        curl
        wget
        jq
        git
        which
        ripgrep
        gnugrep
        gawkInteractive
        ps
        findutils
        gzip
        unzip
        gnutar
        diffutils
        gnused
        nix
      ];
      commonCombinators = with combinators; [
        network
        (try-readonly (noescape "/nix/var/nix"))
        (try-readonly (noescape "/nix/store"))
        (set-env "NIX_CONFIG" ''
          extra-substituters = local?read-only=true&trusted=true
          experimental-features = nix-command flakes
          accept-flake-config = true
        '')
        (add-runtime ''RUNTIME_ARGS+=(--dir "/usr/bin" --symlink "${pkgs.coreutils}/bin/env" "/usr/bin/env")'')
        mount-cwd
        no-new-session
        (try-fwd-env "COLORTERM")
        (try-fwd-env "NO_COLOR")
        (try-fwd-env "TERM")
        (add-pkg-deps commonPkgs)
      ];
    in
    {
      packages.opencode = jail "opencode" pkgs.opencode (
        commonCombinators
        ++ (with combinators; [
          (add-runtime ''mkdir -p "$HOME/.config/opencode" "$HOME/.local/share/opencode"'')
          (try-readwrite (noescape "~/.config/opencode"))
          (try-readwrite (noescape "~/.local/share/opencode"))
        ])
      );

      packages.codex = jail "codex" pkgs.codex (
        commonCombinators
        ++ (with combinators; [
          (add-runtime ''mkdir -p "$HOME/.codex"'')
          (try-readwrite (noescape "~/.codex"))
        ])
      );

      packages.claude-code = jail "claude" pkgs.claude-code (
        commonCombinators
        ++ (with combinators; [
          (add-runtime ''mkdir -p "$HOME/.claude"; touch "$HOME/.claude.json"'')
          (try-readwrite (noescape "~/.claude"))
          (try-readwrite (noescape "~/.claude.json"))
        ])
      );
    };
}
