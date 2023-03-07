# IAM Role 
resource "aws_iam_role" "projeto-role" {
  name = "${var.tag-base}-role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Action = "sts:AssumeRole"
          Effect = "Allow"
          Sid    = ""
          Principal = {
            Service = "ec2.amazonaws.com"
          }
        },
      ]
    }
  )
  tags = {
    Name = "${var.tag-base}-role"
  }
}

resource "aws_iam_instance_profile" "projeto-profile" {
  name = "${var.tag-base}-profile"
  role = aws_iam_role.projeto-role.name
}

resource "aws_iam_role_policy" "projeto-policy" {
  name = "${var.tag-base}-policy"
  role = aws_iam_role.projeto-role.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "sns:Publish"
            ],
            "Resource": [
                "${aws_sns_topic.projeto-events.arn}"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_user" "zabbix-user" {
  name = "zabbix-user"
  
  tags = {
    Name = "${var.tag-base}-zabbix-user"
  }
}

resource "aws_iam_user_policy" "zabbix-user-policy" {
  name = "zabbix-user-policy"
  user = aws_iam_user.zabbix-user.name
    
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "cloudwatch:Describe*",
        "cloudwatch:Get*",
        "cloudwatch:List*",
        "ec2:Describe*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_access_key" "zabbix-user-key" {
  user = aws_iam_user.zabbix-user.name
}