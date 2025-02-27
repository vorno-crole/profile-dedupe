# Salesforce Profile Converter, Validator and Deduplicator
by vc@vaughancrole.com

Currently supports Salesforce Profile, Permission Set and CustomLabel XML files.

_instructions coming soon_


## What Is It?

This is a solution to dealing with the problems that come from source-managed Salesforce XML metadata files.

And a solution to helping Git overcome the problems stemming from tracking and merging XML files in general.

### Example: The Admin Profile

Take the Profile metadata as an example:  
`force-app/main/default/profiles/Admin.profile-meta.xml`

After a few projects, this file fast becomes a mess, difficult to work with and practically "broken" when tracked in Git. This file can become unsequenced (not alphabetical), with duplicate keys and other errors.

Now, these breakages are not easily seen or felt - most times it can still deploy and load into Salesforce (mostly) without complaint.

But when you start tracking your Salesforce metadata in Git, and along comes the eventual merging of projects or other changes (into a common codebase), it can fast become a nightmare to manually resolve all the changes when metadata is broken or scrambled.


### Why does this happen?

There are a few parts to this storm.

* The Profile XML format is a pain to work with. It's a huge file with thousands of lines, and Salesforce does have a habit of making a mess of this file - adding unwanted keys and attributes to the file. Due to this behaviour, and the need to be precise with their changes, builders and developers end up modifying this file by hand.

* Each specific item in the Profile XML file is recorded across multiple lines. eg: Need to add a field-permission to the profile? - that's 4 lines of XML, held amongst a jungle of 100s of other field permissions all listed out one after the other.

When these changes are tracked in Git, Git expects a couple of things:

* It's main purpose is to track code files - which is sequential in nature. Having a Profile change which might be at the top, middle or end of the file doesn't bode well for Git's difference and change engine.

* When multiple projects are contributing to the same Profile file, and with changes being made in (almost) random places in the file itself, Git gets confused very quickly and cannot reconcile these changes.

* Having each specific Profile change across multiple lines "breaks" the Git difference engine. Whilst Git does track changes at a multiple-line level, tracking XML changes produces quirks in the difference engine, due to how the XML file is laid out.

These XML file characteristics, along with Gits shortcomings, lead to many hours of dealing with wonky, broken XMLs and merge hell.

I got tired of spending many long hours dealing with a sucky file format, merging and deploying these changes were resulting in many errors and manual intervention and resolution.

## The Solution

So what did I do? I wrote a script to dynamically transform the XML file into a format that works best with Git, and provides better capability for insepction, analysis, editing and tracking.

Characteristics include:

* Each specific change/attribute or key/value is defined on a single line.

* Each line and the whole file is structured to be sortable to produce a sequenced, alphabetical output

* By having a sortable file format, duplicated keys and other values fast become detectable and (mostly) automatically correctable.

I'm calling this format a quasi-CSV file. It's not truly CSV (it's probably closer to JSON now in this iteration), but CSV sounds friendlier. And I do think it's approachable, human-readable and friendly.

And, with this CSV file, we gain a few possibilities:

* Comparing CSV files together produces a clean, precise delta of the changes made, removed, requested or absent

* Editing the CSV file is a fast and easy task. Can find and amend settings quickly. Can append new settings anywhere in the file. Can remove settings by deleting the line.

* Transforming the CSV file back to XML format cleans and fixes any residual problems the XML might possess.  
Converted XML files are correctly sequenced, with duplicate keys removed, white-spacing cleaned up, and ready for capture into Git and promotion into your Salesforce environment.


### Applications

I wrote this script to work in the following use-cases:

* In a check-only mode: Scan a metadata file, and display an error if any duplicate keys are found (great for PR validations)

* In a "Round trip" mode: Convert a metadata file to CSV, clean it up, then convert it back to clean XML

* In an analysis or edit mode: 
  * Convert (a) metadata file(s) to CSV, 
  *(Compare CSV files with each other to find the changes or differences, 
  * Edit CSV files (add, modify or remove settings or attributes) quickly and easily
  * Then, when happy, convert the CSV back to XML for checking into Git and deployment to Salesforce

In advanced usage, we can inspect a change in Git (be it a single commit, or two commits or branches) with this script

* Convert the "from" and "to" state of the change to CSV format
* Diff the CSV files to produce a clear list of the changes within
* (In some cases) take those changes, and apply these to another CSV file (eg: a file I'm trying to resolve merge conflicts with)
* Then, when happy, convert the CSV back to XML for checking into Git and deployment to Salesforce



## How to Install

Ensure you have the dependencies installed
```shell
brew install jq yq
```

Clone this repo to your machine, and link the folder into your Salesforce repository (or put in your path.)
```shell
mkdir -p ~/Documents/GitHub
cd ~/Documents/GitHub
git clone --depth 1 https://github.com/vorno-crole/profile-dedupe.git
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

This created a alphabeticalised deduplicated CSV file.

#### Convert the CSV file format back to Salesforce XML

```shell
~/Documents/GitHub/profile-dedupe/dedupe.sh -m force-app/main/default/profiles/Admin.profile-meta.xml --decode --replace-xml

*** Profile/Permission Set/Custom Label Deduplication script v1.0
by vc@vaughancrole.com

File type: Profile
Decoding force-app/main/default/profiles/Admin.profile-meta.xml.csv to force-app/main/default/profiles/Admin.profile-meta.xml2
Decode time taken: 0
```

#### Round Trip: XML to CSV to XML

Convert XML to alphabeticalised deduplicated CSV, then back to XML

```shell
~/Documents/GitHub/profile-dedupe/dedupe.sh -m force-app/main/default/profiles/Admin.profile-meta.xml --both --replace-xml --remove-csv

*** Profile/Permission Set/Custom Label Deduplication script v1.0
by vc@vaughancrole.com

File type: Profile
Encoding force-app/main/default/profiles/Admin.profile-meta.xml     to force-app/main/default/profiles/Admin.profile-meta.xml.csv
Encode time taken: 1
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

