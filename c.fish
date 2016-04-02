# vim: ft=sh
function c
    set -l OPT_ADD false
    set -l OPT_KEY ""
    set -l OPT_REMOVE false
    set -l OPT_GO false
    set -l OPT_PRINT false
    set -l OPT_HELP false
    set -l i 1
    while math "$i <=" (count $argv) > /dev/null
        switch $argv[$i]
            case -g --go
                set OPT_GO true
                set i (math "$i + 1")
                set OPT_KEY "$argv[$i]"
            case -a --add
                set OPT_ADD true;
                set i (math "$i + 1")
                set OPT_KEY "$argv[$i]"
            case -r --remove
                set OPT_REMOVE true
                set i (math "$i + 1")
                set OPT_KEY "$argv[$i..-1]"
            case -p --print
                set OPT_PRINT true
                set i (math "$i + 1")
                set OPT_KEY "$argv[$i..-1]"
            case -h --help
                set OPT_HELP true
            case --
                set i (math "$i + 1")
            case -
                set ARGS -
                break
            case '-*'
                echo "Invalid option $argv[$i]"
                return 1
            case '*'
                set ARGS $argv[$i..-1]
                break
        end
        set i (math "$i + 1")
    end

    if eval $OPT_HELP
        echo "Change workspace"
        echo "Usage: c [options]"
        echo -e "List all the bookmarks entries"
        echo -e "Options:"
        echo -e "\t-g, --go [key]              Go to the directory specified by the key"
        echo -e "\t-a, --add <key> [path]      Add the specified PATH assigning the ENTRY."
        echo -e "\t                            The entry key must contain alphanumeric and underscore chars."
        echo -e "\t                            The path is the current wd if PATH is not specified."
        echo -e "\t-r, --remove key            Remove an entry"
        echo -e "\t-p, --print key             Print the PATH entry (useful for pipe command)"
        echo -e "\t-h, --help                  Show this help message"
        return 0
    end

    set -l bookmarks_file $PEARL_HOME/bookmarks
    touch $bookmarks_file

    if eval $OPT_ADD
        # Checks first if key is an alphanumeric char
        if not echo "$OPT_KEY" | grep -q '^\w*$'
            echo "The entry key $OPT_KEY is not valid. It must only contain alphanumeric and underscore chars."
            return 128
        end

        set -l path $ARGS
        if test -z $path
            set path .
        end

        set -l abs_path (readlink -f $path)
        if [ ! -d "$abs_path" ]
            echo "$abs_path is not a directory."
            return 128
        end
        echo "$OPT_KEY:$abs_path" >> "$bookmarks_file"
    else if eval $OPT_REMOVE
        if not grep -q "^$OPT_KEY:.*" $bookmarks_file
            echo "The key $OPT_KEY does not exist."
            return 1
        end
        sed -ie "/$OPT_KEY:.*/d" "$bookmarks_file"
    else if eval $OPT_PRINT
        set -l path (grep "^$OPT_KEY:.*" $bookmarks_file | cut -d: -f2)
        [ "$path" = "" ]; and return 1
        echo "$path"
    else if eval $OPT_GO
        set -l path (grep "^$OPT_KEY:.*" $bookmarks_file | cut -d: -f2)
        builtin cd "$path"
    else
        if [ "$ARGS" != "" ]
            cd $ARGS
        else
            sed -e 's/:/) /' $bookmarks_file
        end
    end
    return 0
end
