#!/usr/bin/env bash

echo "##################### START #####################"

echo "  Docspell Consumedir Cleaner - v0.1 beta"
echo "         by totti4ever" && echo
echo "  $(date)"
echo
echo "#################################################"
echo && echo

jq --version > /dev/null
if [ $? -ne 0 ]; then
  echo "please install 'jq'"
  exit -4
fi

ds_url=${1%/}
ds_user_param=$2
ds_user=${ds_user_param#*/}
ds_collective=${ds_user_param%%/*}
ds_password=$3
ds_consumedir_path=${4%/}
ds_archive_path=$ds_consumedir_path/_archive/$ds_collective


if [ $# -ne 4 ]; then
  echo "FATAL  Exactly four parameters needed"
  exit -3
elif [ "$1" == "" ] || [ "$2" == "" ] || [ "$3" == "" ] || [ "$4" == "" ]; then
  echo "FATAL  Parameter missing"
  echo "  ds_url: $ds_url"
  echo "  ds_user: $ds_user"
  echo "  ds_password: $ds_password"
  echo "  ds_consumedir_path: $ds_consumedir_path"
  exit -2
elif [ "$ds_collective" == "_archive" ]; then
  echo "FATAL  collective name '_archive' is not supported by this script"
  exit -1
fi


############# FUNCTIONS
function curl_call() {
  curl_cmd="$1 -H 'X-Docspell-Auth: $ds_token'"
  curl_result=$(eval $curl_cmd)
  curl_code=$?

  if [ "$curl_result" == '"Authentication failed."' ] || [ "$curl_result" == 'Response timed out' ]; then
    printf "\nNew login required ($curl_result)... "
    login
    printf "%${#len_resultset}s" " "; printf "           .."
    curl_call $1

  elif [ "$curl_result" == "Bad Gateway" ] || [ "$curl_result" == '404 page not found' ]; then
    echo "FATAL  Connection to server failed"
    exit -1
  fi
}


function login() {
  curl_call "curl -s -X POST -d '{\"account\": \"$ds_collective/$ds_user\", \"password\": \"$ds_password\"}' ${ds_url}/api/v1/open/auth/login"

  curl_status=$(echo $curl_result | jq -r ".success")

  if [ "$curl_status" == "true" ]; then
    ds_token=$(echo $curl_result | jq -r ".token")
    echo "Login successfull ( Token: $ds_token )"

  else
    echo "FATAL  Login not succesfull"
    exit 1

  fi
}

############# END

echo "Settings:"
if [ "$DS_CC_REMOVE" == "true" ]; then
  echo "    ### !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! ###"
  echo "  - DELETE files?    YES"
  echo "     when already existing in Docspell. This cannot be undone!"
  echo "    ### !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! ###"
else
  echo "  - DELETE files?    no"
  echo "     moving already uploaded files to archive"
fi
echo
if [ "$DS_CC_UPLOAD_MISSING" == true ]; then
  echo "  - UPLOAD files?    YES"
  echo "     files not existing in Docspell will be uploaded and will be re-checked in the next run."
else
  echo "  - UPLOAD files?    no"
  echo "     files not existing in Docspell will NOT be uploaded and stay where they are."
fi
echo && echo
echo "Press 'ctrl+c' to cancel"
for ((i=9;i>=0;i--)); do
  printf "\r waiting $i seconds "
  sleep 1s
done
echo && echo

# login, get token
login

echo "Scanning folder for collective '$ds_collective' ($ds_consumedir_path/$ds_collective)"
echo && echo

while read -r line
do
  tmp_filepath=$line

  if [ "$tmp_filepath" == "" ]; then
    echo "no files found" && echo
    exit 0 #no results
  elif [ ! -f "$tmp_filepath" ]; then
    echo "FATAL  no access to file: $tmp_filepath"
    exit 3
  fi

  echo "Checking '$tmp_filepath'"
  printf "%${#len_resultset}s" " "; printf "           "

  # check for checksum
  tmp_checksum=$(sha256sum "$tmp_filepath" | awk '{print $1}')

  curl_call "curl -s -X GET '$ds_url/api/v1/sec/checkfile/$tmp_checksum'"
  curl_status=$(echo $curl_result | jq -r ".exists")

  if [ $curl_code -ne 0 ]; then
    # error
    echo "ERROR  $curl_result // $curl_status"

  # file exists in Docspell
  elif [ "$curl_status" == "true" ]; then
    item_name=$(echo $curl_result | jq -r ".items[0].name")
    item_id=$(echo $curl_result | jq -r ".items[0].id")
    echo "File already exists: '$item_name (ID: $item_id)'"

    printf "%${#len_resultset}s" " "; printf "           "
    if [ "$DS_CC_REMOVE" == "true" ]; then
      echo "... removing file"
      rm "$tmp_filepath"
    else
      created=$(echo $curl_result | jq -r ".items[0].created")
      cur_dir="$ds_archive_path/$(date -d @$(echo "($created+500)/1000" | bc) +%Y-%m
)"
      echo "... moving to archive by month added ('$cur_dir')"
      mkdir -p "$cur_dir"
      mv "$tmp_filepath" "$cur_dir/"
    fi

  # file does not exist in Docspell
  else

    echo "Files does not exist, yet"
    if [ "$DS_CC_UPLOAD_MISSING" == true ]; then
      printf "%${#len_resultset}s" " "; printf "           "
      printf "...uploading file.."
      curl_call "curl -s -X POST '$ds_url/api/v1/sec/upload/item' -H 'Content-Type: multipart/form-data' -F 'file=@$tmp_filepath'"
      curl_status=$(echo $curl_result | jq -r ".success")
      if [ "$curl_status" == "true" ]; then
        echo ". done"
      else
        echo -e "\nERROR  $curl_result"
      fi
    fi
  fi

  echo
done \
  <<< $(find $ds_consumedir_path/$ds_collective -type f)


echo ################# DONE #################
date
