#!/bin/bash
set -Eeuo pipefail
umask 077

result=${TKL_TEST_RESULT:?TKL_TEST_RESULT is required}
app_password=${TKL_TEST_APP_PASS:?TKL_TEST_APP_PASS is required}
base=https://localhost
cookie=/tmp/tkl-omeka-cookie.$$
page=/tmp/tkl-omeka-page.$$
headers=/tmp/tkl-omeka-headers.$$
create_script=/tmp/tkl-omeka-create.$$.php

cleanup() {
    rm -f -- "$cookie" "$page" "$headers" "$create_script"
}
trap cleanup EXIT
trap 'status=$?; echo "Omeka acceptance failed at line $LINENO (status $status)" >&2; exit "$status"' ERR

systemctl --quiet is-active apache2.service mariadb.service postfix.service cron.service
systemctl --quiet is-enabled apache2.service mariadb.service postfix.service cron.service
apache2ctl -t
test "$(cd /var/www/omeka && php -r 'require "bootstrap.php"; echo OMEKA_VERSION;')" = 3.2.1

curl --insecure --fail --silent --show-error \
    --cookie "$cookie" --cookie-jar "$cookie" \
    "$base/admin/users/login" >"$page"
grep -Fq 'id="login-form"' "$page"
curl --insecure --fail --silent --show-error --location \
    --cookie "$cookie" --cookie-jar "$cookie" \
    --dump-header "$headers" --output "$page" \
    --data-urlencode 'username=admin' \
    --data-urlencode "password=$app_password" \
    --data-urlencode 'submit=Log In' \
    "$base/admin/users/login"
grep -Fq '/admin/users/logout' "$page"
grep -Fq 'Dashboard' "$page"

cat >"$create_script" <<'PHP'
<?php
chdir('/var/www/omeka');
require_once 'bootstrap.php';
require_once 'Omeka/Application.php';
$application = new Omeka_Application(APPLICATION_ENV);
$application->bootstrap([
    'Config', 'Logger', 'Db', 'Options', 'Pluginbroker', 'View', 'Locale',
]);
$admin = get_db()->getTable('User')->findBySql('username = ?', ['admin'], true);
$item = insert_item(
    ['public' => true, 'owner_id' => $admin->id],
    ['Dublin Core' => ['Title' => [[
        'text' => 'TurnKey v19 collection item',
        'html' => false,
    ]]]]
);
echo $item->id;
PHP
chmod 0644 "$create_script"
item_id=$(runuser -u www-data -- php "$create_script")
[[ $item_id =~ ^[0-9]+$ ]]
test "$(mariadb --batch --skip-column-names omeka --execute \
    "SELECT COUNT(*) FROM items WHERE id=$item_id AND public=1")" = 1
test "$(mariadb --batch --skip-column-names omeka --execute \
    "SELECT COUNT(*) FROM element_texts WHERE record_id=$item_id AND text='TurnKey v19 collection item'")" = 1
curl --insecure --fail --silent --show-error \
    "$base/items/show/$item_id" >"$page"
grep -Fq 'TurnKey v19 collection item' "$page"

systemctl restart mariadb.service apache2.service
systemctl --quiet is-active mariadb.service apache2.service
test "$(mariadb --batch --skip-column-names omeka --execute \
    "SELECT COUNT(*) FROM items WHERE id=$item_id AND public=1")" = 1
curl --insecure --fail --silent --show-error \
    "$base/items/show/$item_id" >"$page"
grep -Fq 'TurnKey v19 collection item' "$page"

password_hash=$(mariadb --batch --skip-column-names omeka --execute \
    "SELECT password FROM users WHERE username='admin'")
test "$(mariadb --batch --skip-column-names omeka --execute \
    "SELECT salt FROM users WHERE username='admin'")" = bcrypt
[[ $password_hash == '$2y$'* ]]
dpkg-query -W php8.4-cli php8.4-mysql php8.4-gd php8.4-xml \
    libapache2-mod-php8.4 mariadb-server imagemagick \
    webmin-apache webmin-mysql >/dev/null
curl --insecure --fail --silent --show-error --head https://127.0.0.1:12321/ >/dev/null
ss -ltn | grep -Eq '127\.0\.0\.1:25[[:space:]]'

release_json=$(curl --fail --silent --show-error \
    https://api.github.com/repos/omeka/Omeka/releases/latest)
grep -Fq '"tag_name": "v3.2.1"' <<<"$release_json"
grep -Fq 'sha256:2cb4d65511321cc5c009cb61516d9ed97378a800fc4a26eb46450c3c4ca230c2' \
    <<<"$release_json"
grep -Rqs '^Suites: trixie' /etc/apt/sources.list.d
! grep -Rqi bookworm /etc/apt/sources.list.d

cat >"$result" <<EOF
package_source=Debian 13 Trixie PHP, MariaDB, Apache and ImageMagick packages; official Omeka Classic 3.2.1 release archive
installed_version=Omeka Classic 3.2.1; PHP $(php -r 'echo PHP_VERSION;')
runtime_checks=normal init; Apache TLS; firstboot administrator web login and current password hash; published collection item creation, database readback and public display; restart persistence; Webmin and local Postfix
updater_command=back up the database; replace the application tree with a reviewed official release while preserving db.ini, files, plugins, themes and local config; complete any prompted /admin/upgrade migration
updater_result=official latest release endpoint returned v3.2.1 and the build archive digest
updater_channel=official Omeka Classic releases and documented supervised database upgrade
integrity_evidence=build and runtime verify GitHub's release-asset SHA-256 2cb4d65511321cc5c009cb61516d9ed97378a800fc4a26eb46450c3c4ca230c2; Debian metadata is signed; no Bookworm source remained
EOF
