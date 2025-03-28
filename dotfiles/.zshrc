
export PATH=$PATH:$HOME/bin
export PATH=$PATH:/usr/local/sbin:/Users/jbowkett/bin

export TERM=xterm-256color

export TZ=UTC

alias whatfileschanged="git whatchanged master..HEAD | egrep '\.(rb|md)$' | awk '{ print $6 }' | sort | uniq"

alias gpoh="git push origin HEAD"
alias t="terraform"
#alias docker_this_term="eval \"$(docker-machine env default)\""
alias h=history
alias grep="grep -i --color"
alias vag="vagrant"
alias hosts="echo '' ; cat /etc/hosts | egrep -v '#|localhost'"
alias other="cd ~/other/"
alias ex="cd ~/Documents/Excelian"
alias capwin="screencapture -w -c -T5 -tjpg"
alias capture="screencapture -c -T5 -tjpg"
alias gti="git"
alias mci="mvn clean install"
alias subl="/Applications/Sublime\ Text.app/Contents/SharedSupport/bin/subl"
alias init_gradle="mkdir -p src/main/java && mkdir -p src/test/java && gradle init && echo apply plugin: \'idea\' >> build.gradle && gradle idea"
export PATH=/usr/local/bin:$PATH
export PATH=$PATH:/usr/local/opt/go/libexec/bin
alias g="gradle"
alias a="alias|grep '='"
alias coding="cd /Users/jbowkett/Coding/java-katas"
alias coding="cd /Users/jbowkett/Coding/blueprints/blueprint-microservices-mss"
alias javahome="echo $JAVA_HOME"
alias path="echo $PATH"

alias from="echo \$from"
alias to="echo \$to"
alias delete-merged-local-branches="git branch --merged | grep -v \* | xargs git branch -D"
alias delete-all-local-branches="git branch | grep -v \* | xargs git branch -D"
alias tag-date="git log -1 --format=%ai release-7.0.44-rc3-swg01131"
alias all-tag-date="git log --tags --simplify-by-decoration --pretty=\"format:%ai %d\" | grep -i tag | head -10"

#includes test compilation
alias skiptests="mvn -DskipTests clean install"

# alias tags_in_order="git tag --sort=-creatordate |head -10"
alias all_tags_in_order="git for-each-ref --sort=taggerdate --shell --format=\"%(taggerdate:format:%d-%m-%Y %H:%m) %(refname:short)\" refs/tags/*"

#export from=`git tag --sort=-creatordate |head -1`
export to=.
alias release-note="git log --format=%s $(echo \$from)..$(echo \$to) | sort -f | uniq -i | grep -v Merge"

export B2_ACCOUNT_ID="de8bc1f3f4fe"
export B2_ACCOUNT_KEY="0000e32a2cb26081c99f73717fd357fc663335e135"

