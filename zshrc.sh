# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="ys"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"


## create a mdev alias that opens fork and cursor in the provided path if no path use current folder
mdev() {
    local path=$1
    if [ -z "$path" ]; then
        path="."
    fi
    /usr/bin/open -a Fork "$path"
    /usr/bin/open -a Cursor "$path"
}
#create a mbranch function that check if the current branch is the same of the param if not check if it is master or main and if so it will create a new branch with param as name and checkout to it 
mgit() {
    local branch=$1
    if [ -z "$branch" ]; then
        echo "Usage: mgit [branch]"
        return 1
    fi

    # Add issue/ prefix if not already present
    if [[ $branch != issue/* ]]; then
        branch="issue/$branch"
    fi

    # Get current branch name
    local current_branch=$(git branch --show-current)

    # If already on the requested branch, do nothing
    if [ "$current_branch" = "$branch" ]; then
        echo "Already on branch '$branch'"
        return 0
    fi

    # Check if branch exists
    if git show-ref --verify --quiet refs/heads/$branch; then
        # Branch exists, checkout to it
        git checkout $branch
    else
        # Branch doesn't exist, try to create from main/master
        if git show-ref --verify --quiet refs/heads/main; then
            git checkout main
            git pull origin main
            git checkout -b $branch
        elif git show-ref --verify --quiet refs/heads/master; then
            git checkout master
            git pull origin master
            git checkout -b $branch
        else
            echo "Neither 'main' nor 'master' branch found"
            return 1
        fi
    fi
}

#create a fucntion mmerge [targer] that take the current branch name and create a new branch form the target branch for example if current branch is issue/123 and target is main it will create a new branch from main named merge-issue-123-on-main and merge issue/123 into it
mmerge() {
    local target=$1
    local current_branch=$(git branch --show-current)
    local new_branch="merge-${current_branch//\//-}-on-$target"

    # Create new branch from target 
    git checkout $target
    git pull origin $target
    git checkout -b $new_branch
}
# create a function mphp that take a version and unlink php and link the provided version
mphp() {
    local version=$1
    if [ -z "$version" ]; then
        echo "Usage: mphp [version]"
        return 1
    fi
    brew unlink php && brew link --overwrite --force php@$version
    echo "PHP version set to $version"
    echo "export PATH=\"/opt/homebrew/opt/php@$version/bin:\$PATH\"" >> ~/.zshrc
    echo "export PATH=\"/opt/homebrew/opt/php@$version/sbin:\$PATH\"" >> ~/.zshrc
    source ~/.zshrc
}

s30() {
    local name=$1
    local dry_run=false
    
    # Check if name is provided
    if [ -z "$name" ]; then
        echo "Usage: s30 <name> [--dry]"
        return 1
    fi

    # Check if --dry option is provided as second argument
    if [ "$2" = "--dry" ]; then
        dry_run=true
    fi

    local storage_path="/Volumes/T7/astroVault/s30"
    #check if the storage path exists if not stop the script
    if [ ! -d "$storage_path" ]; then
        echo "Path $storage_path does not exist. Please connect the AstroVault (external drive T7) to your Mac."
        return 1
    fi

    local path="$storage_path/$name/lights"

    #check if the path exists
    if [ ! -d "$path" ]; then
        if [ "$dry_run" = false ]; then
            /bin/mkdir -p "$path"
            echo "Path $path created."
        else
            echo "[DRY RUN] Would create path: $path"
        fi
    else
        echo "Path $path already exists."
    fi
    
    echo "Copying .fit files from current directory to $path"
    
    #rsync the .fit files to the path with verbose output
    if [ "$dry_run" = true ]; then
        echo "[DRY RUN] Running rsync in simulation mode..."
        /opt/homebrew/bin/rsync -avn --include="*.fit" --include="*/" --exclude="*" ./ "$path"
    else
        /opt/homebrew/bin/rsync -av --include="*.fit" --include="*/" --exclude="*" ./ "$path"
    fi
    
    #check if the rsync command failed
    if [ $? -ne 0 ]; then
        echo "Rsync failed. Please try again."
        return 1
    else
        if [ "$dry_run" = true ]; then
            echo "[DRY RUN] Simulation completed - no files were actually copied"
        else
            echo "Files successfully copied to $path"
        fi
    fi
}

mosne() {
    echo "
░█▀▄▀█░▄▀▀▄░█▀▀░█▀▀▄░█▀▀
░█░▀░█░█░░█░▀▀▄░█░▒█░█▀▀
░▀░░▒▀░░▀▀░░▀▀▀░▀░░▀░▀▀▀
"
}

aichat () {
   #open cursor on the folder /Localsites/ai-chat and start a tab with a chat as editor using chatgpt-40 as model
   /usr/bin/open -a Cursor "/Users/paolo/LocalSites/ai-chat"
} 

update_setiastrosuite() {
    #run the update_setiastrosuite.sh script
    /Volumes/T7/astroapp/update_setiastrosuite.sh
}   
