import json
import boto3
from io import BytesIO
from PIL import Image
from urllib.parse import unquote_plus

region = "us-east-2"

RAW_BUCKET = "rayyan-raw-s3-bucket-module07"
FINISHED_BUCKET = "rayyan-finished-s3-bucket-module07"
DYNAMODB_TABLE = "company"

s3 = boto3.client("s3", region_name=region)
dynamodb = boto3.client("dynamodb", region_name=region)
sns = boto3.client("sns", region_name=region)


def find_record_by_raw_url(raw_url):
    response = dynamodb.scan(
        TableName=DYNAMODB_TABLE,
        FilterExpression="RAWS3URL = :raw",
        ExpressionAttributeValues={
            ":raw": {"S": raw_url}
        }
    )
    items = response.get("Items", [])
    if not items:
        return None
    return items[0]


def lambda_handler(event, context):
    print("Received event:", json.dumps(event))
    processed = []

    for record in event.get("Records", []):
        bucket = record["s3"]["bucket"]["name"]
        key = unquote_plus(record["s3"]["object"]["key"])

        raw_url = f"https://{bucket}.s3.amazonaws.com/{key}"
        item = find_record_by_raw_url(raw_url)

        if not item:
            print("No DynamoDB record found for:", raw_url)
            continue

        record_number = item["RecordNumber"]["S"]

        obj = s3.get_object(Bucket=bucket, Key=key)
        img_bytes = obj["Body"].read()

        image = Image.open(BytesIO(img_bytes))
        gray_image = image.convert("L")

        output = BytesIO()
        image_format = image.format if image.format else "JPEG"
        gray_image.save(output, format=image_format)
        output.seek(0)

        s3.put_object(
            Bucket=FINISHED_BUCKET,
            Key=key,
            Body=output.getvalue()
        )

        response_presigned = s3.generate_presigned_url(
            "get_object",
            Params={
                "Bucket": FINISHED_BUCKET,
                "Key": key
            },
            ExpiresIn=7200
        )

        dynamodb.update_item(
            TableName=DYNAMODB_TABLE,
            Key={
                "RecordNumber": {
                    "S": record_number
                }
            },
            UpdateExpression="SET RAWS3URL = :done, FINSHIEDURL = :finished, FINSIHEDS3URL = :finished",
            ExpressionAttributeValues={
                ":done": {"S": "done"},
                ":finished": {"S": response_presigned}
            }
        )

        try:
            topics = sns.list_topics().get("Topics", [])
            module07_topics = [
                t["TopicArn"] for t in topics
                if "module07" in t["TopicArn"] or "module-07" in t["TopicArn"]
            ]
            if module07_topics:
                sns.publish(
                    TopicArn=module07_topics[0],
                    Subject="Your image is ready for download!",
                    Message=f"Your image {key} is ready: {response_presigned}"
                )
        except Exception as e:
            print("SNS publish skipped/error:", str(e))

        try:
            s3.delete_object(Bucket=bucket, Key=key)
        except Exception as e:
            print("RAW delete skipped/error:", str(e))

        processed.append({
            "RecordNumber": record_number,
            "Key": key,
            "FinishedURL": response_presigned
        })

    return {
        "statusCode": 200,
        "body": json.dumps(processed)
    }
