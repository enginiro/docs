#!/bin/bash

set -e

if ! [ -f phpdoc.phar ]; then
	wget -q -O phpdoc.phar 'https://github.com/phpDocumentor/phpDocumentor/releases/latest/download/phpDocumentor.phar'
fi

sed -i -E '/^  (- url|  start_path|  edit_url):/d' antora-playbook.yml
echo "  - url: ./" >> antora-playbook.yml
echo "    start_path: docs" >> antora-playbook.yml
echo "    edit_url: 'https://github.com/enginiro/$name/edit/{refname}/{path}'" >> antora-playbook.yml

mkdir -p build/site/phpdoc/

mkdir -p sources/
cd sources/

while read -r repository; do
	[ -z "$repository" ] && continue

	name="$(echo "$repository" | cut -d'/' -f2 | cut -d'.' -f1)"

	if [ -d "$name" ]; then
		cd "$name/"
		git pull
		cd ../
	else
		git clone --depth 1 "$repository" --branch "main" --single-branch
	fi

	cd "$name/"
	php ../../phpdoc.phar -t "../../build/site/phpdoc/$name/"
	cd ../

	echo "  - url: ./sources/$name" >> ../antora-playbook.yml
	echo "    start_path: docs" >> ../antora-playbook.yml
	echo "    edit_url: 'https://github.com/enginiro/$name/edit/{refname}/{path}'" >> ../antora-playbook.yml
done < ../repositories

cd ..

./node_modules/.bin/antora generate --fetch antora-playbook.yml
