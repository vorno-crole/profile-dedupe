declare -A PRIMARY_KEYS
PRIMARY_KEYS["applicationVisibilities"]="application"
PRIMARY_KEYS["classAccesses"]="apexClass"
PRIMARY_KEYS["customMetadataTypeAccesses"]="name"
PRIMARY_KEYS["customPermissions"]="name"
PRIMARY_KEYS["externalDataSourceAccesses"]="externalDataSource"
PRIMARY_KEYS["fieldPermissions"]="field"
PRIMARY_KEYS["flowAccesses"]="flow"
PRIMARY_KEYS["layoutAssignments"]="layout"
PRIMARY_KEYS["objectPermissions"]="object"
PRIMARY_KEYS["pageAccesses"]="apexPage"
PRIMARY_KEYS["recordTypeVisibilities"]="recordType"
PRIMARY_KEYS["tabVisibilities"]="tab"
PRIMARY_KEYS["userPermissions"]="name"

declare -A SECONDARY_KEYS
SECONDARY_KEYS["layoutAssignments"]="recordType"
