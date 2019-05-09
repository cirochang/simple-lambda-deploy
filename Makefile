#global config
AWS_LAMBDA_FUNCTION=FooBarLambdaFunction
AWS_LAMBDA_ROLE=arn:aws:iam::00000000:role/foobar-role

#stg config
STG_AWS_LAMBDA_SUBNETS=subnet-foobar-a,subnet-foobar-b
STG_AWS_LAMBDA_SECURITY_GROUP=sg-foobar

STG_ENV_VARS="Variables={ \
	FOO_BAR=foobarfoo, \
	BAR_FOO=barfoobar, \
}"

#prd config
PRD_AWS_LAMBDA_SUBNETS=subnet-foobar-a,subnet-foobar-b
PRD_AWS_LAMBDA_SECURITY_GROUP=sg-foobar

PRD_ENV_VARS="Variables={ \
	FOO_BAR=foobarfoo, \
	BAR_FOO=barfoobar, \
}"

#script
build:
	npm install
	zip -r --exclude=*Makefile* upload.zip .

create_function:
	aws lambda create-function --function-name ${AWS_LAMBDA_FUNCTION} --role ${AWS_LAMBDA_ROLE} --handler index.handler --runtime nodejs8.10 --zip-file fileb://upload.zip

create_stg_alias:
	aws lambda create-alias --function-name ${AWS_LAMBDA_FUNCTION} --name stg --function-version "\$$LATEST"

create_prd_alias:
	aws lambda create-alias --function-name ${AWS_LAMBDA_FUNCTION} --name prd --function-version "\$$LATEST"

create:
	$(MAKE) create_function
	$(MAKE) create_stg_alias
	$(MAKE) create_prd_alias

deploy-stg:
	aws lambda update-function-configuration \
		--function-name ${AWS_LAMBDA_FUNCTION} \
		--environment ${STG_ENV_VARS} \
		--handler index.handler --runtime nodejs8.10 \
		--vpc-config "SubnetIds=${STG_AWS_LAMBDA_SUBNETS}, SecurityGroupIds=${STG_AWS_LAMBDA_SECURITY_GROUP}"
	aws lambda update-function-code --function-name ${AWS_LAMBDA_FUNCTION} --zip-file fileb://upload.zip
	# publish version
	$(eval RESPONSE = $(shell aws lambda publish-version --function-name ${AWS_LAMBDA_FUNCTION} --description staging --output text))
	# get version number
	$(eval VERSION = $(shell echo $(RESPONSE) | awk -F '[[:space:]][[:space:]]*' '{print $$13}'))
	# link alias to version
	aws lambda update-alias --function-name ${AWS_LAMBDA_FUNCTION} --name stg --function-version $(VERSION)

deploy-prd:
	aws lambda update-function-configuration \
		--function-name ${AWS_LAMBDA_FUNCTION} \
		--environment ${PRD_ENV_VARS} \
		--handler index.handler --runtime nodejs8.10 \
		--vpc-config "SubnetIds=${PRD_AWS_LAMBDA_SUBNETS}, SecurityGroupIds=${PRD_AWS_LAMBDA_SECURITY_GROUP}"
	aws lambda update-function-code --function-name ${AWS_LAMBDA_FUNCTION} --zip-file fileb://upload.zip
	# publish version
	$(eval RESPONSE = $(shell aws lambda publish-version --function-name ${AWS_LAMBDA_FUNCTION} --description prod --output text))
	# get version number
	$(eval VERSION = $(shell echo $(RESPONSE) | awk -F '[[:space:]][[:space:]]*' '{print $$13}'))
	# link alias to version
	aws lambda update-alias --function-name ${AWS_LAMBDA_FUNCTION} --name prd --function-version $(VERSION)
