#!/bin/bash

while read assign; do
 export "$assign";
done < <(sed -nE 's/([a-z_0-9]+): (.*)/\1=\2/ p' parameters.yaml)

aws configure set default.region $region

awsAccountId=$(aws sts get-caller-identity --query Account --output text)
timestamp=$(date "+%Y%m%d-%H%M%S")
stackName=$stackNamePrefix-$timestamp
lambdaBucketName=${stackNamePrefix//[^[:alnum:]]/}-$timestamp

aws s3 mb s3://$lambdaBucketName
zip function.zip lambda_function.py
aws s3 cp function.zip s3://${stackNamePrefix//[^[:alnum:]]/}-$timestamp

aws cloudformation create-stack --stack-name $stackName --template-body file://cloudformation.yaml --capabilities CAPABILITY_NAMED_IAM --parameters ParameterKey=PermissionsBoundary,ParameterValue=$permissionBoundary ParameterKey=LambdaCodeBucket,ParameterValue=$lambdaBucketName ParameterKey=LambdaCodeKey,ParameterValue=function.zip

aws cloudformation wait stack-create-complete --stack-name $stackName

aws s3 rb s3://$lambdaBucketName --force

echo "Custom Config Rule Created Successfully"

