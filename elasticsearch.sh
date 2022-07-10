#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

"${currentPath}/../core/script/run.sh" "elasticsearch:all" "${currentPath}/elasticsearch/elasticsearch.sh"
