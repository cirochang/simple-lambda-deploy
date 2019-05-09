# Simple Lambda Deploy

> Simple Makefile to help deploy your lambda functions created by Ciro Chang and Thiago Marcal.

## How to use
Put this makefile in the same directory of your "lambda project".
Change the config variables of the Makefile to suit the settings of your lambda function.
Then, run the follow commands (make sure your aws account is set up in your system):

``` bash
# build the project
make build
# create the lambda function in your aws account
make create_function
# create staging alias
make create_stg_alias
# create production alias
make create_prd_alias
# deploy staging
make deploy-stg
# deploy production
make deploy-prd
```