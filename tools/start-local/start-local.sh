#!/usr/bin/env bash

# Start some number of docspell nodes. The database can be given as
# env variable, if not a h2 database is used. SOLR is only enabled, if
# a SOLR_URL env variable is available.
#
# You must have tmux installed as this is used to host the processes.

set -euo pipefail

ds_version=${1:-0.32.0-SNAPSHOT}
rest_nodes=${2:-1}
joex_nodes=${3:-1}

rest_start_port=7880
joex_start_port=8800

tmux_session_name="docspell-cluster"

run_root=${DOCSPELL_CLUSTER_ROOT:-/tmp/docspell-cluster}

default_db_url="jdbc:h2://$run_root/db/docspell-cluster.db;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE;AUTO_SERVER=TRUE"
db_url="${DOCSPELL_DB:-$default_db_url}"
db_user="${DOCSPELL_DB_USER:-dev}"
db_pass="${DOCSPELL_DB_USER:-dev}"
solr_url="${DOCSPELL_SOLR_URL:-none}"

prepare_solr_config() {
    local enable=
    if [ "$solr_url" = "none" ]; then
        solr_url="http://localhost"
        enable="false"
    else
        enable="true"
    fi
    echo "enabled = $enable"
    echo "solr.url = \"$solr_url\""
}

prepare_rest_config() {
    port="$1"
    app_id="$2"
    file="$3"

    cat >>"$file" <<-EOF
docspell.server {
  app-id = "$app_id"
  base-url = "http://localhost:$port"
  bind.address = "0.0.0.0"
  bind.port = $port
  full-text-search = {
    $(prepare_solr_config)
  }
  auth.server-secret = "hex:caffee"
  backend {
    mail-debug = false
    jdbc {
      url = "${db_url}"
      user = "${db_user}"
      password = "${db_pass}"
    }
    signup {
      mode = open
      new-invite-password = "test"
    }
  }
  admin-endpoint {
    secret = "123"
  }
  integration-endpoint {
    enabled = true
    http-header = {
      enabled = true
      header-value = "test123"
    }
  }
}
EOF
}

prepare_joex_config() {
    port="$1"
    app_id="$2"
    file="$3"

    cat >> "$file" <<-EOF
docspell.joex {
  app-id = "$app_id"
  base-url = "http://localhost:$port"
  bind.address = "0.0.0.0"
  bind.port = $port
  full-text-search = {
   $(prepare_solr_config)
  }
  mail-debug = false
  extraction {
    preview.dpi = 64
  }
  text-analysis {
    nlp {
      mode = full
      clear-interval = "30 seconds"
    }
  }
  jdbc {
    url = "${db_url}"
    user = "${db_user}"
    password = "${db_pass}"
  }
  scheduler {
    pool-size = 1
    wakeup-period = "10 minutes"
    retries = 3
    retry-delay = "10 seconds"
  }
  house-keeping {
    schedule = "*-*-* 01:00:00"
    cleanup-invites = {
      older-than = "10 days"
    }
  }
  #convert.ocrmypdf.command.program = "/some/path/bin/ocrmypdf"
}
EOF
}

prepare_root() {
    rm -rf "$run_root/work"
    mkdir -p "$run_root"/{db,work,pkg}
}

get_session() {
    set +e
    session=$(tmux list-sessions | grep "$tmux_session_name" | cut -d':' -f1 | head -n1)
    echo $session
    set -e
 }

assert_no_session() {
    local session=$(get_session)
    if [ -n "$session" ]; then
        echo "A tmux session already exists. Please stop this first."
        exit 1
    fi
}

prepare_project() {
    local project="$1"
    local number="$2"
    local app_id="$project$number"
    local wdir="$run_root/work/$project-$number"
    mkdir -p "$wdir"
    case "$project" in
        "restserver")
            local port=$(($rest_start_port + $number))
            prepare_rest_config $port $app_id "$wdir/ds.conf"
            ;;
        "joex")
            local port=$(($joex_start_port + $number))
            prepare_joex_config $port $app_id "$wdir/ds.conf"
            ;;
        *)
            echo "Unknown project: $project"
            exit 1
    esac
}

download_zip() {
    if [ -f "$run_root/pkg/joex.zip" ] && [ -f "$run_root/pkg/restserver.zip" ]; then
        echo "Not downloading, files already exist"
    else
        echo "Downloading docspell..."
        if [[ $ds_version == *SNAPSHOT ]]; then
            curl -#Lo "$run_root/pkg/joex.zip" "https://github.com/eikek/docspell/releases/download/nightly/docspell-joex-${ds_version}.zip"
        else
            curl -#Lo "$run_root/pkg/joex.zip" "https://github.com/eikek/docspell/releases/download/v${ds_version}/docspell-joex-${ds_version}.zip"
        fi
        if [[ $ds_version == *SNAPSHOT ]]; then
            curl -#Lo "$run_root/pkg/restserver.zip" "https://github.com/eikek/docspell/releases/download/nightly/docspell-restserver-${ds_version}.zip"
        else
            curl -#Lo "$run_root/pkg/restserver.zip" "https://github.com/eikek/docspell/releases/download/v${ds_version}/docspell-restserver-${ds_version}.zip"
        fi
    fi

    echo "Unzipping..."
    rm -rf "$run_root/pkg"/docspell-joex-* "$run_root/pkg"/docspell-restserver-*
    unzip -qq "$run_root/pkg/restserver.zip" -d "$run_root/pkg"
    unzip -qq "$run_root/pkg/joex.zip" -d "$run_root/pkg"
}

start_project() {
    local project="$1"
    local number="$2"

    local wdir="$run_root/work/$project-$number"
    local cfgfile="$wdir/ds.conf"
    local bindir=$(realpath "$run_root/pkg"/docspell-$project-*/bin)
    local session=$(get_session)
    local tempdir="$wdir/tmp"
    mkdir -p "$tempdir"

    if [ -z "$session" ]; then
        echo "Starting in new session $project-$number..."
        tmux new -d -s "$tmux_session_name" "cd $wdir && $bindir/docspell-$project -Djava.io.tmpdir=$tempdir -- $cfgfile"
    else
        echo "Starting $project-$number..."
        tmux split-window -t "$tmux_session_name" "cd $wdir && $bindir/docspell-$project -Djava.io.tmpdir=$tempdir -- $cfgfile"
    fi
    sleep 1
}

## === Main

assert_no_session

echo "Version: $ds_version"
echo "Restserver nodes: $rest_nodes"
echo "Joex nodes: $joex_nodes"
echo "tmux session: $tmux_session_name"
echo "Working directory root: $run_root"
echo "Database: $db_url"
echo "SOLR: ${solr_url}"
echo "Continue?"
read

prepare_root
download_zip

n=0
max=$(($rest_nodes > $joex_nodes ? rest_nodes : joex_nodes))
while [ $n -lt $max ]
do
    if [ $n -lt $rest_nodes ]; then
        prepare_project "restserver" $n
        start_project "restserver" $n
    fi
    if [ $n -lt $joex_nodes ]; then
        prepare_project "joex" $n
        start_project "joex" $n
    fi

    n=$(($n + 1))
done
