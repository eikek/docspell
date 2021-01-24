#!/usr/bin/env bash

# allows to start small - but affects also tags and correspondents, so they might be missing when linking them!
# LIMIT="LIMIT 0"
# LIMIT_DOC="LIMIT 5"
SKIP_EXISTING_DOCS=true

CURL_CMD="curl"
JQ_CMD="jq"
SQLITE_CMD="sqlite3"

echo "##################### START #####################"

echo "  Docspell - Import from Paperless v '0.3 beta'"
echo "         by totti4ever" && echo
echo "  $(date)"
echo
echo "#################################################"
echo && echo

"$JQ_CMD" --version > /dev/null
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
columns[documents_document]="id, title, datetime(created,'localtime') as created, correspondent_id, file_type, filename"
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
if [ "$SKIP_EXISTING_DOCS" == "true" ]; then declare -A doc_skip; fi

############# FUNCTIONS
function curl_call() {
  curl_cmd="$CURL_CMD $1 -H 'X-Docspell-Auth: $ds_token'"
  curl_result=$(eval $curl_cmd)

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
  curl_call "-s -X POST -d '{\"account\": \"$ds_user\", \"password\": \"$ds_password\"}' ${ds_url}/api/v1/open/auth/login"

  curl_status=$(echo $curl_result | "$JQ_CMD" -r ".success")

  if [ "$curl_status" == "true" ]; then
    ds_token=$(echo $curl_result | "$JQ_CMD" -r ".token")
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

  if [ "$mode" == "documents_document" ] || [ "$mode" == "documents_document_tags" ]; then
    tmp_limit=$LIMIT_DOC
  else
    tmp_limit=$LIMIT
  fi
  tmp_resultset=(`$SQLITE_CMD -header $db_path "select ${columns[$mode]} from $mode order by 1 DESC $tmp_limit;"`)


  tmp_headers=($(echo "${tmp_resultset[0]}" | tr '|' '\n'))
  len_resultset=${#tmp_resultset[@]}

  # go through resultset
  for ((i=1;i<$len_resultset;i++)); do

    # split result into array
    tmp_result=($(echo "${tmp_resultset[$i]/'||'/'| |'}" | tr '|' '\n'))

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
      printf "%${#len_resultset}s" " "; printf "           "

      curl_call "-s -X POST '$ds_url/api/v1/sec/organization' -H 'Content-Type: application/json' -d '{\"id\":\"\",\"name\":\"${tmp_result_arr[name]}\",\"address\":{\"street\":\"\",\"zip\":\"\",\"city\":\"\",\"country\":\"\"},\"contacts\":[],\"created\":0}'"
      curl_status=$(echo $curl_result | "$JQ_CMD" -r ".success")

      if [ "$curl_status" == "true" ]; then
        echo "Organization successfully created from correspondent"
      elif [ "$(echo $curl_result | "$JQ_CMD" -r '.message')" == "Adding failed, because the entity already exists." ]; then
        echo "Organization already exists, nothing to do"
      else
        echo "FATAL  Error during creation of organization: $(echo $curl_result | "$JQ_CMD" -r '.message')"
        exit 2
      fi
      echo

      # paperless id to name for later purposes
      corr2name[${tmp_result_arr[id]}]=${tmp_result_arr[name]}


    # DOCUMENTS
    elif [ "$mode" == "documents_document" ]; then
      echo "\"${tmp_result_arr[filename]}\" [id: ${tmp_result_arr[id]}]"
      printf "%${#len_resultset}s" " "; printf "           "

      doc2name[${tmp_result_arr[id]}]=${tmp_result_arr[filename]}

      tmp_filepath=$file_path/${tmp_result_arr[filename]}
      if [ ! -f "$tmp_filepath" ]; then
        echo "FATAL  no access to file: $tmp_filepath"
        exit 3
      fi

      # check for checksum
      tmp_checksum=$(sha256sum "$tmp_filepath" | awk '{print $1}')

      curl_call "-s -X GET '$ds_url/api/v1/sec/checkfile/$tmp_checksum'"
      curl_status=$(echo $curl_result | "$JQ_CMD" -r ".exists")

      # upload if not existent
      if [ $? -eq 0 ] && [ "$curl_status" == "false" ]; then
        echo -n "File does not exist, uploading.."
        curl_call "-s -X POST '$ds_url/api/v1/sec/upload/item' -H 'Content-Type: multipart/form-data' -F 'file=@$tmp_filepath;type=application/${tmp_result_arr[file_type]}'"

        curl_status=$(echo $curl_result | "$JQ_CMD" -r ".success")
        if [ "$curl_status" == "true" ]; then
          printf ". ."

        else
          echo -e "FATAL  upload failed\nCmd: $curl_cmd\nResp: $curl_result\nStatus: $curl_status"
          exit 4
        fi

      else
        printf "File already exists"
        if [ "$SKIP_EXISTING_DOCS" == "true" ]; then
          echo ", skipping this item for all types" && echo
          doc_skip[${tmp_result_arr[id]}]="true"
        else
          printf ", nothing to upload.Fetching ID.."
        fi
      fi

      # skip if needed (SKIP_EXISTING_DOCS)
      if [ ! ${doc_skip[${tmp_result_arr[id]}]+abc} ]; then

        # waitig for document and get document id
        count=0
        countMax=25
        while [ $count -le $countMax ]; do
          # get Docspell id of document
          curl_call "-s -X GET '$ds_url/api/v1/sec/checkfile/$tmp_checksum'"
          curl_status=$(echo $curl_result | "$JQ_CMD" -r ".exists")
          res=$?

          # file id returned
          if [ $res -eq 0 ] && [ "$curl_status" == "true" ]; then
            curl_status=$(echo $curl_result | "$JQ_CMD" -r ".items[0].id")
            # paperless id to docspell id for later use
            pl2ds_id[${tmp_result_arr[id]}]=$curl_status
            echo ".done"
            break

          # unknown error
          elif [ $res -ne 0 ]; then
            echo -e "FATAL  Error:\n  Err-Code: $? / $res\n  Command: $curl_cmd\n  Result: $curl_result\n  Status: $curl_status"
            exit 7

          # counter too high
          elif [ $count -ge $countMax ]; then
            echo "FATAL  Upload failed (or processing too slow)"
            exit 8

          else
              printf "."
          fi
          sleep $(( count * count ))
          ((count++))
        done


        # link orga to document
        printf "%${#len_resultset}s" " "; printf "           "
        if [ ! "${tmp_result_arr[correspondent_id]/' '/''}" == "" ]; then

          # check for availability of document id and name of organization
          if [ ! "${pl2ds_id[${tmp_result_arr[id]}]}" == "" ] && [ ! "${corr2name[${tmp_result_arr[correspondent_id]}]}" == "" ]; then
            printf "Set link to organization \"${corr2name[${tmp_result_arr[correspondent_id]}]}\" .."

            # get organizations matching doc's orga (can be several when parts match)
            curl_call "-s -X GET '$ds_url/api/v1/sec/organization' -G --data-urlencode 'q=${corr2name[${tmp_result_arr[correspondent_id]}]}'"

            # Search for exact match of paperless correspondent in fetched organizations from Docspell
            curl_status=$(echo $curl_result | "$JQ_CMD" -r ".items[] | select(.name==\"${corr2name[${tmp_result_arr[correspondent_id]}]}\") | .name")

            # double-check that found organization matches doc's correspondent
            if [ "$curl_status" == "${corr2name[${tmp_result_arr[correspondent_id]}]}" ]; then
              curl_status=$(echo $curl_result | "$JQ_CMD" -r ".items[] | select(.name==\"${corr2name[${tmp_result_arr[correspondent_id]}]}\") | .id")

              # Set actual link to document
              curl_call "-s -X PUT '$ds_url/api/v1/sec/item/${pl2ds_id[${tmp_result_arr[id]}]}/corrOrg' -H 'Content-Type: application/json' -d '{\"id\":\"$curl_status\"}'"

              curl_status=$(echo $curl_result | "$JQ_CMD" -r ".success")
              if [ "$curl_status" == "true" ]; then
                echo ". done"

              # unknown error
              else
                echo "FATAL  Failed to link orga \"${tmp_result_arr[orga_id]}\" (doc_id: ${pl2ds_id[${tmp_result_arr[id]}]})"
                exit 5
              fi
            else
              echo "FATAL  Unknown error"
              exit 6
            fi
          else
            echo "WARNING  Something went wrong, no information on doc_id and/or org_id (${pl2ds_id[${tmp_result_arr[id]}]} // ${corr2name[${tmp_result_arr[correspondent_id]}]}) - Limits are $LIMIT / $LIMIT_DOC"
          fi
        else
          echo "No correspondent set in Paperless, skipping."
        fi

        # Set name of document
        printf "%${#len_resultset}s" " "; printf "           "

        curl_call "-s -X PUT '$ds_url/api/v1/sec/item/${pl2ds_id[${tmp_result_arr[id]}]}/name' -H 'Content-Type: application/json' -d '{\"text\":\"${tmp_result_arr[title]}\"}'"

        curl_status=$(echo $curl_result | "$JQ_CMD" -r ".success")
        if [ "$curl_status" == "true" ]; then
          echo "Set name of item: \"${tmp_result_arr[title]}\""

        else
          echo "FATAL  Failed to set item's name \"${tmp_result_arr[title]}\" (doc_id: ${pl2ds_id[${tmp_result_arr[id]}]})"
          exit 5
        fi


        # Set created date of document
        printf "%${#len_resultset}s" " "; printf "           "

        tmp_date="${tmp_result_arr[created]:0:10} 12:00:00" #fix for timezone variations
        curl_call "-s -X PUT '$ds_url/api/v1/sec/item/${pl2ds_id[${tmp_result_arr[id]}]}/date' -H 'Content-Type: application/json' -d '{\"date\":$( echo "$(date -d "$tmp_date" +%s) * 1000" | bc )}'"

        curl_status=$(echo $curl_result | "$JQ_CMD" -r ".success")
        if [ "$curl_status" == "true" ]; then
          echo "Set creation date of item: \"${tmp_date:0:10}\""

        else
          echo "FATAL  Failed to set item's creation date \"$tmp_date\" (doc_id: ${pl2ds_id[${tmp_result_arr[id]}]})"
          exit 5
        fi
        echo

      fi  # done with documents

    # TAGS
    elif [ "$mode" == "documents_tag" ]; then
      if [ ! "${tmp_result_arr[name]}" == "" ] && [ ! "${tmp_result_arr[id]}" == "" ]; then
        echo "\"${tmp_result_arr[name]}\" [id: ${tmp_result_arr[id]}]"
        printf "%${#len_resultset}s" " "; printf "           "

        # paperless tag id to name for later use
        tag2name[${tmp_result_arr[id]}]=${tmp_result_arr[name]}

        curl_call "-s -X POST '$ds_url/api/v1/sec/tag' -H 'Content-Type: application/json' -d '{\"id\":\"ignored\",\"name\":\"${tmp_result_arr[name]}\",\"category\":\"imported (pl)\",\"created\":0}'"

        curl_status=$(echo $curl_result | "$JQ_CMD" -r ".success")
        if [ "$curl_status" == "true" ]; then
          echo "Tag successfully created"
        elif [ "$(echo $curl_result | "$JQ_CMD" -r '.message')" == "A tag '${tmp_result_arr[name]}' already exists" ]; then
          echo "Tag already exists, nothing to do"
        else
          echo "FATAL  Error during creation of tag: $(echo $curl_result | "$JQ_CMD" -r '.message')"
          exit 9
        fi
      else
        echo "WARNING  Error on tag processing, no id and/or name (${tmp_result_arr[id]} / ${tmp_result_arr[name]}) - Limits are $LIMIT / $LIMIT_DOC"
      fi


    # TAGS 2 DOCUMENTS
    elif [ "$mode" == "documents_document_tags" ]; then
      # if doc_skip is not set for document_id
      if [ ! ${doc_skip[${tmp_result_arr[document_id]}]+abc} ]; then
        if [ ! "${tag2name[${tmp_result_arr[tag_id]}]}" == "" ] && [ ! "${tmp_result_arr[tag_id]}" == "" ]; then
          echo "Tag \"${tag2name[${tmp_result_arr[tag_id]}]}\" (id: ${tmp_result_arr[tag_id]}) for \"${doc2name[${tmp_result_arr[document_id]}]}\" (id: ${tmp_result_arr[document_id]})"
          printf "%${#len_resultset}s" " "; printf "           "

          #link tags to documents
          curl_call "-s -X PUT '$ds_url/api/v1/sec/item/${pl2ds_id[${tmp_result_arr[document_id]}]}/taglink' -H 'Content-Type: application/json' -d '{\"items\":[\"${tag2name[${tmp_result_arr[tag_id]}]}\"]}'"

          curl_status=$(echo $curl_result | "$JQ_CMD" -r ".success")
          if [ "$curl_status" == "true" ]; then
            echo '...applied'
          else
            echo "Failed to link tag \"${tmp_result_arr[tag_id]}\" (doc_id: ${pl2ds_id[${tmp_result_arr[document_id]}]})"
          fi
        else
          echo "WARNING  Error on tag processing, no id and/or name (${tmp_result_arr[id]} / ${tmp_result_arr[name]}) - Limits are $LIMIT / $LIMIT_DOC"
        fi
      else
        echo -en "\r"
        sleep 0.1
      fi
    fi  # done with mode processing

  done  # with single resultset
done  # with modes

echo ################# DONE #################
date
