#!/usr/bin/env bash
#!/usr/local/bin/bash

SF_METAFILE="force-app/main/default/profiles/Admin.profile-meta.xml"
MODE="BOTH"
REPLACE="FALSE"
REMOVE_CSVs="FALSE"
SORT_KEYS=""
LC_ALL=C

# setup
	SECONDS=0

	YLW="\033[33;1m"
	GRN="\033[32;1m"
	WHT="\033[97;1m"
	RED="\033[91;1m"
	RES="\033[0m"

	SCR_NAME="Profile/Permission Set/Custom Label Deduplication script"
	SCR_VERSION="1.0"
	SCR_AUTHOR="vc@vaughancrole.com"
	SCR_DIR="$(dirname "$BASH_SOURCE")"


	# functions
		pause()
		{
			read -p "Press Enter to continue." </dev/tty
		}
		export -f pause

		title()
		{
			echo -e "${GRN}*** ${WHT}${SCR_NAME} v${SCR_VERSION}${RES}\nby ${GRN}${SCR_AUTHOR}${RES}\n"
		}
		export -f title

		usage()
		{
			# title
			echo -e "Usage:"
			echo -e "${WHT}$0${RES} -m <profile-perm-set-or-label-meta-file.xml> (--encode | --decode | --both | --check-duplicates) (--replace-xml) (--remove-csv)"
		}
		export -f usage
	# functions


	# read args
		while [ $# -gt 0 ] ; do
			case $1 in
				-m | --meta) SF_METAFILE="$2"
							 shift;;

				-e | --enc | --encode) MODE="ENCODE";;
				-d | --dec | --decode) MODE="DECODE";;
				-b | --both) MODE="BOTH";;
				-c | --check-duplicates) MODE="DUPE";;
				--replace-xml) REPLACE="TRUE";;
				--remove-csv) REMOVE_CSVs="TRUE";;
				--randr | -r) REMOVE_CSVs="TRUE"
							  REPLACE="TRUE";;

				-h | --help | -v | --version)
					title
					usage
					exit 0;;

				*)
					title
					echo -e "${RED}*** ERROR: ${RES}Invalid option: ${WHT}$1${RES}."
					usage
					exit 1;;
			esac
			shift
		done

		if [[ "${SF_METAFILE}" == "" ]]; then
			title
			echo -e "${RED}*** Error: ${RES}SF_METAFILE not specified."
			usage
			exit 1
		fi

		META_FILENAME="$(basename "${SF_METAFILE}")"
		if grep -qF '.profile-meta.xml'  <<< ${META_FILENAME}; then
			META_TYPE="Profile"
			DECODE_KEY="Profile"
			source ${SCR_DIR}/profileKeys.sh

		elif grep -qF '.permissionset-meta.xml'  <<< ${META_FILENAME}; then
			META_TYPE="PermSet"
			DECODE_KEY="PermissionSet"
			source ${SCR_DIR}/permSetKeys.sh

		elif grep -qF '.labels-meta.xml'  <<< ${META_FILENAME}; then
			META_TYPE="Label"
			DECODE_KEY="CustomLabels"
			SORT_KEYS="fullName"
			source ${SCR_DIR}/labelKeys.sh

		else
			echo -e "Unknown Metadata file type: ${META_FILENAME}";
			exit 1;
		fi
	# read args
# setup

title
echo -e "File: ${SF_METAFILE}"
echo -e "File type: ${META_TYPE}"


# Encode to quasi-CSV
if [[ ${MODE} == "ENCODE" || ${MODE} == "DUPE" || ${MODE} == "BOTH" ]]; then
	SECONDS=0

	OUT_FILE="${SF_METAFILE}.csv"

	if [[ ${MODE} == "DUPE" ]]; then
		echo "Checking for duplicates"
		OUT_FILE="${SF_METAFILE}.dupes.csv"
	else
		echo "Encoding ${SF_METAFILE}     to ${OUT_FILE}"
	fi

	META_KEY_0="$(yq -p=xml -o=j --xml-skip-proc-inst "${SF_METAFILE}" | jq -cr 'keys_unsorted | first')"

	# echo "SF_METAFILE: ${SF_METAFILE}"
	# echo "META_KEY_0: ${META_KEY_0}"

	# Get the metadata keys....
	KEY_FILE=".metadataKeys.txt"
	yq -p=xml -o=j --xml-skip-proc-inst "${SF_METAFILE}" | \
	jq -cr ".${META_KEY_0} | keys_unsorted" | cut -c2- | sed 's/.\{1\}$//' | sed -e 's/,/\n/g' | \
	awk -F'"' '{print $2}' | grep -v '+@xmlns' | sort | uniq > ${KEY_FILE}

	rm -f "${OUT_FILE}"

	# iterate profile keys
	while IFS= read -u 10 -r META_KEY_1 ; do
		# echo -n "META_KEY_1: ${META_KEY_1} "

		# Primary key
		PRIMARY_KEY="${PRIMARY_KEYS["${META_KEY_1}"]}"
		SECONDARY_KEY="${SECONDARY_KEYS["${META_KEY_1}"]}"

		# Check for key:value (not key:object)
		key_values="$(yq -p=xml -o=j -I=0 "${SF_METAFILE}" | jq -c ".${META_KEY_0}.${META_KEY_1}")"
		# echo $key_values

		TYPE="$(jq -r 'type' <<< "$key_values")"
		# echo $TYPE

		if [[ $TYPE == 'string' ]]; then
			# echo "String: single value of key ${META_KEY_1}."
			echo "${META_KEY_1}:$key_values" >> "${OUT_FILE}"
			continue;

		elif [[ $TYPE == 'array' ]]; then

			# Check type of first element
			TYPE2="$(jq -rc 'first | type' <<< "$key_values")"

			# if a string, assume is duplication
			if [[ $TYPE2 == 'string' ]]; then

				# duplication of key, multiple strings
				jq -c '.[]' <<< "$key_values" | awk -v metakey="${META_KEY_1}" '{print metakey":" $0}' >> "${OUT_FILE}"
				continue;
			fi

		fi

		# Check for array or not - enforce object inside array
		if [[ $TYPE == 'object' ]]; then
			key_values="[${key_values}]";
		fi

		if [[ ${MODE} != "DUPE" ]]; then
			# encode mode
			jq -c ".[] | {${PRIMARY_KEY}} as \$first | \$first + (to_entries - (\$first|to_entries) | from_entries)" <<< "$key_values" | \
			awk -v metakey="${META_KEY_1}" '{print metakey $0}' >> "${OUT_FILE}"

		else
			# dupe mode
			if [[ "${SECONDARY_KEY}" != "" ]]; then
				# echo "Sec key: ${SECONDARY_KEY}"
				SECONDARY_KEY=",${SECONDARY_KEY}"
			fi

			jq -c ".[] | {${PRIMARY_KEY}${SECONDARY_KEY}}" <<< "$key_values" | \
			awk -v metakey="${META_KEY_1}" '{print metakey $0}' >> "${OUT_FILE}"

		fi

	done 10< ${KEY_FILE}
	rm -f ${KEY_FILE};

	# UNIQ it
	if [[ ${MODE} != "DUPE" ]]; then
		LC_COLLATE=C sort -u -o "${OUT_FILE}" "${OUT_FILE}"

	else
		# check dupes
		LC_COLLATE=C sort "${OUT_FILE}" | uniq -cd > "${OUT_FILE}2"

		EXIT_CODE="0"

		if [[ -s "${OUT_FILE}2" ]]; then
			echo -e "Error: Duplicate ${META_KEY_0} keys found"
			cat "${OUT_FILE}2"
			EXIT_CODE="1"
		else
			echo -e "Good: No duplicate ${META_KEY_0} keys found."
		fi

		rm "${OUT_FILE}"
		rm "${OUT_FILE}2"
		echo "Check time taken: $SECONDS";
		exit $EXIT_CODE;

	fi

	# cat "${SF_METAFILE}.csv"
	# exit;
	echo "Encode time taken: $SECONDS";
fi


# Decode back to xml
if [[ ${MODE} == "DECODE" || ${MODE} == "BOTH" ]]; then
	SECONDS=0
	echo "Decoding ${SF_METAFILE}.csv to ${SF_METAFILE}2"
	LC_COLLATE=C sort -u -o "${SF_METAFILE}.csv" "${SF_METAFILE}.csv"

	META_KEY_0="${DECODE_KEY}"
	YQ_CMD="sort_keys(.[])"

	if [[ ${SORT_KEYS} != "" ]]; then
		YQ_CMD=".[] |= pick ( ([\"${SORT_KEYS}\"] + keys) | unique)"
	fi

	# echo "SF_METAFILE: ${SF_METAFILE}"
	# echo "META_KEY_0: ${META_KEY_0}"

	cat <<- EOF > "${SF_METAFILE}2"
	<?xml version="1.0" encoding="UTF-8"?>
	<${META_KEY_0} xmlns="http://soap.sforce.com/2006/04/metadata">
	EOF

	awk -F'[{}]' '{if ($0 ~ /{/) { print "{\""$1"\":{" $2 "}}" } else { split($0, arr, ":"); print "{\"" arr[1] "\":" arr[2] "}" }};' "${SF_METAFILE}.csv" | \
	yq -p=j -o=x -I=4 "${YQ_CMD}" | \
	awk '{print "    "$0}' >> "${SF_METAFILE}2";

	echo "</${META_KEY_0}>" >> "${SF_METAFILE}2";

	# DTD entities
	sed -i '' 's/&#34;/\&quot;/gi' "${SF_METAFILE}2"
	sed -i '' 's/&#38;/\&amp;/gi'  "${SF_METAFILE}2"
	sed -i '' 's/&#39;/\&apos;/gi' "${SF_METAFILE}2"
	sed -i '' 's/&#60;/\&lt;/gi'   "${SF_METAFILE}2"
	sed -i '' 's/&#62;/\&gt;/gi'   "${SF_METAFILE}2"

	# cat "${SF_METAFILE}2";

	if [[ "${REPLACE}" == "TRUE" ]]; then
		mv "${SF_METAFILE}2" "${SF_METAFILE}";
	fi

	if [[ ${REMOVE_CSVs} == "TRUE" ]]; then
		rm "${SF_METAFILE}.csv";
	fi

	echo "Decode time taken: $SECONDS";
fi
