# This function is a wrapper for cd including some functionalities
function c() {
    #################### BEGIN OPTION PARSING ############################
    local OPT_ADD=false
    local OPT_KEY=""
    local OPT_REMOVE=false
    local OPT_GO=false
    local OPT_PRINT=false
    local OPT_HELP=false
    for opt in "$@"
    do
	case $1 in
            -g|--go) shift; OPT_GO=true; OPT_KEY="$1" ; shift ;;
            -a|--add) shift; OPT_ADD=true; OPT_KEY="$1" ; shift ;;
            -r|--remove) shift; OPT_REMOVE=true; OPT_KEY="$1" ; shift ;;
	    -p|--print) shift; OPT_PRINT=true; OPT_KEY="$1" ; shift ;;
            -h|--help) OPT_HELP=true ; shift ;;
            --) shift ; break ;;
            -) break ;;
            -*) echo "Invalid option $1" ;;
            *) break ;;
	esac
    done

    ARGS=()
    for arg in "$@"
    do
        ARGS+=("$arg")
    done

    if $OPT_HELP
    then
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
    fi

    #################### END OPTION PARSING ############################

    local bookmarks_file="$PEARL_HOME/bookmarks"
    touch $bookmarks_file

    if $OPT_ADD
    then
        # Checks first if key is an alphanumeric char
        if ! echo "$OPT_KEY" | grep -q '^\w*$'
        then
            echo "The entry key $OPT_KEY is not valid. It must only contain alphanumeric and underscore chars."
            return 128
        fi

        local path=${ARGS}
        if [ -z "$path" ]; then
            local path="."
        fi

        local abs_path=$(readlink -f "$path")
        if [ ! -d "$abs_path" ]; then
            echo "$abs_path is not a directory."
            return 128
        fi
        echo "$OPT_KEY:$abs_path" >> "$bookmarks_file"

    elif $OPT_REMOVE
    then
        if ! grep -q "^${OPT_KEY}:.*" $bookmarks_file
        then
            echo "The key ${OPT_KEY} does not exist."
            return 1
        fi
        sed -ie "/$OPT_KEY:.*/d" "$bookmarks_file"
    elif $OPT_PRINT
    then
        local path=$(grep "^${OPT_KEY}:.*" $bookmarks_file | cut -d: -f2)
        [ "$path" == "" ] && return 1
        echo "$path"
    elif $OPT_GO
    then
        local path=$(grep "^${OPT_KEY}:.*" $bookmarks_file | cut -d: -f2)
        builtin cd "$path"
    else
        if [ "$ARGS" != "" ]
        then
            builtin cd "$ARGS"
        else
            sed -e 's/:/) /' $bookmarks_file
        fi
    fi
    return 0;
}
