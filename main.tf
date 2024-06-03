# https://docs.aws.amazon.com/sns/latest/api/API_Publish.html#API_Publish_Examples
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_notification


resource "aws_sqs_queue" "your-sqs" {
  name = "your-sqs"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": "sqs:SendMessage",
      "Resource": "arn:aws:sqs:*:*:your-sqs",
      "Condition": {
        "ArnEquals": { "aws:SourceArn": "arn:aws:sns:*:*:your-sns" }
      }
    },
    {
      "Sid": "Stmt1234",
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": [
        "sqs:ReceiveMessage",
        "sqs:sendMessage"
      ],
      "Resource": "arn:aws:sqs:*:*:your-sqs",
      "Condition": {
        "ArnEquals": {
          "aws:SourceArn": "arn:aws:lambda:*:*:your_lambda"
        }
      }
    }
  ]
}
POLICY
}

resource "aws_s3_bucket" "your-bucket" {
  bucket = "your-bucket"
}

resource "aws_sns_topic" "your-sns" {
  name   = "your-sns"
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
   {
      "Sid": "__default_statement_ID",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "SNS:Publish",
      "Resource": "arn:aws:sns:*:*:your-sns",
      "Condition": {
     
        "ArnLike": {
          "aws:SourceArn": "${aws_s3_bucket.your-bucket.arn}"
        }
      }
    },
    {
      "Sid": "sqs_statement",
      "Effect": "Allow",
      "Principal": "*",
      "Action": ["SNS:Subscribe", "SNS:Receive"],
      "Resource": "arn:aws:sns:*:*:your-sns",
      "Condition": {
        "ArnEquals": { 
          "aws:SourceArn": ["${aws_sqs_queue.your-sqs.arn}"]
        }
      }
    }
  ]
}
POLICY
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.your-bucket.id

  topic {
    topic_arn     = aws_sns_topic.your-sns.arn
    events        = ["s3:ObjectCreated:*"]
    filter_suffix = ".log"
  }
}


resource "aws_sns_topic_subscription" "your_sns_topic_subscription" {
  topic_arn = aws_sns_topic.your-sns.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.your-sqs.arn
}


resource "aws_iam_role" "your_lambda_role" {
  name                 = "your_lambda_role"
  max_session_duration = 3600
  description          = "None"
  assume_role_policy   = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
          "Action": "sts:AssumeRole",
              "Principal": {
                "Service": "lambda.amazonaws.com"
              },
          "Effect": "Allow",
          "Sid": "" 
        }
    ]
}
EOF
}
resource "aws_iam_policy" "your_iam_policy_for_lambda" {

  name        = "aws_iam_policy_for_terraform_aws_lambda_role"
  path        = "/"
  description = "AWS IAM Policy for managing aws lambda role"
  policy      = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": [
       "logs:CreateLogGroup",
       "logs:CreateLogStream",
       "logs:PutLogEvents"
     ],
     "Resource": "arn:aws:logs:*:*:*",
     "Effect": "Allow"
   },
   {
     "Action": [
       "sqs:ReceiveMessage",
       "sqs:DeleteMessage",
       "sqs:GetQueueAttributes"
     ],
     "Resource": "${aws_sqs_queue.your-sqs.arn}",
     "Effect": "Allow"
   }
 ]
}
EOF
}
resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role" {
  role       = aws_iam_role.your_lambda_role.name
  policy_arn = aws_iam_policy.your_iam_policy_for_lambda.arn
}

data "archive_file" "zip_the_python_code" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/"
  output_path = "${path.module}/lambda/hello-python.zip"
}

resource "aws_lambda_function" "your_lambda" {
  filename         = "${path.module}/lambda/hello-python.zip"
  function_name    = "your_lambda"
  role             = aws_iam_role.your_lambda_role.arn
  handler          = "index.lambda_handler"
  runtime          = "python3.8"
  source_code_hash = data.archive_file.zip_the_python_code.output_base64sha256
  depends_on       = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role]
}
resource "aws_lambda_event_source_mapping" "your_lambda_trigger" {
  event_source_arn = aws_sqs_queue.your-sqs.arn
  function_name    = aws_lambda_function.your_lambda.arn
  batch_size       = 10
}
