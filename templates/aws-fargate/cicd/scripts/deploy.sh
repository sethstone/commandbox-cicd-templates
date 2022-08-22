#!/bin/bash

${AWS_PAGER+"false"} && unset _AWS_PAGER || _AWS_PAGER="$AWS_PAGER"
export AWS_PAGER=""
prefix="@@CICDTEMPLATE_PROJECT_PREFIX@@"

########################################################################################################################
# CONFIRM CWD
########################################################################################################################
if [ ! -d cicd ]; then
    echo "The 'cicd' folder was not found in the current directory; please switch to your project root before running this script."
    exit 1
fi

########################################################################################################################
# DEPLOY STACKS
########################################################################################################################
aws cloudformation deploy --stack-name ${prefix}-network --template-file cicd/aws/templates/1-network.yml
aws cloudformation deploy --stack-name ${prefix}-ecs --template-file cicd/aws/templates/2-ecs.yml --capabilities CAPABILITY_NAMED_IAM
# The ECS service is built with a desired count of 0 to allow stack creation to succeed prior to the ECR repo being
# populated.  Here we set the service to a desired count of 2 and update the template for future runs.
aws ecs update-service --cluster ${prefix}-ecs-fargate-cluster --service ${prefix}-service --desired-count 2 > /dev/null
aws cloudformation deploy --stack-name ${prefix}-pipeline --template-file cicd/aws/templates/3-pipeline.yml --capabilities CAPABILITY_NAMED_IAM

########################################################################################################################
# UPLOAD TEMPLATE ENV FILES TO S3
########################################################################################################################
if [ -f cicd/env/build-testing.env.tmpl ]; then
   aws s3 cp cicd/env/build-testing.env.tmpl s3://${prefix}-env-build-testing/build-testing.env
fi
if [ -f cicd/env/prod.env.tmpl ]; then
    aws s3 cp cicd/env/prod.env.tmpl s3://${prefix}-env-prod/prod.env
fi

########################################################################################################################
# CREATE SYSTEMS MANAGER PARAMETERS
########################################################################################################################
# As of 3/18/22 CloudFormation doesn't support creating SecureString parameters with the CLI.
echo 
echo "Pulling images from DockerHub is severely rate-limited when done anonymously."
echo "To allow CodeBuild to pull images from DockerHub we need a set of login credentials.  (Free account is acceptable)."
echo "These credentials will be stored encrypted in AWS SSM Parameter Store using your account's AWS-managed key (AWS KMS)."
aws ssm describe-parameters --filters "Key=Name,Values=${prefix}-DOCKERHUB_USERNAME" | grep -q ${prefix}-DOCKERHUB_USERNAME
if [ $? -eq 1 ]; then 
    read -p "Please provide the Docker Username: " USERINPUT_DOCKERHUB_USERNAME
    aws ssm put-parameter --name "${prefix}-DOCKERHUB_USERNAME" --value "${USERINPUT_DOCKERHUB_USERNAME}" --type "SecureString"
fi
aws ssm describe-parameters --filters "Key=Name,Values=${prefix}-DOCKERHUB_PASSWORD" | grep -q ${prefix}-DOCKERHUB_PASSWORD
if [ $? -eq 1 ]; then 
    read -s -p "Please provide the Docker Password (input hidden): " USERINPUT_DOCKERHUB_PASSWORD
    aws ssm put-parameter --name "${prefix}-DOCKERHUB_PASSWORD" --value "${USERINPUT_DOCKERHUB_PASSWORD}" --type "SecureString"
fi
echo 
echo "Note: If you need to change the password later you can do so from the AWS Systems Manager service console."

########################################################################################################################
# USER INSTRUCTIONS
########################################################################################################################
echo
echo 'CodeCommit Clone URLs: '
echo -n '  * '
aws cloudformation describe-stacks --stack-name ${prefix}-pipeline --query "Stacks[0].Outputs[?OutputKey=='CloneUrlSsh'].OutputValue" --output text --no-paginate 
echo -n '  * '
aws cloudformation describe-stacks --stack-name ${prefix}-pipeline --query "Stacks[0].Outputs[?OutputKey=='CloneUrlHttp'].OutputValue" --output text --no-paginate 
echo
CFN_ALB_URL=$(aws cloudformation describe-stacks --stack-name ${prefix}-ecs --query "Stacks[0].Outputs[?OutputKey=='LoadBalancerDNSName'].OutputValue" --output text --no-paginate )
echo 'Load Balancer URLs: '
echo "  * TEST: http://${CFN_ALB_URL}:8080"
echo "  * PROD: http://${CFN_ALB_URL}"
echo


# Reset the AWS CLI pager either to unset or its original value
${_AWS_PAGER+"false"} && unset AWS_PAGER || AWS_PAGER="$_AWS_PAGER"
