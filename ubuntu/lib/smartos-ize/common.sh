
# set -e -x


PATH=$PATH:/lib/smartos-ize

log() {
	printf "$@\n"
}

fatal() {
	printf "$@\n"
	exit 1
}
