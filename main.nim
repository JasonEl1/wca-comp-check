import httpclient
import json
import strutils
import os
import times

#url / path constants
const url = "https://raw.githubusercontent.com/robiningelbrecht/wca-rest-api/master/api/competitions.json"
let pwd = getAppDir()
let config = pwd & "/config.json"
let storage = pwd & "/competitions.txt"

let current_date = now()

try: #check if config file exists
  discard parseFile(config)
except:
  echo "Config files not found. Please run './setup.sh'."
  quit(0)

try:
  assert(os.fileExists(storage) == true)
except:
  discard os.execShellCmd("touch competitions.txt")

proc get_known_competitions(storage: string): seq[string]= # get sequence of known competitions
  var file = open(storage,fmRead)
  var known_competitions: seq[string] = @[]
  known_competitions = readAll(file).split("\n")
  for value in 0..<known_competitions.len:
    known_competitions[value] = known_competitions[value].strip(chars={'\n'})
  file.close()
  return known_competitions

# get config data from file
let config_data = parseFile(config)
let region = config_data["region"].getStr()

let client = newHttpClient()

var new_competitions: seq[string] = @[]
var known_competitions = get_known_competitions(storage)
var num_new: int = 0

let response = client.getContent(url)
let parsed = parseJson(response)["items"]
let num_competitions = len(parsed)
for i in 0..(num_competitions-1):
  let is_known = parsed[i]["name"].getStr() in known_competitions
  let date = parse(parsed[i]["date"]["till"].getStr(),"yyyy-MM-dd")
  if (date - current_date).inDays > 0:
    let city = parsed[i]["city"].getStr()
    if region in city and not is_known:
      new_competitions.add(parsed[i]["name"].getStr())
      echo $(parsed[i]["name"].getStr()) & " is new!"
      inc num_new
  else:
    if(is_known):
      known_competitions.delete(known_competitions.find(parsed[i]["name"].getStr()))
      echo $(parsed[i]["name"].getStr()) & " has passed."
      echo "removing from database..."

client.close()

var file = open(storage,fmWrite)

for index in 0..<new_competitions.len:
  if(new_competitions[index] != ""):
    file.writeLine(new_competitions[index])
for index in 0..<known_competitions.len:
  if(known_competitions[index] != ""):
    file.writeLine(known_competitions[index])

file.close()

if num_new > 0:
  echo $num_new & " new competitions found!"
  echo "adding to database...\n"
else:
  echo "No new competitions found. Known Competitons: \n"

discard os.execShellCmd("cat " & pwd & "/competitions.txt")
