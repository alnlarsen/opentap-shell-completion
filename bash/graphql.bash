
graphql () {
  local IFS=$'\n'
  local repo="$1"
  local query='
  query Query { packages(distinctName: true, name: "OpenT.*", version: "Any") {
  name
  description }}'

  local response=$(curl -X POST "$repo/3.1/Query" -H "Accept: application/json" -H "Content-Type: application/x-www-form-urlencoded" -d "$query" 2> /dev/null)
  local items=($( echo "$response" | yq '.packages[] | ( (.name | sub(":", "\:")) + ":" + ( .description | sub("\n", " ")))' ))
  for i in ${items[@]}
  do 
    echo "${i%%<*}"
  done
}
