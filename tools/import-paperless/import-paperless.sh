#!/bin/bash

# allows to start small - but affects also tags and correspondents, so they might be missing when linking them!
# LIMIT=LIMIT 150

echo "##################### START #####################"

echo "  Docspell - Import from Paperless v '0.1 beta'"
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

ds_url=$1
ds_user=$2
ds_password=$3
db_path=$4
file_path=$5

if [ $# -ne 5 ]; then
  echo "FATAL  Exactly five parameters needed"
  exit -3
elif [ "$1" == "" ] || [ "$2" == "" ] || [ "$3" == "" ] || [ "$4" == "" ] || [ "$5" == "" ]; then
  echo "FATAL  Parameter missing"
  echo "  ds_url: $ds_url"
  echo "  ds_user: $ds_user"
  echo "  ds_password: $ds_password"
  echo "  db_path: $db_path"
  echo "  file_path: $file_path"
  exit -2
fi

# the tables we need
modes=("documents_correspondent" "documents_document" "documents_tag" "documents_document_tags")

# the columns per table we need
declare -A columns
#documents_document: id, title, content, created, modified, added, correspondent_id, file_type, checksum,  storage_type, filename
columns[documents_document]="id, title, created, added, correspondent_id, file_type, filename"
#documents_correspondent: id, name, match, matching_algorithm, is_insensitive, slug
columns[documents_correspondent]="id, name"
#documents_tag: id, name, colour, match, matching_algorithm, is_insensitive, slug
columns[documents_tag]="id, name"
#documents_document_tags: id, document_id, tag_id
columns[documents_document_tags]="document_id, tag_id"

declare -A document2orga
declare -A corr2name
declare -A tag2name
declare -A doc2name
declare -A pl2ds_id

############# FUCNTIONS
function curl_call() {
  curl_cmd=$1
  curl_result=$(eval $curl_cmd)

  if [ "$curl_result" == '"Authentication failed."' ]; then
    printf "New login required... "
    login
    sleep 2
    curl_call $1

  elif [ "$curl_result" == "Bad Gateway" ] || [ "$curl_result" == '404 page not found' ]; then
    echo "FATAL  Connection to server failed"
    exit -1
  fi
}

function login() {
  curl_call "curl -s -X POST -d '{\"account\": \"$ds_user\", \"password\": \"$ds_password\"}' ${ds_url}/api/v1/open/auth/login"

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

# login, get token
login

# go through modes
for mode in "${modes[@]}"; do
  echo && echo "### $mode ###"

  OLDIFS=$IFS
  IFS=$'\n'

  tmp_resultset=(`sqlite3 -header $db_path "select ${columns[$mode]} from $mode order by 1 $LIMIT;"`)

  tmp_headers=($(echo "${tmp_resultset[0]}" | tr '|' '\n'))
  len_resultset=${#tmp_resultset[@]}

  # go through resultset
  for ((i=1;i<$len_resultset;i++)); do

    # split result into array
    tmp_result=($(echo "${tmp_resultset[$i]}" | tr '|' '\n'))

    # process single result array
    len_result=${#tmp_result[@]}
    # write array to named array
    declare -A tmp_result_arr
    for ((j=0;j<$len_result;j++)); do
      tmp_header=${tmp_headers[$j]}
      tmp_result_arr[$tmp_header]=${tmp_result[$j]}
    done

    printf "%${#len_resultset}s" "$i"; printf "/$((len_resultset-1))     "

    # CORRESPONDENTS
    if [ "$mode" == "documents_correspondent" ]; then
      echo "\"${tmp_result_arr[name]}\" [id: ${tmp_result_arr[id]}]"
      curl_call "curl -s -X POST '$ds_url/api/v1/sec/organization' -H 'X-Docspell-Auth: $ds_token' -H 'Content-Type: application/json' -d '{\"id\":\"\",\"name\":\"${tmp_result_arr[name]}\",\"address\":{\"street\":\"\",\"zip\":\"\",\"city\":\"\",\"country\":\"\"},\"contacts\":[],\"created\":0}'"
      curl_status=$(echo $curl_result | jq -r ".success")

      printf "%${#len_resultset}s" " "; printf "           "
      if [ "$curl_status" == "true" ]; then
        echo "Organization successfully created from correspondent"
      elif [ "$(echo $curl_result | jq -r '.message')" == "Adding failed, because the entity already exists." ]; then
        echo "Organization already exists, nothing to do"
      else
        echo "FATAL  Error during creation of organization: $(echo $curl_result | jq -r '.message')"
        exit 2
      fi
      echo

      # paperless id to name for later purposes
      corr2name[${tmp_result_arr[id]}]=${tmp_result_arr[name]}


    # DOCUMENTS
    elif [ "$mode" == "documents_document" ]; then
      echo "\"${tmp_result_arr[filename]}\" [id: ${tmp_result_arr[id]}]"
      doc2name[${tmp_result_arr[id]}]=${tmp_result_arr[filename]}

      tmp_filepath=$file_path/${tmp_result_arr[filename]}
      if [ ! -f "$tmp_filepath" ]; then
        echo "FATAL  no access to file: $tmp_filepath"
        exit 3
      fi

      # check for checksum
      tmp_checksum=$(sha256sum "$tmp_filepath" | awk '{print $1}')

      curl_call "curl -s -X GET '$ds_url/api/v1/sec/checkfile/$tmp_checksum' -H 'X-Docspell-Auth: $ds_token'"
      curl_status=$(echo $curl_result | jq -r ".exists")

      printf "%${#len_resultset}s" " "; printf "           "
      # upload if not existent
      if [ $? -eq 0 ] && [ "$curl_status" == "false" ]; then
        echo -n "File does not exist, uploading... "
        curl_call "curl -s -X POST '$ds_url/api/v1/sec/upload/item' -H 'X-Docspell-Auth: $ds_token' -H 'Content-Type: multipart/form-data' -F 'file=@$tmp_filepath;type=application/${tmp_result_arr[file_type]}'"

        curl_status=$(echo $curl_result | jq -r ".success")
        if [ "$curl_status" == "true" ]; then
          echo "done"

        else
          echo "FATAL  upload failed"
          exit 4
        fi

      else
        echo "File already exists, nothing to upload"
      fi

      # link orga to document
      printf "%${#len_resultset}s" " "; printf "           "
      printf "Linking Organization \"${corr2name[${tmp_result_arr[correspondent_id]}]}\" .."
      count=0
      countMax=10
      while [ $count -le $countMax ]; do
        # get Docspell id of document
        curl_call "curl -s -X GET '$ds_url/api/v1/sec/checkfile/$tmp_checksum' -H 'X-Docspell-Auth: $ds_token'"
        curl_status=$(echo $curl_result | jq -r ".exists")
        res=$?

        if [ $res -eq 0 ] && [ "$curl_status" == "true" ]; then
          curl_status=$(echo $curl_result | jq -r ".items[0].id")
          # paperless id to docspell id for later use
          pl2ds_id[${tmp_result_arr[id]}]=$curl_status

          if [ ! "${pl2ds_id[${tmp_result_arr[id]}]}" == "" ] && [ ! "${corr2name[${tmp_result_arr[correspondent_id]}]}" == "" ]; then
            count2=0
            count2Max=5
            while [ $count2 -le $count2Max ]; do
              curl_call "curl -s -X GET '$ds_url/api/v1/sec/organization' -H 'X-Docspell-Auth: $ds_token' -G --data-urlencode 'q=${corr2name[${tmp_result_arr[correspondent_id]}]}'"

              # Search for exact match of paperless correspondent in docspell organizations
              curl_status=$(echo $curl_result | jq -r ".items[] | select(.name==\"${corr2name[${tmp_result_arr[correspondent_id]}]}\") | .name")

              if [ "$curl_status" == "${corr2name[${tmp_result_arr[correspondent_id]}]}" ]; then
                curl_status=$(echo $curl_result | jq -r ".items[] | select(.name==\"${corr2name[${tmp_result_arr[correspondent_id]}]}\") | .id")

                # Set actual link to document
                curl_call "curl -s -X PUT '$ds_url/api/v1/sec/item/${pl2ds_id[${tmp_result_arr[id]}]}/corrOrg' -H 'X-Docspell-Auth: $ds_token' -H 'Content-Type: application/json' -d '{\"id\":\"$curl_status\"}'"

                curl_status=$(echo $curl_result | jq -r ".success")
                if [ "$curl_status" == "true" ]; then
                  echo ". done"

                else
                  echo "FATAL  Failed to link orga \"${tmp_result_arr[orga_id]}\" (doc_id: ${pl2ds_id[${tmp_result_arr[id]}]})"
                  exit 5
                fi
                break

              elif [ $count2 -ge $count2Max ]; then
                echo "FATAL  Upload failed (or processing too slow)"
                exit 6

              else
                printf "."
              fi

              sleep $(( count2*count2 ))
              ((count2++))
            done

          else
            echo "Something went wrong, no information on doc_id and/or org_id (${pl2ds_id[${tmp_result_arr[id]}]} // ${corr2name[${tmp_result_arr[correspondent_id]}]})"

          fi
          break

        elif [ $res -ne 0 ]; then
          echo -e "FATAL  Error:\n  Err-Code: $? / $res\n  Command: $curl_cmd\n  Result: $curl_result\n  Status: $curl_status"
          exit 7

        elif [ $count -ge $countMax ]; then
          echo "FATAL  Upload failed (or processing too slow)"
          exit 8

        else
            printf "."
        fi
        sleep $(( count * count ))
        ((count++))
      done
      echo

      # TAGS
      elif [ "$mode" == "documents_tag" ]; then
        echo "\"${tmp_result_arr[name]}\" [id: ${tmp_result_arr[id]}]"
        printf "%${#len_resultset}s" " "; printf "           "

        # paperless tag id to name for later use
        tag2name[${tmp_result_arr[id]}]=${tmp_result_arr[name]}

        curl_call "curl -s -X POST '$ds_url/api/v1/sec/tag' -H 'X-Docspell-Auth: $ds_token' -H 'Content-Type: application/json' -d '{\"id\":\"ignored\",\"name\":\"${tmp_result_arr[name]}\",\"category\":\"imported (pl)\",\"created\":0}'"

        curl_status=$(echo $curl_result | jq -r ".success")
        if [ "$curl_status" == "true" ]; then
          echo "Tag successfully created"
        elif [ "$(echo $curl_result | jq -r '.message')" == "A tag '${tmp_result_arr[name]}' already exists" ]; then
          echo "Tag already exists, nothing to do"
        else
          echo "FATAL  Error during creation of tag: $(echo $curl_result | jq -r '.message')"
          exit 9
        fi


      # TAGS 2 DOCUMENTS
      elif [ "$mode" == "documents_document_tags" ]; then
        echo "Tag \"${tag2name[${tmp_result_arr[tag_id]}]}\" (id: ${tmp_result_arr[tag_id]}) for \"${doc2name[${tmp_result_arr[document_id]}]}\" (id: ${tmp_result_arr[document_id]})"
        printf "%${#len_resultset}s" " "; printf "           "

        #link tags to documents
        curl_call "curl -s -X PUT '$ds_url/api/v1/sec/item/${pl2ds_id[${tmp_result_arr[document_id]}]}/taglink' -H 'X-Docspell-Auth: $ds_token' -H 'Content-Type: application/json' -d '{\"items\":[\"${tag2name[${tmp_result_arr[tag_id]}]}\"]}'"

        curl_status=$(echo $curl_result | jq -r ".success")
        if [ "$curl_status" == "true" ]; then
          echo '...applied'
        else
          echo "Failed to link tag \"${tmp_result_arr[tag_id]}\" (doc_id: ${pl2ds_id[${tmp_result_arr[document_id]}]})"
        fi
      fi

  done
done

echo ################# DONE #################
date
