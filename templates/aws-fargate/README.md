# aws-fargate Template

This template generates CloudFormation stack templates to create the necessary AWS resources to host your CFML application on AWS ECS/Fargate.  Additionally, it will create a complete CodePipeline CI/CD pipeline to automate the deployment of your application.

## Files created 
**cicd/aws/templates** - this directory contains the CloudFormation templates and supporting files to deploy the architecture.

 * **1-network.yml** - VPC with three public subnets across three Availability Zones and an Internet
  Gateway with a default route on the public subnets.
 * **2-ecs.yml** - Application Load Balancer, ECR Repository, Fargate cluster, Task Definition and ECS Service.
 * **3-pipeline.yml** - CodeCommit Repo, CodeBuild project, CodeDeploy Application and CodePipeline pipeline to automate
   the CI/CD process.

There are two other important files in this directory to be aware of:
  
  * **buildspec.yml** - This defines your build process for building your container image.
  * **task-definition.json** - This file defines the cpu and memory resources that will be use by your containers.

**cicd/docker** - this contains the Dockerfiles used to build the production image (and if you choose to use it the
development image.)

**cicd/scripts** - these are Bash and Powershell scripts used to deploy and undeploy the architecture to AWS. This
requires the **aws-cli** to be installed and configured with your AWS credentials.

🌟 **Once these files are generated they are yours to customize and maintain as part of your project.** 🌟  If you need to make
architectural changes you can modify the CF (CloudFormation) templates and re-run the **deploy.sh** (or **deploy.ps1**) 
script to update your environment OR they can just be used as your starting point and you can manage the resources 
manually after the stacks are initially deployed.

## Quickstart Usage 

**Deployment**

1. Create the template by running `cicd generate` in your commandbox environment
    ```
    box cicd generate template=aws-fargate
    ```
    You'll be prompted for the location of your project's root directory and the prefix name you want to use for naming your cloud resources.  

2. Review and customize generated files in new **cicd** folder.

    Review the `docker/commandbox/Dockerfile` and the CF templates in `aws/templates` to make adjustments for your project. Also consider modifying the `docker/commandbox/Dockerfile.dockerignore` file to exclude files that you don't want in the final production image.

3. Verify your aws-cli

    As mentioned above you need to have **aws-cli** >= 2.0.6 installed in your terminal.  Once installed you should configure it with `aws configure` and then verify connectivity by running `aws cloudformation list-stacks`.

4. Deploy the stacks 

    ◼ Bash: `cicd/scripts/deploy.sh`

    ◼ Powershell: `cicd\scripts\deploy.ps1`

    ❗ Note: The user you configure in the aws-cli must have all the necessary permissions to create the resources described in the CloudFormation templates.  I generally select a user with the `AdministratorAccess` IAM policy.

    ❗ Note: Due to [Docker Hub's pull policy](https://docs.docker.com/docker-hub/download-rate-limit/) you will need to provide **a valid Docker Hub username and password** when prompted by the deploy script. These credentials will be stored encrypted in AWS SSM Parameter Store using your account's AWS-managed key (AWS KMS) and will not be stored anywhere in your local project.  If you need to manage these credentials later you can do so directly from the AWS System Manager console.  If you don't have an account, sign up for a free account here: https://hub.docker.com/. 

5. View resources in AWS console

    If the deployment completes successfully you can view the created resources in your AWS console.  

6. Add CodeCommit repo as a git remote 

    To trigger the CI/CD pipeline you must push to the CodeCommit repo that was created, but first you must add it as a remote.  For example:

    ```
    git remote add origin ssh://<SSHKEYID>@git-codecommit.<REGION>.amazonaws.com/v1/repos/<REPONAME>
    ```

    Note: Using SSH keys with AWS CodeCommit requires that you have an IAM user with valid access to the given repository and that user has a valid SSH key already uploaded on the Security Credentials tab in the console.  If not, you must upload an SSH key to continue or you can attempt to use the HTTPS Git credentials for AWS CodeCommmit.

7. Create a commit and push to CodeCommit 

    ```
    git push --set-upstream origin master
    ```

    Subsequent pushes:

    ```
    git push
    ```

8. Watch pipeline run and verify test application

    Open the CodePipeline console and verify that the build succeeds and the deploy has started. Once the deploy has started it will take a couple of minutes to launch the new "Green" containers.  You can view the status by clicking the "Details" link in the Deploy stage action.

    Once the containers are deployed and test traffic has been routed you can test them using the TEST URL that was output whenever you ran the `deploy.sh` script.

9. Re-route traffic 

    Once your comfortable that your project has deployed successfully to the test target group you can click "Reroute traffic" in the deployment details screen and CodeDeploy will now instruct the Application Load Balancer to route production traffic to your new containers.  

10. Future deployments only require repeating steps 7-9.

**Undeployment**

To remove all the resources (including your CodeCommit repo and ECR repo) you can run the included "undeploy" scripts:

 * Bash: `cicd/scripts/undeploy.sh`
 * Powershell: `cicd\scripts\undeploy.ps1`

:money_with_wings: Note: This configuration will **cost around USD 55.00 per month** (based on prices in us-east-1 as of Februrary 2022) assuming a very minimal amount of activity.