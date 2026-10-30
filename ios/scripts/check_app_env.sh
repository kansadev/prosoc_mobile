#!/bin/sh
# Un build Release doit choisir son API explicitement (--dart-define=APP_ENV=dev|uat|prod) :
# sans cela l'application pointerait silencieusement en dev (voir lib/config/app_environment.dart).
[ "$CONFIGURATION" = "Release" ] || exit 0

decode() {
  printf '%s' "$1" | base64 --decode 2>/dev/null || printf '%s' "$1" | base64 -D
}

app_env=""
OLD_IFS=$IFS
IFS=','
for encoded in $DART_DEFINES; do
  define=$(decode "$encoded")
  case "$define" in
    APP_ENV=*) app_env=$(printf '%s' "${define#APP_ENV=}" | tr '[:upper:]' '[:lower:]') ;;
  esac
done
IFS=$OLD_IFS

case "$app_env" in
  dev|uat|prod)
    echo "Prosoc : build release pour APP_ENV=$app_env"
    ;;
  *)
    echo "error: APP_ENV manquant ou invalide (${app_env:-absent}) pour un build release. Ajoutez --dart-define=APP_ENV=dev|uat|prod, ex. : flutter build ipa --dart-define=APP_ENV=prod"
    exit 1
    ;;
esac
