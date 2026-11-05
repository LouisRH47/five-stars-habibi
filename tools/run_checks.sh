#!/bin/bash
# Runs every automatic check on a throw-away copy of the project, so your real save and
# settings are never touched (tools/prepare_validation.py makes the copy).
#   tools/run_checks.sh            headless checks, smoke test and every focused test
#   tools/run_checks.sh --bots     ...plus the play-test bot, careful and careless
#   tools/run_checks.sh --only road_mesh,smoke   just those suites (names without _test.gd)
# It prints PASS or FAIL for each step and ALL CHECKS PASS at the end if everything passed.
# Set GODOT=/path/to/Godot if Godot isn't in /Applications or ~/Downloads.
set -u
cd "$(dirname "$0")/.."

if [ -z "${GODOT:-}" ]; then
	for app in /Applications/Godot.app "$HOME/Downloads/Godot.app"; do
		if [ -x "$app/Contents/MacOS/Godot" ]; then GODOT="$app/Contents/MacOS/Godot"; break; fi
	done
fi
if [ -z "${GODOT:-}" ]; then echo "Can't find Godot. Set GODOT=/path/to/Godot"; exit 2; fi

BOTS=0
ONLY=""
while [ $# -gt 0 ]; do
	case "$1" in
		--bots) BOTS=1 ;;
		--only) ONLY=",$2,"; shift ;;
	esac
	shift
done

TMP_ROOT="${TMPDIR:-/tmp}"
WORK=$(mktemp -d "${TMP_ROOT%/}/habibi-checks-XXXXXX")
LOGS="$WORK/logs"
mkdir -p "$LOGS"
PROJECT=$(python3 tools/prepare_validation.py "$WORK" | tail -1)
echo "Copy of the project: $PROJECT"
echo "Logs: $LOGS"
FAILED=0

wanted() { [ -z "$ONLY" ] || [[ "$ONLY" == *",$1,"* ]]; }

step() {  # step NAME [needs RESULT: PASS] -- godot args...
	local name=$1 need=$2; shift 2
	local log="$LOGS/$name.log"
	local start=$SECONDS
	"$GODOT" --path "$PROJECT" --headless "$@" >"$log" 2>&1
	local code=$?
	local ok=1
	[ $code -ne 0 ] && ok=0
	[ "$need" = "result" ] && ! grep -q "RESULT: PASS" "$log" && ok=0
	grep -qE "SCRIPT ERROR|Parse Error|Failed to load script" "$log" && ok=0
	if [ $ok -eq 1 ]; then
		echo "PASS  $name ($((SECONDS - start)) s)"
	else
		echo "FAIL  $name ($((SECONDS - start)) s)  -> $log"
		grep -E "FAIL|SCRIPT ERROR|Parse Error|ERROR" "$log" | head -8 | sed 's/^/      /'
		FAILED=1
	fi
}

step import any --import
step import-again any --import
step quit any --quit
if wanted smoke; then
	step smoke result --fixed-fps 60 -s tests/smoke_test.gd -- "--save-dir=$WORK/smoke-save"
fi
for test in tests/*_test.gd; do
	name=$(basename "$test" _test.gd)
	[ "$name" = "smoke" ] && continue
	wanted "$name" || continue
	step "$name" result --fixed-fps 60 -s "tests/${name}_test.gd"
done
if [ $BOTS -eq 1 ]; then
	step bot-careful any --fixed-fps 60 -s tests/playtest_bot.gd
	step bot-careless any --fixed-fps 60 -s tests/playtest_bot.gd -- careless
	for kind in careful careless; do
		echo "--- play-test bot ($kind) summary ---"
		tail -15 "$LOGS/bot-$kind.log"
	done
fi

if [ $FAILED -eq 0 ]; then echo "ALL CHECKS PASS"; else echo "SOME CHECKS FAILED"; fi
exit $FAILED
