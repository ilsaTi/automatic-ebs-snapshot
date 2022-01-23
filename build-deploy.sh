#!/bin/bash

rm code/index.zip
cd code/
zip index.zip index.py
cd ..
terraform validate
terraform destroy
terraform apply