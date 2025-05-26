# deploy.sh
#!/bin/bash

hugo

cd public
git init
git remote add origin git@github.com:weita0/weita0.github.io.git
git add .
git commit -m "Deploy $(date)"
git push -f origin master
