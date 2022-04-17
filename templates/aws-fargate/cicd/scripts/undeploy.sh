#!/bin/bash

${AWS_PAGER+"false"} && unset _AWS_PAGER || _AWS_PAGER="$AWS_PAGER"
export AWS_PAGER=""
prefix="@@CICDTEMPLATE_PROJECT_PREFIX@@"

echo "Deleting ${prefix}-pipeline stack..."
aws cloudformation delete-stack --stack-name ${prefix}-pipeline
aws cloudformation wait stack-delete-complete --stack-name ${prefix}-pipeline --no-paginate
echo "${prefix}-pipeline delete finished."
echo "Deleting ${prefix}-ecs stack..."
aws cloudformation delete-stack --stack-name ${prefix}-ecs
aws cloudformation wait stack-delete-complete --stack-name ${prefix}-ecs --no-paginate
echo "${prefix}-ecs delete finished."
echo "Deleting ${prefix}-network stack..."
aws cloudformation delete-stack --stack-name ${prefix}-network
aws cloudformation wait stack-delete-complete --stack-name ${prefix}-network --no-paginate
echo "${prefix}-network delete finished."

# Delete SSM Parameters for DockerHub
echo "Deleting AWS Systems Manager parameters for DockerHub ..."
aws ssm delete-parameter --name "${prefix}-DOCKERHUB_USERNAME"
aws ssm delete-parameter --name "${prefix}-DOCKERHUB_PASSWORD"
echo "Finished deleting parameters."

${_AWS_PAGER+"false"} && unset AWS_PAGER || AWS_PAGER="$_AWS_PAGER"