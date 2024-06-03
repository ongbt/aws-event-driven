import json


def lambda_handler(event, context):
    # parsed = json.loads(event)
    print(json.dumps(event, indent=4, sort_keys=True))

    return {
        'message': event['Records'][0]['body']
    }
