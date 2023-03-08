
# Cria uma função Lambda chamada "zabbix-add-host"
# resource "aws_lambda_function" "zabbix-add-host" {
#   function_name = "zabbix-add-host"
#   handler       = "index.lambda_handler"
#   role         = aws_iam_role.zabbix-lambda-role.arn
#   publish       = true
#   runtime      = "python3.9"
#   filename     = "zabbix-add-host.zip"  # nome do arquivo ZIP contendo o código da função
# }

# Faz upload do código da função Lambda para a AWS
resource "aws_lambda_function" "zabbix-add-host" {
    function_name = "zabbix-add-host"
    handler       = "lambda_function.lambda_handler"
    publish       = true
    runtime      = "python3.9"
    timeout = 15
    role         = aws_iam_role.zabbix-lambda-role.arn
    filename      = data.archive_file.lambda_function.output_path
    source_code_hash = data.archive_file.lambda_function.output_base64sha256
    environment {
        variables = {
            SECRET_NAME = aws_secretsmanager_secret.zabbix-user-secret-key.name,
        }
    }
}

# Cria uma política de segurança que permite a função Lambda acessar o Secret Manager "zabbix-user-secret"
resource "aws_iam_policy" "zabbix-user-secret-access-policy" {
  name        = "zabbix-user-secret-access-policy"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = aws_secretsmanager_secret.zabbix-user-secret-key.arn
      }
    ]
  })
}

# Cria uma política de segurança que permite a função Lambda publicar logs no CloudWatch
resource "aws_iam_policy" "zabbix-log-policy" {
  name        = "zabbix-log-policy"
  policy      = jsonencode(
    {
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow",
                Action = "logs:CreateLogGroup",
                Resource = "arn:aws:logs:${var.regiao}:${var.conta-aws}:*"
            },
            {
              Effect = "Allow",
              Action = [
                "logs:CreateLogStream",
                "logs:PutLogEvents"
              ],
              Resource = [
                "arn:aws:logs:${var.regiao}:${var.conta-aws}:log-group:/aws/lambda/${aws_lambda_function.zabbix-add-host.function_name}:*"
              ]
            }
        ]
    })
}

# Cria uma política de segurança que permite a função Lambda acessar recursos do EC2
resource "aws_iam_policy" "zabbix-ec2-policy" {
  name        = "zabbix-ec2-policy"
  policy      = jsonencode(
    {
        Version = "2012-10-17"
        Statement = [
          {
              Sid = "VisualEditor0",
              Effect = "Allow",
              Action = [
                  "ec2:DescribeInstances",
                  "ec2:TerminateInstances",
                  "ec2:DescribeTags",
                  "ec2:ModifyInstanceAttribute"
              ],
              Resource = "*"
          },
          {
              Sid = "VisualEditor1",
              Effect = "Allow",
              Action = "ssm:SendCommand",
              Resource = "arn:aws:ec2:${var.regiao}:${var.conta-aws}:instance/*"
          }
        ]
    })
}

# Cria uma função IAM que permite a função Lambda acessar o Secret Manager "zabbix-user-secret"
resource "aws_iam_role" "zabbix-lambda-role" {
  name = "zabbix-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Anexa a política de segurança à função IAM
resource "aws_iam_role_policy_attachment" "zabbix-user-secret-access-policy-attachment" {
  policy_arn = aws_iam_policy.zabbix-user-secret-access-policy.arn
  role       = aws_iam_role.zabbix-lambda-role.name
}

# Anexa a política de segurança à função IAM
resource "aws_iam_role_policy_attachment" "zabbix-log-policy-attachment" {
  policy_arn = aws_iam_policy.zabbix-log-policy.arn
  role       = aws_iam_role.zabbix-lambda-role.name
}

# Anexa a política de segurança à função IAM
resource "aws_iam_role_policy_attachment" "zabbix-ec2-policy-attachment" {
  policy_arn = aws_iam_policy.zabbix-ec2-policy.arn
  role       = aws_iam_role.zabbix-lambda-role.name
}

# Define o código da função Lambda
data "archive_file" "lambda_function" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/zabbix-add-host.zip"
}


# Cria uma regra de evento que é ativada sempre que uma nova instância EC2 é criada
resource "aws_cloudwatch_event_rule" "detect-ec2-instance-rule" {
  name = "detect-ec2-instance-rule"
  description = "Trigger zabbix-add-host function on new EC2 instance creation"
  event_pattern = jsonencode(
        {
            source = [
                "aws.ec2"
            ],
            detail-type = [
                "EC2 Instance State-change Notification"
            ],
            detail = {
                state = [
                    "pending"
                ]
            }
        }
    )
}

# Configura a permissão da função Lambda para ser invocada pela regra de evento
resource "aws_lambda_permission" "event_rule_lambda_permission" {
  statement_id = "AllowExecutionFromCloudWatchEvent"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.zabbix-add-host.arn
  principal = "events.amazonaws.com"
  source_arn = aws_cloudwatch_event_rule.detect-ec2-instance-rule.arn
}

# Associa a regra de evento à função Lambda
resource "aws_cloudwatch_event_target" "zabbix_add_host_lambda_target" {
  rule = aws_cloudwatch_event_rule.detect-ec2-instance-rule.name
  arn = aws_lambda_function.zabbix-add-host.arn
}

# Cria um trigger para a função Lambda que executa a cada vez que uma nova mensagem é enviada para uma fila SQS
# resource "aws_lambda_event_source_mapping" "sqs_trigger" {
#   event_source_arn  = aws_sqs_queue.zabbix-add-host_queue.arn
#   function_name     = aws_lambda_function.zabbix-add-host.function_name
#   batch_size        = 1
#   starting_position = "latest
