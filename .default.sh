CHISEL_LOCAL_PORT=${CHISEL_LOCAL_PORT:-5022}
CHISEL_REMOTE_PORT=${CHISEL_REMOTE_PORT:-2022}
CHISEL_APP_NAME="${CHISEL_APP_NAME:-cf-ssh-chisel-$USER-$CHISEL_LOCAL_PORT}"

for TMPDIR in $TMPDIR $TMP /var/tmp /tmp; do
  [ ! -d $TMPDIR ] || break # reverse test to not trip set -e
done
