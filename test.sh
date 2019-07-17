#!/bin/bash
   
TOKEN="0389c33b-e3af-4377-8ac0-14e798345a5f"
URL="https://secure.sysdig.com/api/scanning/v1/anchore"
IMAGE="docker-mailmain:latest"
##################
# Internal Vars
##################
DIGEST=""
RETRIES=96
 
DIGEST=$(curl -s -k --request POST --header "Accept: application/json" --header "Content-Type: application/json" -H "Authorization: Bearer ${TOKEN}" --data '{"tag":'\"${IMAGE}\"'}' ${URL}/images/ | jq -r ".[].imageDigest" 2>/dev/null)
[ $? -ne 0 ] && echo "Error adding image to scan queue!" && exit 1
STATUS=$(curl -s -k --header "Content-Type: application/json" -H "Authorization: Bearer ${TOKEN}" ${URL}/images/${DIGEST} | jq -r ".[].analysis_status" 2>/dev/null)
[ $? -ne 0 ] && echo "Error getting analysus status!" && exit 1
FULLTAG=$(curl -s -k --request POST --header "Accept: application/json" --header "Content-Type: application/json" -H "Authorization: Bearer ${TOKEN}" --data '{"tag":'\"${IMAGE}\"'}' ${URL}/images/ |  jq -r ".[].image_detail[0].fulltag" 2>/dev/null )
[ $? -ne 0 ] && echo "Error getting image full tag!" && exit 1
 
echo $STATUS
 
for ((i=0;  i<${RETRIES}; i++)); do
    status=$(curl -s -k  --header "Content-Type: application/json" -H "Authorization: Bearer ${TOKEN}" "${URL}/images/${DIGEST}/check?tag=$FULLTAG&detail=false" | grep "status" | awk '{print $2}')
    if [ ! -z  "$status" ]; then
        echo "Status is $status"
        break
    fi
    echo -n "." && sleep 5
done
 
echo "Scan Report - "
curl -s -k --header "Content-Type: application/json" -H "Authorization: Bearer ${TOKEN}" "${URL}/images/${DIGEST}/check?tag=$FULLTAG&detail=true"
 
echo "$status" | grep -v fail
exit $?