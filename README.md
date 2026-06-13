# AWS Hybrid Connectivity Project

## Overview

This project deploys a hybrid AWS network architecture using Terraform.

The environment consists of:

* Production VPC
* Development VPC
* AWS Transit Gateway
* Route tables for VPC-to-VPC connectivity
* Two EC2 instances in the Production VPC
* One EC2 instance in the Development VPC
* Internet connectivity through Internet Gateways

## Architecture

Production VPC (10.10.0.0/16)

* Production EC2 #1
* Production EC2 #2

Development VPC (10.20.0.0/16)

* Development EC2 #1

Connectivity is established using an AWS Transit Gateway, allowing communication between both VPCs while maintaining separate network boundaries.

## Technologies

* Terraform
* AWS VPC
* AWS EC2
* AWS Transit Gateway
* AWS Route Tables
* AWS Security Groups

## Deployment

Initialize Terraform:

```bash
terraform init
```

Review the execution plan:

```bash
terraform plan
```

Deploy the infrastructure:

```bash
terraform apply
```

## Project Structure

```text
.
├── main.tf
├── variables.tf
├── outputs.tf
├── .gitignore
└── README.md
```

## Skills Demonstrated

* Infrastructure as Code (IaC)
* AWS Networking
* Transit Gateway Configuration
* Route Table Management
* Terraform State Management
* Git and GitHub Version Control

## Author

Derrick McGill

Network Engineer | Cloud Infrastructure | AWS | Terraform

