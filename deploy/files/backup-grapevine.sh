#!/bin/bash

sudo -u postgres pg_dump grapevine > /opt/backups/grapevine-`date +%FT%R`.sql
