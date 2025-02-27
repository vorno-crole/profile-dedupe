# Salesforce Profile Converter, Validator and Deduplicator
by vc@vaughancrole.com

instructions coming soon

## Install

Ensure you have the dependencies installed
```shell
brew install jq yq
```

Clone this repo to your machine, and link the folder into your Salesforce repository (or put in your path.)
```shell
mkdir -p ~/Documents/GitHub
cd ~/Documents/GitHub
git clone https://github.com/vorno-crole/profile-dedupe.git
```

## How To Use

### Options
Run the `dedupe.sh` script with `--help` to get basic usage instructions

```shell
~/Documents/GitHub/profile-dedupe/dedupe.sh --help

*** Profile/Permission Set/Custom Label Deduplication script v1.0
by vc@vaughancrole.com

Usage:
~/Documents/GitHub/profile-dedupe/dedupe.sh -m <profile-perm-set-or-label-meta-file.xml> (--encode | --decode | --both | --check-duplicates) (--replace-xml) (--remove-csv)
```

### Convert Salesforce XML from and to CSV

#### Convert a Salesforce Profile XML into a (kind of) CSV file format for easier diff'ing and human editing.

```shell
~/Documents/GitHub/profile-dedupe/dedupe.sh -m force-app/main/default/profiles/Admin.profile-meta.xml --encode

*** Profile/Permission Set/Custom Label Deduplication script v1.0
by vc@vaughancrole.com

File type: Profile
Encoding force-app/main/default/profiles/Admin.profile-meta.xml     to force-app/main/default/profiles/Admin.profile-meta.xml.csv
Encode time taken: 2
```

This created a deduplicated CSV file.

#### Convert the CSV file format back to Salesforce XML

```shell
~/Documents/GitHub/profile-dedupe/dedupe.sh -m force-app/main/default/profiles/Admin.profile-meta.xml --decode --replace-xml

*** Profile/Permission Set/Custom Label Deduplication script v1.0
by vc@vaughancrole.com

File type: Profile
Decoding force-app/main/default/profiles/Admin.profile-meta.xml.csv to force-app/main/default/profiles/Admin.profile-meta.xml2
Decode time taken: 0
```

### Check Salesforce XML for duplicate keys


```shell
~/Documents/GitHub/profile-dedupe/dedupe.sh -m force-app/main/default/profiles/Admin.profile-meta.xml --check-duplicates

*** Profile/Permission Set/Custom Label Deduplication script v1.0
by vc@vaughancrole.com

File type: Profile
Checking force-app/main/default/profiles/Admin.profile-meta.xml for duplicates
Good: No duplicate Profile keys found.
Check time taken: 2
```

