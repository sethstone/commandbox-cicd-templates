# commandbox-cicd-templates
Generate infrastructure-as-code files for deploying CFML application to your favorite cloud platforms.

## Package Installation

You will need [CommandBox](https://www.ortussolutions.com/products/commandbox) installed to use this tool.

From within the terminal, simply run the following command to install the module.
```
$ box install commandbox-cicd-templates
```

## Usage 
```
$ box cicd generate
```
OR
```
$ box cicd generate template=<template-name>
```

## Available Templates

- **aws-fargate** - CloudFormation templates for Blue/Green deployment to AWS Fargate using CodeDeploy. (See template
[README.md](https://github.com/sethstone/commandbox-cicd-templates/blob/master/templates/aws-fargate/README.md) for more
information.)

## General Instructions for using templates
Each template can provide its own usage instructions and may prompt the user for input parameters specific to the
template.  By convention the templates should prompt you for your project's root directory and generate their files in a
sub-folder called **cicd**. 

Refer to the README.md file in each template's directory (`templates/<template-name>/README.md`).