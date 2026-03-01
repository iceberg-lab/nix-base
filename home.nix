{ config, lib, pkgs, ... }:

{
  options.hm-base = {
    gitName = lib.mkOption {
      type = lib.types.str;
      description = "Full name for git commits";
    };

    gitEmail = lib.mkOption {
      type = lib.types.str;
      description = "Email address for git commits";
    };
  };

  config = {
    home.stateVersion = "24.11";

    home.packages = with pkgs; [
      htop
      jujutsu
      zip
      unzip
    ];

    programs.home-manager.enable = true;

    # ── Git ─────────────────────────────────────────────────────────────
    programs.git = {
      enable = true;
      settings = {
        user.name = config.hm-base.gitName;
        user.email = config.hm-base.gitEmail;
        init.defaultBranch = "main";
      };
    };

    # ── Neovim ──────────────────────────────────────────────────────────
    programs.neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
    };

    # ── tmux ────────────────────────────────────────────────────────────
    programs.tmux = {
      enable = true;
      terminal = "tmux-256color";
      mouse = true;
      historyLimit = 50000;
      escapeTime = 0;
      baseIndex = 1;
      keyMode = "vi";
      prefix = "C-Space";
      extraConfig = ''
        # True color support
        set -ag terminal-overrides ",xterm-256color:RGB"

        # Split panes with intuitive keys
        bind | split-window -h -c "#{pane_current_path}"
        bind - split-window -v -c "#{pane_current_path}"

        # New windows keep current path
        bind c new-window -c "#{pane_current_path}"

        # Vi-style pane navigation
        bind h select-pane -L
        bind j select-pane -D
        bind k select-pane -U
        bind l select-pane -R

        # Resize panes with repeatable keys
        bind -r H resize-pane -L 5
        bind -r J resize-pane -D 5
        bind -r K resize-pane -U 5
        bind -r L resize-pane -R 5

        # Renumber windows when one is closed
        set -g renumber-windows on

        # Status bar
        set -g status-position top
        set -g status-style "fg=white,bg=default"
        set -g status-left "[#S] "
        set -g status-right "%H:%M"
      '';
    };

    # ── fzf (with shell integration) ────────────────────────────────────
    programs.fzf = {
      enable = true;
      enableZshIntegration = true; # Ctrl-R history search, Ctrl-T file search, Alt-C cd
    };

    # ── Zsh ─────────────────────────────────────────────────────────────
    programs.zsh = {
      enable = true;
      autosuggestion.enable = true;
      enableCompletion = true;
      syntaxHighlighting.enable = true;

      history = {
        size = 50000;
        save = 50000;
        ignoreDups = true;
        ignoreAllDups = true;
        share = true;
      };

      initContent = ''
        # ── Jujutsu prompt ──────────────────────────────────────────────
        __jj_prompt() {
          if ! jj root 2>/dev/null 1>/dev/null; then
            return
          fi

          local bookmark
          bookmark=$(jj log --no-graph -r @ -T 'bookmarks' 2>/dev/null)

          local change_id
          change_id=$(jj log --no-graph -r @ -T 'change_id.shortest(8)' 2>/dev/null)

          local dirty=""
          if [[ $(jj log --no-graph -r @ -T 'empty' 2>/dev/null) == "false" ]]; then
            dirty=" %F{yellow}*%f"
          fi

          local conflict=""
          if jj log --no-graph -r @ -T 'conflict' 2>/dev/null | grep -q 'true'; then
            conflict=" %F{red}conflict%f"
          fi

          local ref=""
          if [[ -n "$bookmark" ]]; then
            ref="%F{magenta}$bookmark%f"
          else
            ref="%F{yellow}$change_id%f"
          fi

          echo " ($ref''${dirty}''${conflict})"
        }

        setopt PROMPT_SUBST
        NEWLINE=$'\n'
        PROMPT='%F{green}%n@%m%f:%F{blue}%~%f$(__jj_prompt)''${NEWLINE}%# '
      '';
    };
  };
}
