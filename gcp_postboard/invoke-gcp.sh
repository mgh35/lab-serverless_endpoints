#!/bin/bash
set -e

export PROJECT=$(gcloud projects list | grep postboard- | grep -v postboard-admin-  | awk '{print $1}')

gcloud functions call GET__random_word --project $PROJECT