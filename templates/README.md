# aws-fargate Template

This template generates CloudFormation stack templates to create the necessary AWS resources to host your CFML
application on AWS ECS/Fargate.  Additionally, it will create a complete CodePipeline CI/CD pipeline to automate the
testing and deployment of your application.

## Files created 
**cicd/aws/templates** - this directory contains the CloudFormation templates and supporting files to deploy the architecture.

 * **1-network.yml** - VPC with three public subnets across three Availability Zones and an Internet
  Gateway with a default route on the public subnets.
 * **2-ecs.yml** - Application Load Balancer, ECR Repository, Fargate cluster, Task Definition and ECS Service.
 * **3-pipeline.yml** - CodeCommit Repo, CodeBuild project, CodeDeploy Application and CodePipeline pipeline to automate
   the CI/CD process.

There are two other important files in this directory to be aware of:
  
  * **buildspec.yml** - This defines your build process for building your container image and testing it.
  * **task-definition.json** - This file defines the cpu and memory resources that will be use by your containers.

**cicd/docker** - this contains the Dockerfiles used to build the production image (and if you choose to use the
development image.)

**cicd/scripts** - these are Bash and Powershell scripts used to deploy and undeploy the architecture to AWS. This
requires the **aws-cli** to be installed and configured with your AWS credentials.

🌟 Once these files are generated they are yours to customize and maintain as part of your project.  If you need to make
architectural changes you can modify the CF (CloudFormation) templates and re-run the **deploy.sh** (or **deploy.ps1**) 
script to update your environment.  OR they can just be used as your starting point and you can manage the resources 
manually after the stacks are initially generated.

## Usage 
(1) Create the template by running `cicd generate` in your commandbox environment
```
box cicd generate template=aws-fargate
```
You'll be prompted for the location of your project's root directory and the prefix name you want to use for naming your
cloud resources.  

(2) Review and customize generated files.

Review the docker/commandbox/Dockerfile and the CF templates in aws/templates to make adjustments for your project.
Also consider modifying the `.dockerignore` file in your project root to exclude files that you don't want in the final 
production image.

(3) Verify your aws-cli

As mentioned above you need to have **aws-cli** >= 2.0.6 installed in your terminal.  Once installed you should
configure it with `aws configure` and then verify connectivity by running `aws cloudformation list-stacks`.

(4) Deploy the stacks 

 * Bash: `cicd/scripts/deploy.sh`
 * Powershell: `cicd\scripts\deploy.ps1`

(5) View resources in AWS console

If the deployment completes successfully you can view the created resources in your AWS console.  

(6) Add CodeCommit repo as a git remote 

To trigger the CI/CD pipeline you must push to the CodeCommit repo that was created, but first you must add it as a
remote.  For example:

```
git remote add origin ssh://ACCESSKEYID@git-codecommit.<REGION>.amazonaws.com/v1/repos/<REPONAME>
```

(7) Create a commit and push to CodeCommit 

(8) Watch pipeline run and verify test application

Open the CodePipeline console and verify that the build succeeds and the deploy has started. Once the deploy has started
it will take a couple of minutes to launch the new "Green" containers.  You can view the status by clicking the
"Details" link in the Deploy stage action.

Once the containers are deployed and test traffic has been routed you can test them using the TEST URL that was output
whenever you ran the `deploy.sh` script.

(9) Re-route traffic 

Once your comfortable that your project has deployed to the test target group you can click "Reroute traffic" in the
deployment details screen and CodeDeploy will now instruct the Application Load Balancer to route production traffic to
your new containers.  

(10) Future deployments would only require repeating steps 7-10.

**Undeployment**

To remove all the resources (including your CodeCommit repo and ECR repo) you can run the included "undeploy" scripts:

 * Bash: `cicd/scripts/undeploy.sh`
 * Powershell: `cicd\scripts\undeploy.ps1`