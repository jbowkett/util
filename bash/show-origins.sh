for D in *;
do
	if [ -d "${D}" ]; then        
        pushd "${D}" > /dev/null
        export pwd=`pwd`
        # git remote show origin
        export url=`git config --get remote.origin.url`
        if [ -z "$url" ]
        then
        	echo "pwd ${pwd} => **INVESTIGATE** "
        # else
        	# echo # "pwd ${pwd} => ${url}"
        	# git status
        	# git push origin HEAD 
        fi
        echo "========================================================"
        # git status
        popd > /dev/null
    fi
done