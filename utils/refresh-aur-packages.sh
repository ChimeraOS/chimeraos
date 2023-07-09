# /bin/bash

source manifest
pushd "aur-pkgs/" > /dev/null
# remove all packages
git rm -- */ > /dev/null || git commit -m "Update AUR packages" > /dev/null

for package in ${AUR_PACKAGES}; do
    git submodule add --force https://aur.archlinux.org/${package}.git > /dev/null
done

git commit --amend -m "Update AUR packages" > /dev/null
echo "Updated AUR packages, use git push to push changes"
popd