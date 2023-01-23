# SourceFuze

## Terraform

Terraform code is in the `terraform` folder. Terraform commands should be run from this folder

I did not understand what files are going to be written to s3.

Currently, the nginx container does not write any files to s3.

## CLI

I used python virtual environments.

All commands should be run from the `sf_cli` folder

```
python -m venv venv
source venv/bin/activate
pip install boto3
```

To run the CLI:

```
python3 main.py --help
```
