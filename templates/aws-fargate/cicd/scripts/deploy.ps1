$prefix="@@CICDTEMPLATE_PROJECT_PREFIX@@"

########################################################################################################################
# DEPLOY STACKS
########################################################################################################################
aws cloudformation deploy --stack-name $prefix-network --template-file cicd/aws/templates/1-network.yml
aws cloudformation deploy --stack-name $prefix-ecs --template-file cicd/aws/templates/2-ecs.yml --capabilities CAPABILITY_NAMED_IAM
# The ECS service is built with a desired count of 0 to allow stack creation to succeed prior to the ECR repo being
# populated.  Here we set the service to a desired count of 2 and update the template for future runs.
aws ecs update-service --cluster $prefix-ecs-fargate-cluster --service $prefix-service --desired-count 2 > $null
aws cloudformation deploy --stack-name $prefix-pipeline --template-file cicd/aws/templates/3-pipeline.yml --capabilities CAPABILITY_NAMED_IAM

########################################################################################################################
# CREATE DEPLOYMENT GROUP
########################################################################################################################
# As of 4/10/20 CloudFormation doesn't support Blue/Green deployments for ECS so we create it with the CLI.
# Monitoring this GitHub issue: https://github.com/aws/containers-roadmap/issues/130
# AWS CloudFormation docs for DeploymentGroup with Blue/Green Deployment Style: 
#   https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-codedeploy-deploymentgroup-deploymentstyle.html
########################################################################################################################
# Update 3/19/22: Issue 130 mentioned above is now resolved, but in a suprisingly limited way.  CloudFormation can 
# create a DeploymentGroup for Blue/Green deployment, but it doesn't support the necessary hooks to integrate with 
# CI/CD.  Namely, declaring output values or importing values from other stacks is not currently supported for templates
# defining Blue/Green ECS deployments.  See new issue: https://github.com/aws-cloudformation/cloudformation-coverage-roadmap/issues/483
########################################################################################################################k
$CFN_CLUSTER_NAME=(aws cloudformation describe-stacks --stack-name $prefix-ecs --query "Stacks[0].Outputs[?OutputKey=='ClusterName'].OutputValue" --output text --no-paginate)
$CFN_SERVICE_NAME=(aws cloudformation describe-stacks --stack-name $prefix-ecs --query "Stacks[0].Outputs[?OutputKey=='ServiceName'].OutputValue" --output text --no-paginate)
$CFN_TG1_NAME=(aws cloudformation describe-stacks --stack-name $prefix-ecs --query "Stacks[0].Outputs[?OutputKey=='TargetGroup1Name'].OutputValue" --output text --no-paginate)
$CFN_TG2_NAME=(aws cloudformation describe-stacks --stack-name $prefix-ecs --query "Stacks[0].Outputs[?OutputKey=='TargetGroup2Name'].OutputValue" --output text --no-paginate)
$CFN_PROD_LISTENER=(aws cloudformation describe-stacks --stack-name $prefix-ecs --query "Stacks[0].Outputs[?OutputKey=='ALBProductionListener'].OutputValue" --output text --no-paginate)
$CFN_TEST_LISTENER=(aws cloudformation describe-stacks --stack-name $prefix-ecs --query "Stacks[0].Outputs[?OutputKey=='ALBTestListener'].OutputValue" --output text --no-paginate)

$CFN_CODEDEPLOY_APP=(aws cloudformation describe-stacks --stack-name $prefix-pipeline --query "Stacks[0].Outputs[?OutputKey=='CodeDeployApplicationName'].OutputValue" --output text --no-paginate)
$CFN_CODEDEPLOY_DG=(aws cloudformation describe-stacks --stack-name $prefix-pipeline --query "Stacks[0].Outputs[?OutputKey=='CodeDeployDeploymentGroupName'].OutputValue" --output text --no-paginate)
$CFN_CODEDEPLOY_SRV_ROLE=(aws cloudformation describe-stacks --stack-name $prefix-pipeline --query "Stacks[0].Outputs[?OutputKey=='CodeDeployServiceRole'].OutputValue" --output text --no-paginate) 

# Check to see if DG already exists and skip creating if it does.
$DG_SEARCH=(aws deploy list-deployment-groups --application-name $CFN_CODEDEPLOY_APP) | Select-String $CFN_CODEDEPLOY_DG
if ($DG_SEARCH -eq $null) {
    # Deployment Group CLI Reference
    # https://docs.aws.amazon.com/cli/latest/reference/deploy/create-deployment-group.html
    aws deploy create-deployment-group `
        --application-name $CFN_CODEDEPLOY_APP `
        --auto-rollback-configuration enabled=true,events=DEPLOYMENT_FAILURE `
        --blue-green-deployment-configuration "deploymentReadyOption={actionOnTimeout=STOP_DEPLOYMENT,waitTimeInMinutes=60},terminateBlueInstancesOnDeploymentSuccess={action=TERMINATE,terminationWaitTimeInMinutes=15}" `
        --deployment-config-name CodeDeployDefault.ECSAllAtOnce `
        --deployment-group-name $CFN_CODEDEPLOY_DG `
        --deployment-style deploymentOption=WITH_TRAFFIC_CONTROL,deploymentType=BLUE_GREEN `
        --ecs-services clusterName=$CFN_CLUSTER_NAME,serviceName=$CFN_SERVICE_NAME `
        --load-balancer-info "targetGroupPairInfoList=[{targetGroups=[{name=$CFN_TG1_NAME},{name=$CFN_TG2_NAME}],prodTrafficRoute={listenerArns=[$CFN_PROD_LISTENER]},testTrafficRoute={listenerArns=[$CFN_TEST_LISTENER]}}]" `
        --service-role-arn $CFN_CODEDEPLOY_SRV_ROLE
}

########################################################################################################################
# CREATE SYSTEM MANAGER PARAMETERS
########################################################################################################################
# As of 3/18/22 CloudFormation doesn't support creating SecureString parameters with the CLI.
Write-Host
Write-Host "Pulling images from DockerHub is severely rate-limited when done anonymously."
Write-Host "To allow CodeBuild to pull images from DockerHub we need a set of login credentials.  (Free account is acceptable)."
Write-host "These credentials will be stored encrypted in AWS SSM Parameter Store using your account's AWS-managed key (AWS KMS)."
$SSM1_SEARCH=(aws ssm describe-parameters --filters "Key=Name,Values=$prefix-DOCKERHUB_USERNAME") | Select-String $prefix-DOCKERHUB_USERNAME
if ($SSM1_SEARCH -eq $null) {
    $USERINPUT_DOCKERHUB_USERNAME = Read-Host "Please provide the Docker Username"
    aws ssm put-parameter --name "$prefix-DOCKERHUB_USERNAME" --value "$USERINPUT_DOCKERHUB_USERNAME" --type "SecureString"
}
$SSM2_SEARCH=(aws ssm describe-parameters --filters "Key=Name,Values=$prefix-DOCKERHUB_PASSWORD") | Select-String $prefix-DOCKERHUB_PASSWORD
if ($SSM1_SEARCH -eq $null) {
    $USERINPUT_DOCKERHUB_PASSWORD = Read-Host -AsSecureString -Prompt "Please provide the Docker Password"
    # Cast to NetworkCredential to retrieve the unencrypted string
    $USERINPUT_DOCKERHUB_PASSWORD = [System.Net.NetworkCredential]::new("", $USERINPUT_DOCKERHUB_PASSWORD).Password
    aws ssm put-parameter --name "$prefix-DOCKERHUB_PASSWORD" --value "$USERINPUT_DOCKERHUB_PASSWORD" --type "SecureString"
}
Write-Host
Write-Host "Note: If you need to change the password later you can do so from the AWS Systems Manager service in the console."

########################################################################################################################
# USER INSTRUCTIONS
########################################################################################################################
Write-Host

$CFN_SSH_CLONE_URL=(aws cloudformation describe-stacks --stack-name $prefix-pipeline --query "Stacks[0].Outputs[?OutputKey=='CloneUrlSsh'].OutputValue" --output text --no-paginate)
$CFN_HTTPS_CLONE_URL=(aws cloudformation describe-stacks --stack-name $prefix-pipeline --query "Stacks[0].Outputs[?OutputKey=='CloneUrlHttp'].OutputValue" --output text --no-paginate )
Write-Host
Write-Host "CodeCommit Clone URLs: "
Write-Host "  * $CFN_SSH_CLONE_URL"
Write-Host "  * $CFN_HTTPS_CLONE_URL"
Write-Host

$CFN_ALB_URL=(aws cloudformation describe-stacks --stack-name $prefix-ecs --query "Stacks[0].Outputs[?OutputKey=='LoadBalancerDNSName'].OutputValue" --output text --no-paginate)
Write-Host "Load Balancer URLs: "
Write-Host "  * TEST: http://$CFN_ALB_URL" ":8080" -separator ""
Write-Host "  * PROD: http://$CFN_ALB_URL"
Write-Host
