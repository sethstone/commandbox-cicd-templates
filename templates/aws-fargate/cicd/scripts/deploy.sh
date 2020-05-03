#!/bin/bash

${AWS_PAGER+"false"} && unset _AWS_PAGER || _AWS_PAGER="$AWS_PAGER"
export AWS_PAGER=""
prefix="@@CICDTEMPLATE_PROJECT_PREFIX@@"

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
# CREATE DEPLOYMENT GROUP
########################################################################################################################
# As of 4/10/20 CloudFormation doesn't support Blue/Green deployments for ECS so we create it with the CLI.
# Monitoring this GitHub issue: https://github.com/aws/containers-roadmap/issues/130
# AWS CloudFormation docs for DeploymentGroup with Blue/Green Deployment Style: 
#   https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-codedeploy-deploymentgroup-deploymentstyle.html
CFN_CLUSTER_NAME=$(aws cloudformation describe-stacks --stack-name ${prefix}-ecs --query "Stacks[0].Outputs[?OutputKey=='ClusterName'].OutputValue" --output text --no-paginate)
CFN_SERVICE_NAME=$(aws cloudformation describe-stacks --stack-name ${prefix}-ecs --query "Stacks[0].Outputs[?OutputKey=='ServiceName'].OutputValue" --output text --no-paginate)
CFN_TG1_NAME=$(aws cloudformation describe-stacks --stack-name ${prefix}-ecs --query "Stacks[0].Outputs[?OutputKey=='TargetGroup1Name'].OutputValue" --output text --no-paginate)
CFN_TG2_NAME=$(aws cloudformation describe-stacks --stack-name ${prefix}-ecs --query "Stacks[0].Outputs[?OutputKey=='TargetGroup2Name'].OutputValue" --output text --no-paginate)
CFN_PROD_LISTENER=$(aws cloudformation describe-stacks --stack-name ${prefix}-ecs --query "Stacks[0].Outputs[?OutputKey=='ALBProductionListener'].OutputValue" --output text --no-paginate)
CFN_TEST_LISTENER=$(aws cloudformation describe-stacks --stack-name ${prefix}-ecs --query "Stacks[0].Outputs[?OutputKey=='ALBTestListener'].OutputValue" --output text --no-paginate)

CFN_CODEDEPLOY_APP=$(aws cloudformation describe-stacks --stack-name ${prefix}-pipeline --query "Stacks[0].Outputs[?OutputKey=='CodeDeployApplicationName'].OutputValue" --output text --no-paginate)
CFN_CODEDEPLOY_DG=$(aws cloudformation describe-stacks --stack-name ${prefix}-pipeline --query "Stacks[0].Outputs[?OutputKey=='CodeDeployDeploymentGroupName'].OutputValue" --output text --no-paginate)
CFN_CODEDEPLOY_SRV_ROLE=$(aws cloudformation describe-stacks --stack-name ${prefix}-pipeline --query "Stacks[0].Outputs[?OutputKey=='CodeDeployServiceRole'].OutputValue" --output text --no-paginate)

# Check to see if DG already exists and skip creating if it does.
aws deploy list-deployment-groups --application-name ${CFN_CODEDEPLOY_APP} | grep -q ${CFN_CODEDEPLOY_DG}
if [ $? -eq 1 ]; then 
    # Deployment Group CLI Reference
    # https://docs.aws.amazon.com/cli/latest/reference/deploy/create-deployment-group.html
    aws deploy create-deployment-group \
        --application-name ${CFN_CODEDEPLOY_APP} \
        --auto-rollback-configuration enabled=true,events=DEPLOYMENT_FAILURE \
        --blue-green-deployment-configuration "deploymentReadyOption={actionOnTimeout=STOP_DEPLOYMENT,waitTimeInMinutes=60},terminateBlueInstancesOnDeploymentSuccess={action=TERMINATE,terminationWaitTimeInMinutes=15}" \
        --deployment-config-name CodeDeployDefault.ECSAllAtOnce \
        --deployment-group-name ${CFN_CODEDEPLOY_DG} \
        --deployment-style deploymentOption=WITH_TRAFFIC_CONTROL,deploymentType=BLUE_GREEN \
        --ecs-services clusterName=${CFN_CLUSTER_NAME},serviceName=${CFN_SERVICE_NAME} \
        --load-balancer-info "targetGroupPairInfoList=[{targetGroups=[{name=${CFN_TG1_NAME}},{name=${CFN_TG2_NAME}}],prodTrafficRoute={listenerArns=[${CFN_PROD_LISTENER}]},testTrafficRoute={listenerArns=[${CFN_TEST_LISTENER}]}}]" \
        --service-role-arn ${CFN_CODEDEPLOY_SRV_ROLE}
fi

########################################################################################################################
# USER INSTRUCTIONS
########################################################################################################################
echo
aws cloudformation describe-stacks --stack-name ${prefix}-pipeline --query "Stacks[0].Outputs[?OutputKey=='CloneUrlSsh'].OutputValue" --output text --no-paginate 
aws cloudformation describe-stacks --stack-name ${prefix}-pipeline --query "Stacks[0].Outputs[?OutputKey=='CloneUrlHttp'].OutputValue" --output text --no-paginate 
echo
echo -n 'http://'
aws cloudformation describe-stacks --stack-name ${prefix}-ecs --query "Stacks[0].Outputs[?OutputKey=='LoadBalancerDNSName'].OutputValue" --output text --no-paginate 


# Reset the AWS CLI pager either to unset or its original value
${_AWS_PAGER+"false"} && unset AWS_PAGER || AWS_PAGER="$_AWS_PAGER"