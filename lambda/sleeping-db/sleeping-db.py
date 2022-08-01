import json
import boto3
import logging

logger = logging.getLogger(__name__)
logging.getLogger().setLevel(logging.INFO)

def handler(event, context):

    instance_identifier = event['instance_identifier']
    
    client = boto3.client('rds')

    # DEBUG
    r = client.describe_db_instances(DBInstanceIdentifier=instance_identifier)
    logger.info('describe_db_instances(DBInstanceIdentifier=instance_identifier)')
    logger.info(json.dumps(r, default=str))

    if event['action'] == 'sleep':
        r = client.stop_db_instance(DBInstanceIdentifier=instance_identifier)

        return {
            'statusCode': 200,
            'body': f"Instance {instance_identifier} has been stopped"
        }
    
    if event['action'] == 'wake':

        r = client.start_db_instance(DBInstanceIdentifier=instance_identifier)
        logger.info('start_db_instance(DBInstanceIdentifier=instance_identifier)')
        logger.info(r)

        return {
            'statusCode': 200,
            'body': f"Instance {instance_identifier} has been started"
        }

    return {
        'statusCode': 400,
        'body': "Please provide an action (sleep or wake)"
    }
