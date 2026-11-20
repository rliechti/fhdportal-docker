#!/usr/bin/env bash
# Makes a complete test submission for the demonstrator: a metadata bundle (zip) and the matching encrypted data files.
#
#   scripts/make-test-bundle.sh <your e-mail> [options of create_test_bundle.php]
#
#   scripts/make-test-bundle.sh you@example.org              2 patients, a random cancer type, a name made of the date
#   scripts/make-test-bundle.sh you@example.org -p 5 -c lung -n DEMO-LUNG       (php e2e/create_test_bundle.php -h lists the options)
#
# It writes   bundles/<name>/<name>.zip   (upload it with "Large Submissions in Batch")
# and         sda-inbox/<your e-mail>/*.c4gh   (the data files: random bytes under the right names, which is all the fake archive checks)
# <your e-mail> is the address with which you registered in the portal: the files belong to that user.
# The generator is the one of the end-to-end test (e2e/create_test_bundle.php). It runs on this machine if PHP has the zip extension,
# otherwise inside the API container. SDA_DIR and BUNDLES_DIR change the two folders.
set -euo pipefail
cd "$(dirname "$0")/.."
[ $# -ge 1 ] || { sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'; exit 2; }
email="$1"; shift
case "$email" in *@*.*) ;; *) echo "'$email' is not an e-mail address" >&2; exit 2 ;; esac
case "$email" in */*|*..*) echo "'$email' is not usable as a folder name" >&2; exit 2 ;; esac
sda="${SDA_DIR:-sda-inbox}"; bundles="${BUNDLES_DIR:-bundles}"

name=""; prev=""
for a in "$@"; do [ "$prev" = "-n" ] && name="$a"; prev="$a"; done
if [ -z "$name" ]; then name="DEMO-$(date +%y%m%d-%H%M%S)"; set -- -n "$name" "$@"; fi
case "$name" in *[!A-Za-z0-9_-]*) echo "the name may hold letters, digits, - and _ only: $name" >&2; exit 2 ;; esac
mkdir -p "$bundles" "$sda/$email"

if command -v php >/dev/null 2>&1 && php -r 'exit(class_exists("ZipArchive") ? 0 : 1);' 2>/dev/null; then
  php e2e/create_test_bundle.php -z -o "$bundles" "$@"
else
  echo "(no PHP with the zip extension here: running the generator in the API container, which must be up)"
  docker compose exec -T api php /api/e2e/create_test_bundle.php -z -o /api/bundles "$@"
fi

dir="$bundles/$name"
[ -f "$dir/$name.zip" ] && [ -f "$dir/file_sizes.tsv" ] || { echo "the generator did not produce $dir/$name.zip" >&2; exit 1; }
n=0
while IFS=$'\t' read -r file _; do
  [ -n "$file" ] || continue
  head -c $((512 + RANDOM % 1024)) /dev/urandom > "$sda/$email/$file"
  n=$((n + 1))
done < "$dir/file_sizes.tsv"

echo
echo "bundle : $dir/$name.zip"
echo "files  : $n data files in $sda/$email/"
echo "next   : docker compose exec api php /var/www/fhd-portal/htdocs/api/tools/cron_sda.php    (or wait a minute: the files get listed),"
echo "         then upload the zip with \"Large Submissions in Batch\" in the Submitter portal."
