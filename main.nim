import httpclient
import json
import strutils
import os


const url = "https://raw.githubusercontent.com/robiningelbrecht/wca-rest-api/master/api/competitions.json"
let pwd = getAppDir()
let config = pwd & "/config.json"
let storage = pwd & "/competitions.txt"

try:
  discard parseFile(config)
  assert(os.existsFile(storage) == true)
except:
  echo "Config files not found. Please run './setup.sh'."
  quit(0)

let config_data = parseFile(config)
let region = config_data["region"].getStr()

let client = newHttpClient()

var indices: seq[int]

let response = client.getContent(url)
let parsed = parseJson(response)["items"]
let num_competitions = len(parsed)
for i in 0..(num_competitions-1):
  let year = parsed[i]["date"]["from"].getStr()[0..3]
  if year == "2025": # make sure this stays up to date
    let city = parsed[i]["city"].getStr()
    if region in city:
      indices.add(i)

var new_competitions: seq[string] = @[]

for index in indices:
  new_competitions.add(parsed[index]["name"].getStr())

client.close()

var known_competitions: seq[string] = @[]

var file = open(storage,fmRead)
known_competitions = readAll(file).split("\n")
for value in 0..<known_competitions.len:
  known_competitions[value] = known_competitions[value].strip(chars={'\n'})
file.close()

var num_new_competitions = 0

for index in 0..<new_competitions.len:
  if new_competitions[index] in known_competitions:
    new_competitions[index] = "%"
  else:
    echo new_competitions[index] & " is new!"
    inc num_new_competitions

if num_new_competitions > 0:
  echo $num_new_competitions & " new competitions found!"
  echo "adding to database..."

  file = open(storage,fmAppend)

  for index in 0..<new_competitions.len:
    if new_competitions[index] != "%":
      file.writeLine(new_competitions[index])

  file.close()
else:
  echo "No new competitions found. Known Competitons: "
  discard os.execShellCmd("cat " & pwd & "/competitions.txt")
