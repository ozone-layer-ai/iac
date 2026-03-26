# cert-manager
resource "aws_iam_role" "cert_manager_service_account" {
  name               = "cert_manager-sa-role-kmj"
  path               = "/"
  assume_role_policy = <<-POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "${module.eks.oidc_provider_arn}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "ForAllValues:StringEquals": {
          "${module.eks.oidc_provider}:sub": [
            "system:serviceaccount:cert-manager:cert-manager"
          ]
        }
      }
    }
  ]
}
POLICY
}

resource "aws_iam_policy" "cert_manager_policy" {
  name        = "cert_manager_policy_kmj"
  path        = "/"
  description = "Cert Manager SA Policy"

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": "route53:GetChange",
        "Resource": "arn:aws:route53:::change/*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "route53:ChangeResourceRecordSets",
          "route53:ListResourceRecordSets"
        ],
        "Resource": "arn:aws:route53:::hostedzone/*",
        "Condition": {
          "ForAllValues:StringEquals": {
            "route53:ChangeResourceRecordSetsRecordTypes": ["TXT"]
          }
        }
      },
      {
        "Effect": "Allow",
        "Action": "route53:ListHostedZonesByName",
        "Resource": "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cert_manager_service_account" {
  role       = aws_iam_role.cert_manager_service_account.name
  policy_arn = aws_iam_policy.cert_manager_policy.arn
}

# terraform-operator
resource "aws_iam_role" "terraform_operator_service_account" {
  name               = "terraform-operator-sa-role-kmj"
  path               = "/"
  assume_role_policy = <<-POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "${module.eks.oidc_provider_arn}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "ForAllValues:StringLike": {
          "${module.eks.oidc_provider}:sub": [
            "system:serviceaccount:tf-system:tf-*",
            "system:serviceaccount:org-*:tf-*",
            "system:serviceaccount:tf-system:terraform-operator"
          ]
        }
      }
    }
  ]
}
POLICY
}

resource "aws_iam_policy" "terraform_operator_policy" {
  name        = "terraform_operator_policy_kmj"
  path        = "/"
  description = "Terraform Operator SA Policy"

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ],
        "Resource": [
          "arn:aws:s3:::tf-states-o3",
          "arn:aws:s3:::tf-states-o3/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:Describe*"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateVpc",
          "ec2:DeleteVpc",
          "ec2:ModifyVpcAttribute",

          "ec2:CreateSubnet",
          "ec2:DeleteSubnet",
          "ec2:ModifySubnetAttribute",

          "ec2:CreateInternetGateway",
          "ec2:AttachInternetGateway",
          "ec2:DetachInternetGateway",
          "ec2:DeleteInternetGateway",

          "ec2:CreateRouteTable",
          "ec2:DeleteRouteTable",
          "ec2:AssociateRouteTable",
          "ec2:DisassociateRouteTable",
          "ec2:CreateRoute",
          "ec2:DeleteRoute",

          "ec2:CreateNatGateway",
          "ec2:DeleteNatGateway",

          "ec2:AllocateAddress",
          "ec2:ReleaseAddress",
          "ec2:DisassociateAddress",

          "ec2:DescribeAddresses",
          "ec2:DescribeInstances",

          "ec2:ModifyNetworkInterfaceAttribute",
          "ec2:ModifyInstanceAttribute",

          "ec2:CreateSecurityGroup",
          "ec2:DeleteSecurityGroup",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:AuthorizeSecurityGroupEgress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupEgress",

          "ec2:CreateTags",
          "ec2:DeleteTags",

          "ec2:CreateNetworkAclEntry",
          "ec2:DeleteNetworkAclEntry"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:Describe*",
          "elasticloadbalancing:CreateLoadBalancer",
          "elasticloadbalancing:DeleteLoadBalancer",
          "elasticloadbalancing:CreateListener",
          "elasticloadbalancing:DeleteListener",
          "elasticloadbalancing:CreateTargetGroup",
          "elasticloadbalancing:DeleteTargetGroup",
          "elasticloadbalancing:RegisterTargets",
          "elasticloadbalancing:DeregisterTargets",
          "elasticloadbalancing:AddTags",
          "elasticloadbalancing:RemoveTags"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "iam:GetRole",
          "iam:PassRole",
          "iam:ListRoles",
          "iam:GetInstanceProfile",
          "iam:ListInstanceProfiles"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "terraform_operator_service_account" {
  role       = aws_iam_role.terraform_operator_service_account.name
  policy_arn = aws_iam_policy.terraform_operator_policy.arn
}