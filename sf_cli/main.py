import boto3
import argparse

def list_files(bucket_name):
    s3 = boto3.client('s3')
    response = s3.list_objects(Bucket=bucket_name)
    for content in response.get('Contents', []):
        print(content.get('Key'))

def list_deployment_versions(cluster_name, service_name):
    ecs = boto3.client('ecs')
    response = ecs.list_task_definition_families(status='ALL')
    task_definition_families = response['families']
    for task_definition_family in task_definition_families:
        response = ecs.list_task_definitions(familyPrefix=task_definition_family)
        task_definitions = response['taskDefinitionArns']
        for task_definition in task_definitions:
            response = ecs.describe_services(cluster=cluster_name,services=[service_name])
            for service in response['services']:
                if service['taskDefinition'] == task_definition:
                    print(task_definition)

def build_s3_parser(parser):
    list_command = parser.add_parser('list', help='List files in an S3 bucket')
    list_command.add_argument('-b', '--bucket_name', type=str, help='Name of the S3 bucket', required=True)
    list_command.add_argument('-n', '--num_files', type=int, help='Number of files to list', required=False, default=10)
    list_command.add_argument('-r', '--region', type=str, help='AWS region', required=False, default='us-east-1')

def build_ecs_parser(parser):
    versions_command = parser.add_parser('versions', help='List versions of an ECS deployment')
    versions_command.add_argument('-c', '--cluster_name', type=str, help='Name of the ECS cluster', required=True)
    versions_command.add_argument('-s', '--service_name', type=str, help='Name of the ECS service', required=True)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='List files in an S3 bucket and versions of an ECS deployment')

    subparsers = parser.add_subparsers(dest='command')
    build_s3_parser(subparsers)
    build_ecs_parser(subparsers)

    args = parser.parse_args()

    if args.command == "list":
        list_files(args.bucket_name)
    elif args.command == "versions":
        list_deployment_versions(args.cluster_name, args.service_name)
    else:
        print("Unknown command: {}".format(args.command))
