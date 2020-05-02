$prefix="@@CICDTEMPLATE_PROJECT_PREFIX@@"

aws deploy delete-deployment-group --application-name $prefix-codedeploy-app --deployment-group-name $prefix-codedeploy-app-dg
Write-Host "Deleting $prefix-pipeline stack..."
aws cloudformation delete-stack --stack-name $prefix-pipeline
aws cloudformation wait stack-delete-complete --stack-name $prefix-pipeline --no-paginate
Write-Host "$prefix-pipeline delete finished."
Write-Host "Deleting $prefix-ecs stack..."
aws cloudformation delete-stack --stack-name $prefix-ecs
aws cloudformation wait stack-delete-complete --stack-name $prefix-ecs --no-paginate
Write-Host "$prefix-ecs delete finished."
Write-Host "Deleting $prefix-network stack..."
aws cloudformation delete-stack --stack-name $prefix-network
aws cloudformation wait stack-delete-complete --stack-name $prefix-network --no-paginate
Write-Host "$prefix-network delete finished."