#!/bin/bash
set -eo pipefail

PHP_VERSION=""
LARAVEL_VERSION=""

while getopts "p:l:-:" opt; do
  optarg="$OPTARG"
  if [[ "$opt" = - ]]; then
    opt="-${OPTARG%%=*}"
    optarg="${OPTARG/${OPTARG%%=*}/}"
    optarg="${optarg#=}"
    if [[ -z "$optarg" ]] && [[ ! "${!OPTIND}" = -* ]]; then
      optarg="${!OPTIND}"
      shift
    fi
  fi

  case "-$opt" in
    -p|--php)
      PHP_VERSION="$optarg"
      ;;
    -l|--laravel)
      LARAVEL_VERSION="$optarg"
      ;;
    --)
      break
      ;;
    -?)
      exit 1 
      ;;
    --*)
      echo "illegal option -- ${opt##-}" >&2
      exit 1 
      ;;
  esac
done

if [ -z "$PHP_VERSION" ]; then
  PHP_VERSION="8.2"
fi
if [ -z "$LARAVEL_VERSION" ]; then
  LARAVEL_VERSION="10"
fi

if [[ ! "${PHP_VERSION}" =~ ^7\.4|8\.[0-2]$ ]]; then
  echo 'PHP version must be between 7.4 and 8.2' >&2
  exit 1
fi

if [[ ! "${LARAVEL_VERSION}" =~ ^[6-9]|10$ ]]; then
  echo 'Laravel version must be between 6 and 10' >&2
  exit 1
fi

if [[ $LARAVEL_VERSION -eq 10 && "${PHP_VERSION}" =~ ^7\.4|8\.0$ ]]; then
  echo "Laravel 10 does not support PHP $PHP_VERSION" >&2
  exit 1
fi

if [[ $LARAVEL_VERSION -eq 9 && "${PHP_VERSION}" =~ ^7\.4$ ]]; then
  echo "Laravel 9 does not support PHP $PHP_VERSION" >&2
  exit 1
fi

if [[ $LARAVEL_VERSION -eq 8 && "${PHP_VERSION}" =~ ^8\.[2-9]$ ]]; then
  echo "Laravel 8 does not support PHP $PHP_VERSION" >&2
  exit 1
fi

if [[ $LARAVEL_VERSION -eq 7 && "${PHP_VERSION}" =~ ^8\.[1-9]$ ]]; then
  echo "Laravel 7 does not support PHP $PHP_VERSION" >&2
  exit 1
fi

if [[ $LARAVEL_VERSION -eq 6 && "${PHP_VERSION}" =~ ^8\.[1-9]$ ]]; then
  echo "Laravel 6 does not support PHP $PHP_VERSION" >&2
  exit 1
fi

if [ -e "artisan" ]; then
  echo "artisan already exists" >&2
  exit 1
fi

PROJECT_DIRECTORY=$(dirname $(readlink -f $0))
PROJECT_NAME=$(basename "${PROJECT_DIRECTORY}")

cd "$PROJECT_DIRECTORY"
sed -Ei "s/PHP_VERSION: \"[0-9.]{3}\"/PHP_VERSION: \"${PHP_VERSION}\"/" compose.yml
docker build --build-arg PHP_VERSION=$PHP_VERSION -f runtimes/php/Dockerfile -t ${PROJECT_NAME}-php .
docker run --rm -ti -e USER_ID=$(id -u) -e GROUP_ID=$(id -g) -e LARAVEL_VERSION=${LARAVEL_VERSION}.* -w /work -v ./:/tmp/work ${PROJECT_NAME}-php setup.sh
rm -rf .git initialize.sh
git init .
git add -A
git commit -m "Initial commit"

cd - > /dev/null
