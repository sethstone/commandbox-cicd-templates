#!/bin/sh

${AWS_PAGER+"false"} && unset _AWS_PAGER || _AWS_PAGER="$AWS_PAGER"
export AWS_PAGER=""
prefix="@@CICDTEMPLATE_PROJECT_PREFIX@@"

aws deploy delete-deployment-group --application-name ${prefix}-codedeploy-app --deployment-group-name ${prefix}-codedeploy-app-dg
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

${_AWS_PAGER+"false"} && unset AWS_PAGER || AWS_PAGER="$_AWS_PAGER"