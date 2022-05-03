#!/bin/bash -e

cd /usr/share/elasticsearch

echo "Installing Elasticsearch plugin: analysis-phonetic"
sudo bin/elasticsearch-plugin install analysis-phonetic

echo "Installing Elasticsearch plugin: analysis-icu"
sudo bin/elasticsearch-plugin install analysis-icu

echo "Restarting Elasticsearch"
sudo service elasticsearch restart
