import os
import sys

sys.path.append('./')

import json
import boto3
from botocore.exceptions import ClientError
from pyzabbix.api import ZabbixAPI


# https://gist.github.com/lrakai/18303e1fc1fb1d8635cc20eee73a06a0

ssm_commands_amz2 = """
    sudo yum install https://repo.zabbix.com/zabbix/5.4/rhel/7/x86_64/zabbix-release-5.4-1.el7.noarch.rpm
    sudo yum install zabbix-agent2
    sudo systemctl start zabbix-agent2
"""

secret_name = os.environ.get('SECRET_NAME')
if secret_name is None:
    secret_name = 'zabbix-user-key'

profile = None
if __name__ == "__main__":
    profile = 'ricardoteixcloud'

session = boto3.Session()
if profile is not None:
    session = boto3.Session(profile_name='ricardoteixcloud')


def lambda_handler(event, context):

    global session

    ec2_resource = session.resource('ec2')
    instance = ec2_resource.Instance(event['detail']['instance-id'])

    print(instance.private_ip_address)
    security_groups = instance.security_groups

    security_groups_ids = [sg['GroupId'] for sg in security_groups]
    
    secret = get_secret(event['region'])
    print(secret)
    
    zabbix_client_sg_id = secret['zabbix_client_sg_id']
    security_groups_ids.append(zabbix_client_sg_id)

    instance.modify_attribute(Groups=security_groups_ids)

    result_add_host = add_zabbix_host(
        url = secret['zabbix_host'], 
        user = secret['zabbix_login'], 
        password = secret['zabbix_password'], 
        user_key_id = secret['id'], 
        user_key_secret = secret['secret'], 
        ec2_ip = instance.private_ip_address, 
        host_name = instance.private_ip_address, 
        instance_id = event['detail']['instance-id'], 
        region = event['region']
    )
    
    return {
        'statusCode': 200,
        'body': {
            'result': result_add_host,
            'privateIpAddress': instance.private_ip_address
        }
    }


def get_secret(region_name):

    global session
    global secret_name
    
    client = session.client(
        service_name='secretsmanager',
        region_name=region_name
    )
    
    try:
        get_secret_value_response = client.get_secret_value(
            SecretId=secret_name
        )
    except ClientError as e:
        if e.response['Error']['Code'] == 'DecryptionFailureException':
            raise e
        elif e.response['Error']['Code'] == 'InternalServiceErrorException':
            raise e
        elif e.response['Error']['Code'] == 'InvalidParameterException':
            raise e
        elif e.response['Error']['Code'] == 'InvalidRequestException':
            raise e
        elif e.response['Error']['Code'] == 'ResourceNotFoundException':
            raise e
    else:
        if 'SecretString' in get_secret_value_response:
            secret = get_secret_value_response['SecretString']
            return json.loads(secret)

    return ''

def add_zabbix_host(url, user, password, user_key_id, user_key_secret, ec2_ip, host_name, instance_id, region):
    
    # Create ZabbixAPI class instance
    zapi = ZabbixAPI(url=url, user=user, password=password)

    # Verifica se existe um host com o mesmo nome. Caso exista, 
    # não adiciona novamente e retorna a lista dos existentes.
    result = zapi.host.get(monitored_hosts=1, output='extend')
    hostnames = [host['host'] for host in result]
    for host in result:
        if host['host'] == ec2_ip:
            zapi.user.logout()
            return hostnames

    result_template = zapi.template.get(
        filter = {
            "name": "AWS EC2 by HTTP"
        }
    )
    print('templateid', result_template[0]['templateid'])

    result_groups = zapi.hostgroup.get(
        filter = {
            "name": "Linux servers"
        }
    )
    print('groupid', result_groups[0]['groupid'])

    result_create = zapi.host.create(
        host = host_name,
        status = 0,
        interfaces = [
            {
                "type": 2,
                "main": 1,
                "useip": 1,
                "ip": ec2_ip,
                "dns": "",
                "port": "10050",
                "details": {
                    "version": 2,
                    "community": "public"
                }
            }
        ],
        groups = [
            {
                "groupid": result_groups[0]['groupid']
            }
        ],
        templates = [
            {
                "templateid": result_template[0]['templateid']
            }
        ],
        macros= [
            {
                "macro": "{$AWS.ACCESS.KEY.ID}",
                "value": user_key_id
            },
            {
                "macro": "{$AWS.SECRET.ACCESS.KEY}",
                "value": user_key_secret
            },
            {
                "macro": "{$AWS.REGION}",
                "value": region
            },
            {
                "macro": "{$AWS.EC2.INSTANCE.ID}",
                "value": instance_id
            }
        ]
    )

    print(result_create)

    # Get all monitored hosts
    result = zapi.host.get(monitored_hosts=1, output='extend')
    hostnames = [host['host'] for host in result]
    print(hostnames)

    # Logout from Zabbix
    zapi.user.logout()

    return result_create


evt = {
    "version": "0",
    "id": "adbc2f0a-36d1-6700-61a3-7a0d26b26280",
    "detail-type": "EC2 Instance State-change Notification",
    "source": "aws.ec2",
    "account": "930779231265",
    "time": "2023-03-07T18:56:11Z",
    "region": "us-east-1",
    "resources": [
        "arn:aws:ec2:us-east-1:930779231265:instance/i-0e12044266efb9d78"
    ],
    "detail": {
        "instance-id": "i-0e12044266efb9d78",
        "state": "pending"
    }
}


if __name__ == "__main__":
    lambda_handler(evt, {})