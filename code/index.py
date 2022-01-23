import boto3
import datetime
import os
import logging

TAG_KEY = os.environ.get('TAG_KEY')
TAG_VALUE = os.environ.get('TAG_VALUE')
logger = logging.getLogger()
logger.setLevel(logging.INFO)

ec2 = boto3.resource('ec2')

# create the tags 
def generate_tags(volumeId, tags):
    tag_final = []
    for tag in tags:
        
        if tag['Key']=='Name':
            tag['Key'] = 'Volume'
        tag_final.append(tag)
            
    tag_final.append({'Key': 'Name', 'Value': f'snapshot-ebs-{volumeId}'})
    tag_final.append({'Key': 'Source',  'Value': 'Généré automatiquement'})
    tag_final.append({'Key': TAG_KEY, 'Value': TAG_VALUE})
    tag_final.append({'Key': 'DateCreation', 'Value': f'{datetime.datetime.now()}'})
  
    return tag_final
    

def lambda_handler(event, context):
    
    volumes = ec2.volumes.filter(Filters=[{'Name': 'status', 'Values': ['available']}]) 
    
    for device in volumes:
                          
        snap = ec2.create_snapshot(
                VolumeId=device.id,
                TagSpecifications=[
                {
                    'ResourceType': 'snapshot',
                    'Tags': generate_tags(device.id, device.tags)
                },
            ])
        
        logger.info(f'Snapshot {snap.id} created for Volume {device.id}.')
        
        # delete volume
        device.delete()
        logger.info(f'Volume {device.id} has been deleted.')
    
    logger.info('EBS snapshot creation completed successfully!')
        
   