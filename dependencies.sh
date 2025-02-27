#/usr/local/bin/bash

# Functions
	checkInstalled()
	{
		if ! command -v $1 &> /dev/null; then
			echo -e "${RED}*** Error: ${RES}$1 could not be found."
			exit 1
		fi
	}
	export -f checkInstalled
# Functions

# Check tools are installed
echo "Checking dependencies..."
checkInstalled jq
checkInstalled yq
