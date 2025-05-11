# Mosne Seestar rsync
# copy (whith resume) using rsync exludiing jpg. 
# usage:
# 0. edit the variable  
# local storage_path="/Volumes/T7/astroVault/s30" with you desired path
# 1. go to you seestar forder. For example:
# cd /Volumes/EMMC\ Images/MyWorks/M\ 106_sub
# 2. lunch the command s30 [destination] i use [object]-[location]-[date] For example:
# s30 ic443-par-s30-2025-04-11
# 3. the script will create the light folder for you and sync all fits files.
# 4. enjoy !
#
# It requires rsync 
# brew install rsync

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
