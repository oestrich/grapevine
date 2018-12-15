#!/bin/bash

sudo -u postgres pg_dump gossip > /opt/backups/gossip-`date +%FT%R`.sql
