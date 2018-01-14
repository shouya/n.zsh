#
# requirements:
#   - ripgrep
#   - ranger
#   - fzf (optional)
#
# configs:
#   - NOTE_PATH
#

CONFIG_FILE=${CONFIG_FILE:-$HOME/.config/n.conf}
[[ -f "$CONFIG_FILE" ]] && source "$CONFIG_FILE"

_n() {
    local -a commands
    commands=(
        'new:Create new note'
        'ls:List notes'
        'edit:Edit note'
        'cat:View note'
        'manage:Manage notes with ranger'
        'grep:Full text search in notes (with rg)'
        'filter:Filter by tag'
    )

    _arguments \
        '1:cmd:->cmds' \
        '*:: :->args'

    case "$state" in
        cmds)
            _describe -V 'Commands' commands
            ;;
        args)
            local cmd
            cmd=$line[1]

            _n/command "$cmd"
            ;;
    esac
}

_n/command() {
    local cmd
    cmd="$1"

    case "$cmd" in
        new)
            _message 'Note filename'
             ;;
        ls)
            _message 'None'
            ;;
        filter)
            local tag_info tag_name tag_count
            local -a tag_completion
            local IFS=$'\n'
            for tag_info in $(n api tags); do
                tag_name="${tag_info#* }"
                tag_count="${tag_info% *}"
                tag_completion+=("$tag_name:filter by tag $tag_name ($tag_count)")
            done
            _describe -V 'Select tag' tag_completion
            ;;

        edit|cat)
            local -a note_completion
            local file filename no
            local IFS=$'\n'
            for file in $(n api notes); do
                file="$file:"
                filename="${file#*:}"
                no="${file%:*}"
                trimmed_filename=$(basename ${filename%.*})
                trimmed_filename="${trimmed_filename//:/\\:}"
                note_completion+=("$trimmed_filename:Edit $trimmed_filename")
            done
            _describe -2V 'Select note' note_completion
            ;;

        grep)
            _rg
            ;;

        *)
            ;;
    esac
}


n() {
    local cmd note_path note_file tagdb template tagdb_content

    note_path="${NOTE_PATH:-$HOME/Documents/notes}"
    tag_index="$note_path/.tag_index"
    template="$note_path/.template"

    cmd="$1"; shift
    case "$cmd" in
        new)
            local note_name

            note_name="$1"
            note_file="$note_path/$note_name"

            if [[ "$note_file" != *.* ]]; then
                note_file+="${NOTE_DEFAULT_EXT:-.md}"
            fi

            if [[ ! -e "$note_file" ]]; then
                [[ ! -e "$template" ]] && touch "$template"
                cp -f "$template" "$note_file"
            fi

            ranger --selectfile="$note_file" "$(dirname "$note_file")"

            n/refresh_tag_if_needed "$note_path" "$tag_index"
            ;;

        ls)
            local line filename tag_str i filter delimiter out_line
            local -a outputs
            i=0
            n/refresh_tag_if_needed "$note_path" "$tag_index"

            [[ "$1" = "-filter="* ]]    && filter="${1#-filter=}"       && shift
            [[ "$1" = "-delimiter="* ]] && delimiter="${1#-delimiter=}" && shift

            cat "$tag_index" | grep -v '^#' | while read line; do
                filename="${line%*:}"
                tag_str="${line#*:*}"
                trimmed_filename="$(basename ${filename%.*})"

                [[ -n "$filter" && "$tag_str" != *"$filter"* ]] && continue

                i=$((i+1))

                out_line="$(print -Pn "%F{yellow}$i%f"$'\t')"
                out_line="$out_line$(print -Pn "%U$trimmed_filename%u"$'\t')"
                out_line="$out_line$(print -P  "%F{green}$tag_str%f")"

                outputs+=("$out_line")
            done


            if [[ -n "$delimiter" ]]; then
                # remove colors & styles
                print -l $outputs | \
                    sed "s,$(printf '\033')\\[[0-9;]*[a-zA-Z],,g" | \
                    tr $'\t' "$delimiter"
            else
                print -l $outputs | column -t -s $'\t'
            fi

            ;;

        manage)
            ranger "$note_path"

            n/refresh_tag_if_needed "$note_path" "$tag_index"
            ;;

        filter)
            local tag
            tag="$1"

            [[ -z "$tag" ]] && {
                echo 'Please specify a tag to filter on'
                return
            }

            "$0" ls -filter="$tag"
            ;;

        grep)
            rg "$@" "$note_path"
            ;;

        refresh)
            rm -f "$tag_index"
            n/refresh_tag_if_needed "$note_path" "$tag_index"
            ;;

        edit)
            local note_name
            local -a selected_files

            while [[ -z "$1" ]]; do
                set -- $("$0" select-menu -multi)
            done

            for note_name in "$@"; do
                selected_files+=("$(n/note_name_to_file "$note_path" "$note_name")")
            done

            ${NOTE_EDITOR:-${EDITOR:-vim}} "${selected_files[@]}"

            n/refresh_tag_if_needed "$note_path" "$tag_index"
            ;;

        preview)
            loca
            note_name="$*"
            note_file="$(n/note_name_to_file "$note_path" "$note_name")"
            cat "$note_file"
            ;;

        cat)
            NOTE_EDITOR="${NOTE_VIEWER:-${PAGER:-less -F}}" "$0" edit "$@"
            ;;

        select-menu)
            local ns fzf_preview multi_select pattern line
            local -a note_list fzf_options
            n/refresh_tag_if_needed "$note_path" "$tag_index"

            [[ "$1" = "-multi" ]] && multi_select=yes && shift

            # fzf_preview="$0 preview \"{2..-2}\""
            # fzf_preview="eval echo {1}"
            fzf_options=('-1' '-0' '--reverse') # "--preview=\"$fzf_preview\"")

            [[ -n "$multi_select" ]] && fzf_options+=(-m)

            note_list=$("$0" ls -delimiter=:)
            print -l $note_list | column -t -s: | fzf "${fzf_options[@]}" | \
                awk '{print $1}' | while read line; do
                if [[ -z "$ns" ]]; then
                    ns+="$line"
                else
                    ns+="|$line"
                fi
            done
            print -l $note_list | grep -E "^($ns):" | cut -d: -f2
            ;;

        api)
            n/api "$note_path" "$tag_index" "$@"
            ;;

        *)
            echo "Unknown command"
            ;;
    esac
}

n/scan_tag() {
    local note_file
    note_file="$1"

    grep "." "$note_file"                   | \
        tail -1                             | \
        grep -oh -E '#[a-zA-Z][a-zA-Z0-9]*' | \
        cut -c2-
}

n/refresh_tag_if_needed() {
    local note_path tag_index refresh f
    local -a files
    note_path="$1"
    tag_index="$2"
    IFS=$'\n' files=($(n/note_files "$note_path"))
    refresh=no

    if [[ ! -e "$tag_index" ]]; then
        refresh=yes
    else
        # if some file is newer than the index
        for f in $files; do
            [[ "$f" -nt "$tag_index" ]] && refresh=yes
        done
    fi

    [[ "$refresh" == no ]] && return

    # empty the file
    truncate --size=0 "$tag_index"

    for f in "${files[@]}"; do
        local -a tags
        tags=($(n/scan_tag "$f"))
        echo "$f:${(j:,:)tags}" >> "$tag_index"
    done
}

n/note_files() {
    local note_path
    note_path="$1"

    # normal files only
    # sort by modification date (in descending order)
    print -l "$1"/*(.om)
}

n/note_name_to_file() {
    local note_path note_name selected_file
    local -a selected_files

    note_path="$1"
    note_name="$2"

    [[ -z "$note_name" ]] && return

    selected_files=("$note_path/$note_name".*)

    if [[ "${#selected_files}" -lt 1 ]]; then
        echo 'Cannot find note with named ${selected_files[1]}}'
        return
    elif [[ "${#selected_files}" -gt 1 ]]; then
        echo 'More than one notes matched'
        return
    fi

    selected_file="${selected_files[1]}"
    print "$selected_file"
}

n/api() {
    local note_path tag_index command
    note_path="$1"; shift
    tag_index="$1"; shift
    command="$1"; shift

    case "$command" in
        tags)
            local -a tags
            n/refresh_tag_if_needed "$note_path" "$tag_index"

            cat "$tag_index" | grep -v '^#' | while read line; do
                tag_str=${line#*:}
                tr ',' '\n' <<< "$tag_str"
            done | grep '.' | sort | uniq -c | awk '{print $1 " " $2}' | sort -g -r
            ;;

        notes)
            n/note_files "$note_path" | nl -s: -w1
            ;;

        *)
            echo "Unkonwn API [$command]"
            ;;
    esac
}

compdef _n n
