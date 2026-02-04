#! /bin/env bash
HELP (){
    echo "Sync Utility"
    echo ""
    echo "This script is designed for private repositories that publish to a"
    echo "public read-only repository."
    echo ""
    echo "How to use:"
    echo ""
    echo "1) Create 'publish.txt' and list the files or directories to publish (one per line)."
    echo "2) Run: ./publish.sh URL [BRANCH]"
    echo "  - Arg 1: https://gitlab:TOKEN@github.com/user/repo.git or git@github.com:user/repo.git"
    echo "  - Arg 2: Target branch (e.g., master or dev)"
    echo "3) Optional: export SLACK_WEBHOOK=https://hooks.slack.com/services/A/B/C"
    echo "4) Optional: export SLACK_CHANNEL=general"
}

URL=$1
BRANCH=${BRANCH:=master}
DIR=publish
TXT=publish.txt
SLACK_CHANNEL=${SLACK_CHANNEL:=general}

if [ -z "$1" ];  then
    echo "Is required repo url"
    exit 1
fi
if [ $URL = "help" ] || [ $URL = "h" ] ; then
    HELP
    exit 1
fi
if [ ! -z "$2" ];  then
    BRANCH=$2
fi
if [ -d $DIR ]; then
    rm -fr $DIR
fi

if [ ! -f $TXT ]; then
    echo "Sorry, $TXT no exists."
    exit 1
fi

PUBLISH_LIST=()
git clone $URL -b $BRANCH $DIR
while IFS= read -r LINE
do
    LINE_COMMENT=${LINE:0:1}
    COMMENT=#
    if [ $LINE_COMMENT != $COMMENT ] ; then
        if [ -e $LINE ]; then
            echo "copy -r $LINE $DIR"
            cp -r $LINE $DIR
            PUBLISH_LIST+=($LINE)
        else
            echo "Don't exists $LINE"
        fi
    fi
done < ./$TXT


MSG=$(git show -s --format='%s')
cd $DIR

if [[ `git status --porcelain` ]]; then
    [[ ! $(git config --global user.email) ]] &&  git config --global user.email "no-reply@publish.bot"
    [[ ! $(git config --global user.name) ]] && git config --global user.name "Publish Bot"

    git add .
    git commit -m "$MSG"
    git push --set-upstream origin $BRANCH
    cd ..
    MSG_NOTIFY="Publish at branch: $BRANCH \n\n ${PUBLISH_LIST[*]}"
    echo $MSG_NOTIFY
    if [ ${#PUBLISH_LIST[@]} > 0 ]; then
        if [[ $SLACK_WEBHOOK ]]; then
            curl -X POST --data-urlencode "payload={\"channel\": \"#$SLACK_CHANNEL\", \"text\": \"${MSG_NOTIFY}\", }" $SLACK_WEBHOOK
        fi
    else
        echo "Any file was sync"
    fi
fi
