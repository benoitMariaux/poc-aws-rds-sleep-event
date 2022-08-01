data "archive_file" "lambda_sleeping_db" {
  type = "zip"

  source_dir  = "${path.module}/lambda/sleeping-db"
  output_path = "${path.module}/sleeping-db/sleeping-db.zip"
}

resource "aws_s3_object" "lambda_sleeping_db" {
  bucket = aws_s3_bucket.lambda_bucket.id

  key    = "sleeping-db.zip"
  source = data.archive_file.lambda_sleeping_db.output_path

  etag = filemd5(data.archive_file.lambda_sleeping_db.output_path)
}

resource "aws_lambda_function" "lambda_sleeping_db" {
  function_name = "SleepingDB"

  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key    = aws_s3_object.lambda_sleeping_db.key

  runtime = "python3.8"
  handler = "sleeping-db.handler"

  source_code_hash = data.archive_file.lambda_sleeping_db.output_base64sha256

  role = aws_iam_role.lambda_sleeping_db_exec.arn
}

resource "aws_cloudwatch_log_group" "lambda_sleeping_db" {
  name = "/aws/lambda/${aws_lambda_function.lambda_sleeping_db.function_name}"

  retention_in_days = 30
}

resource "aws_iam_role" "lambda_sleeping_db_exec" {
  name = "lambda_sleeping_db_exec"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_sleeping_db_policy_attachment" {
  role       = aws_iam_role.lambda_sleeping_db_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy" "lambda_sleeping_db_policy_for_rds_policy" {
  name        = "lambda_sleeping_db_policy_for_rds_policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "RDS:DESCRIBEDBINSTANCES",
        "RDS:STARTDBINSTANCE",
        "RDS:STOPDBINSTANCE"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "lambda_sleeping_db_policy_for_rds_policy_attachment" {
  name       = "lambda_sleeping_db_policy_for_rds_policy_attachment"
  roles      = [aws_iam_role.lambda_sleeping_db_exec.name]
  policy_arn = aws_iam_policy.lambda_sleeping_db_policy_for_rds_policy.arn
}

##########################
# Lambda evocation rules
resource "aws_cloudwatch_event_rule" "sleep_db_at_night" {
    name = "sleep_db_at_night"
    description = "sleep_db_at_night"
    schedule_expression = "cron(0 20 * ? 1-5 *)"
    #schedule_expression = "rate(5 minutes)"
}

resource "aws_cloudwatch_event_target" "sleep_db_at_night_target" {
    rule = aws_cloudwatch_event_rule.sleep_db_at_night.name
    target_id = "lambda_sleeping_db"
    input     = "{\"action\":\"sleep\", \"instance_identifier\":\"${aws_db_instance.db.id}\"}"
    arn = aws_lambda_function.lambda_sleeping_db.arn
}

resource "aws_cloudwatch_event_rule" "wake_db_on_the_morning" {
    name = "wake_db_on_the_morning"
    description = "wake_db_on_the_morning"
    schedule_expression = "cron(0 8 * ? 1-5 *)"
    #schedule_expression = "rate(5 minutes)"
}

resource "aws_cloudwatch_event_target" "wake_db_on_the_morning_target" {
    rule = aws_cloudwatch_event_rule.sleep_db_at_night.name
    target_id = "lambda_sleeping_db"
    input     = "{\"action\":\"wake\", \"instance_identifier\":\"${aws_db_instance.db.id}\"}"
    arn = aws_lambda_function.lambda_sleeping_db.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_lambda" {
    statement_id = "AllowExecutionFromCloudWatch"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.lambda_sleeping_db.function_name
    principal = "events.amazonaws.com"
    source_arn = aws_cloudwatch_event_rule.sleep_db_at_night.arn
}