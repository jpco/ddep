#!/bin/bash

# DDEP: just another dotfiles deployment script.
# Supports syncing files in subdirectories (e.g., I want my .vim/plugins,
# but not .vim/backups).

[[ -z $DF_DIR ]] && DF_DIR="$HOME/dotfiles/"
[[ -z $DF_BRANCH ]] && DF_BRANCH="master"

DEP_ACTION="ln -s"

usage() {
    echo "Usage: ddep [command] [file]"
    echo "Commands:"
    echo -e "\tinstall: installs (symlinks) ddep to wherever 'env' is located"
    echo -e "\tuninstall: unlinks ddep from wherever 'env' is located"
    echo -e "\tdeploy: symlinks dotfiles to home"
    echo -e "\tadd [file]: adds file to dotfiles"
    echo -e "\trm [file]: removes file from dotfiles"
    echo -e "\tpull: pulls dotfiles repository from github"
    echo -e "\tpush: commits & pushes dotfiles repository to github"
}

install() {
    BIN_DIR=`env | grep ^_ | cut -d= -f2 | rev | cut -d/ -f1 --complement | rev`
    ln -s "`pwd`/ddep.sh" "$BIN_DIR/ddep"
}

uninstall() {
    BIN_DIR=`env | grep ^_ | cut -d= -f2 | rev | cut -d/ -f1 --complement | rev`
    unlink "$BIN_DIR/ddep"
}

deploy_f() {
    dest=`realpath -s $2`
    if [[ -z `grep ${dest:${#HOME}+1} $DF_DIR/.dfreg` ]]; then
        echo "ddep: File $dest not found in dotfiles."
        exit 1
    fi

    src="$DF_DIR/home/${dest:2+${#HOME}}"
    if [[ -e $dest ]]; then
        if [[ ! -e $DF_DIR/stash ]]; then
            echo "ddep: Creating stash"
            mkdir "$DF_DIR/stash"
        fi
        if [[ -L $dest ]]; then
            echo -n "ddep: Unlinking $dest "
            echo "(points to `realpath $dest`)"
            unlink "$dest"
        else
            stashdest="$DF_DIR/stash/${dest:2+${#HOME}}"
            sdirs=`echo ${stashdest%/*} | tr "/" "\n"`
            cdest=""
            for sdir in $sdirs; do
                if [[ ! -d "$cdest/$sdir" ]]; then
                    if [[ -e "$cdest/$sdir" ]]; then
                        echo "ddep: File conflict in the stash. Smashing old file (Sorry!)"
                        rm -rf "$cdest/$sdir"
                    fi

                    mkdir "$cdest/$sdir"
                fi

                cdest="$cdest/$sdir"
            done

            mv -f "$dest" "$stashdest"
            stashed=yes
        fi
        if [[ $? -ne 0 ]]; then
            echo "ddep: Could not clear destination."
            echo "ddep: Problematic file: $dest"
            exit 1
        fi
    fi
    
    # dirs between ~ and the desired dotfile
    tdirs=`echo ${dest%/*} | tr "/" "\n"`
    cdest=""
    for tdir in $tdirs; do
        if [[ ! -d "$cdest/$tdir" ]]; then
            if [[ -e "$cdest/$tdir" ]]; then
                echo "ddep: Conflicting file $cdest/$tdir in \$HOME."
                exit 1
            fi

            mkdir "$cdest/$tdir"
        fi

        cdest="$cdest/$tdir"
    done
    $DEP_ACTION "$src" "$dest"

    if [[ $stashed = yes && $1 = '-y' ]]; then
        echo "ddep: Files stashed during deployment."
        echo "ddep: Review them in ${DF_DIR}stash."
    fi
}

deploy() {
    stashed=no
    for dest in `cat $DF_DIR/.dfreg`; do
        deploy_f -n $dest
    done

    if [[ $stashed = yes ]]; then
        echo "ddep: Files stashed during deployment."
        echo "ddep: Review them in ${DF_DIR}stash."
    fi
}

add() {
    path=`realpath -e $1 2> /dev/null`
    if [[ $? -eq 1 ]]; then
        echo "ddep: File does not exist."
        exit 1
    fi
    if [[ `expr match "$path" "$HOME"` -eq 0 ]]; then
        echo "ddep: File must be under home."
        exit 1
    fi

    hname=${path:1+${#HOME}}
    name=`basename "$path"`

    if [[ -z "$hname" ]]; then
        echo "ddep: File must be under home."
        exit 1
    fi

    if [[ `expr match "$hname" "\."` -eq 0 ]]; then
        echo "ddep: Under-home file component must begin with .!"
        exit 1
    fi

    nhname="${hname:1}"
    if [[ $name = $hname ]]; then
        name=${name:1}
    fi

    if [[ ! -d "$DF_DIR/home" ]]; then
        echo "ddep: Creating \$DF_DIR/home directory"
        mkdir "$DF_DIR/home"
    fi

    # dirs between ~ and the desired dotfile
    tdirs=`echo ${nhname%/*} | tr "/" "\n"`
    if [[ "$tdirs" = "$nhname" && ! -d "$HOME/.$tdirs" ]]; then
        tdirs=
    fi

    dest="$DF_DIR/home"
    for tdir in $tdirs; do
        if [[ $tdir = ${hname#/} ]]; then
            tdir=${tdir:1}
        fi
        if [[ ! -d "$dest/$tdir" ]]; then
            if [[ -e "$dest/$tdir" ]]; then
                echo "ddep: Conflicting file in \$DF_DIR directory."
                exit 1
            fi

            mkdir "$dest/$tdir"
        fi

        dest="$dest/$tdir"
    done

    mv "$path" "$dest/$name" && \
    ln -s "$dest/$name" "$path"
    echo "${path:${#HOME}+1}" >> $DF_DIR/.dfreg
}

remove() {
    path=`realpath -se $1 2> /dev/null`
    spath=${path:${#HOME}+1}
    df="$DF_DIR/home/${path:2+${#HOME}}"

    if [[ ! -z `grep "$spath" $DF_DIR/.dfreg` ]]; then
        unlink "$path" && mv "$df" "$path"
        cdfdir=${df%/*}
        while [[ $cdfdir != $DF_DIR/home ]]; do
            if [[ -z `ls -A $cdfdir` ]]; then
                rmdir $cdfdir
                cdfdir=${cdfdir%/*}
            else
                break
            fi
        done
        grep -v "$spath" "$DF_DIR/.dfreg" > "$DF_DIR/.ndfreg"
        mv "$DF_DIR/.ndfreg" "$DF_DIR/.dfreg"
    else
        echo "ddep: Could not find file in dotfiles dir."
    fi
}

pull() {
    cd "$DF_DIR"
    git pull
    cd -
}

push() {
    cd "$DF_DIR"
    git add home && git commit -m "ddep commit `date`" \
    && git push origin $DF_BRANCH
    cd -
}

case $1 in
    install)
        install
        ;;
    uninstall)
        uninstall
        ;;
    deploy)
        if [[ $# -eq 1 ]]; then
            deploy
        else
            deploy_f -y $2
        fi
        ;;
    cp-deploy)
        DEP_ACTION=cp
        if [[ $# -eq 1 ]]; then
            deploy
        else
            deploy_f -y $2
        fi
        ;;
    add)
        if [[ $# -eq 1 ]]; then
            echo "ddep: Missing filename."
            exit 1
        fi
        add $2
        ;;
    rm)
        if [[ $# -eq 1 ]]; then
            echo "ddep: Missing filename."
            exit 1
        fi
        remove $2
        ;;
    pull)
        pull
        ;;
    push)
        push
        ;;
    *)
        usage
        ;;
esac
