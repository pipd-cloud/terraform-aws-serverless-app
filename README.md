<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.9 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_batch"></a> [batch](#module\_batch) | ./modules/batch | n/a |
| <a name="module_cache"></a> [cache](#module\_cache) | ./modules/cache | n/a |
| <a name="module_database"></a> [database](#module\_database) | ./modules/database | n/a |
| <a name="module_ecr_repo"></a> [ecr\_repo](#module\_ecr\_repo) | ./modules/ecr | n/a |
| <a name="module_ecs_cluster"></a> [ecs\_cluster](#module\_ecs\_cluster) | ./modules/ecs_cluster | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_tags"></a> [aws\_tags](#input\_aws\_tags) | Additional AWS tags to apply to resources in this module. | `map(string)` | `{}` | no |
| <a name="input_batch"></a> [batch](#input\_batch) | The AWS Batch configuration to apply, if any. | <pre>object(<br/>    {<br/>      iam_custom_policy = optional(<br/>        list(<br/>          object(<br/>            {<br/>              sid       = string<br/>              effect    = string<br/>              actions   = list(string)<br/>              resources = list(string)<br/>              conditions = optional(list(object({<br/>                test     = string<br/>                variable = string<br/>                values   = list(string)<br/>                }<br/>                )<br/>                ),<br/>                []<br/>              )<br/>            }<br/>          )<br/>        ),<br/>        []<br/>      )<br/>      iam_managed_policies = optional(list(string), [])<br/>      batch_compute = optional(<br/>        object(<br/>          {<br/>            type      = optional(string, "FARGATE_SPOT")<br/>            max_vcpus = optional(number, 16)<br/>          }<br/>        ),<br/>        {<br/>          type      = "FARGATE_SPOT"<br/>          max_vcpus = 16<br/>        }<br/>      )<br/>    }<br/>  )</pre> | `{}` | no |
| <a name="input_cache_config"></a> [cache\_config](#input\_cache\_config) | The configuration for the cache. | <pre>object({<br/>    auto_minor_version_upgrade = optional(bool, true)<br/>    node_type                  = optional(string, "cache.t3.medium")<br/>    transit_encryption_enabled = optional(bool, false)<br/>    num_cache_nodes            = optional(number, 1)<br/>    apply_immediately          = optional(bool, false)<br/>    engine_version             = optional(string, "7.1")<br/>    port                       = optional(number, 6379)<br/>    parameter_group_family     = optional(string, "redis7")<br/>    maintenance_window         = optional(string, "sun:05:00-sun:06:00")<br/>    parameters = optional(map(object({<br/>      name  = string<br/>      value = string<br/>    })), {})<br/>  })</pre> | `{}` | no |
| <a name="input_cache_inbound_sg_ids"></a> [cache\_inbound\_sg\_ids](#input\_cache\_inbound\_sg\_ids) | The list of security groups that may access the cache. | `list(string)` | `[]` | no |
| <a name="input_cache_serverless"></a> [cache\_serverless](#input\_cache\_serverless) | Whether to use a serverless cache. | `bool` | `true` | no |
| <a name="input_cache_serverless_config"></a> [cache\_serverless\_config](#input\_cache\_serverless\_config) | The configuration for the cache. | <pre>object({<br/>    data_storage = object({<br/>      min = number<br/>      max = number<br/>    })<br/>    ecpu = object({<br/>      min = number<br/>      max = number<br/>    })<br/>    ttl = object({<br/>      create = optional(string, "40m")<br/>      update = optional(string, "80m")<br/>      delete = optional(string, "40m")<br/>    })<br/>  })</pre> | <pre>{<br/>  "data_storage": {<br/>    "max": 2,<br/>    "min": 1<br/>  },<br/>  "ecpu": {<br/>    "max": 2000,<br/>    "min": 1000<br/>  },<br/>  "ttl": {<br/>    "create": "40m",<br/>    "delete": "40m",<br/>    "update": "80m"<br/>  }<br/>}</pre> | no |
| <a name="input_db_acu_config"></a> [db\_acu\_config](#input\_db\_acu\_config) | Minimum and maximum ACU to allocate to instances in the cluster. | <pre>object({<br/>    min = number<br/>    max = number<br/>  })</pre> | <pre>{<br/>  "max": 1,<br/>  "min": 0.5<br/>}</pre> | no |
| <a name="input_db_allow_major_version_upgrade"></a> [db\_allow\_major\_version\_upgrade](#input\_db\_allow\_major\_version\_upgrade) | Whether to allow major version upgrades for the database. | `bool` | `false` | no |
| <a name="input_db_cluster_snapshot"></a> [db\_cluster\_snapshot](#input\_db\_cluster\_snapshot) | The cluster snapshot from which to create the database. | `string` | `null` | no |
| <a name="input_db_copy_tags_to_snapshot"></a> [db\_copy\_tags\_to\_snapshot](#input\_db\_copy\_tags\_to\_snapshot) | Whether to copy tags to the database snapshot. | `bool` | `true` | no |
| <a name="input_db_engine"></a> [db\_engine](#input\_db\_engine) | The engine to use for the database. | `string` | `"postgresql"` | no |
| <a name="input_db_engine_version"></a> [db\_engine\_version](#input\_db\_engine\_version) | The version of the engine to deploy. | `string` | n/a | yes |
| <a name="input_db_iam_auth_enabled"></a> [db\_iam\_auth\_enabled](#input\_db\_iam\_auth\_enabled) | Whether to enable IAM authentication for the database. | `bool` | `false` | no |
| <a name="input_db_inbound_sg_ids"></a> [db\_inbound\_sg\_ids](#input\_db\_inbound\_sg\_ids) | The list of security groups that may access the database. | `list(string)` | `[]` | no |
| <a name="input_db_instance_count"></a> [db\_instance\_count](#input\_db\_instance\_count) | The number of instances in the cluster. | `number` | `1` | no |
| <a name="input_db_instance_snapshot"></a> [db\_instance\_snapshot](#input\_db\_instance\_snapshot) | The instance snapshot from which to create the database. | `string` | `null` | no |
| <a name="input_db_monitoring_interval"></a> [db\_monitoring\_interval](#input\_db\_monitoring\_interval) | The interval, in seconds, between points when Enhanced Monitoring metrics are collected. | `number` | `60` | no |
| <a name="input_db_performance_insights_enabled"></a> [db\_performance\_insights\_enabled](#input\_db\_performance\_insights\_enabled) | Whether to enable Performance Insights for the database. | `bool` | `true` | no |
| <a name="input_db_performance_insights_retention_period"></a> [db\_performance\_insights\_retention\_period](#input\_db\_performance\_insights\_retention\_period) | The number of days to retain Performance Insights data. | `number` | `7` | no |
| <a name="input_db_preferred_backup_window"></a> [db\_preferred\_backup\_window](#input\_db\_preferred\_backup\_window) | The daily time range during which automated backups are created. | `string` | `"00:00-05:00"` | no |
| <a name="input_db_preferred_maintenance_window"></a> [db\_preferred\_maintenance\_window](#input\_db\_preferred\_maintenance\_window) | The weekly time range during which system maintenance can occur. | `string` | `"sun:05:00-sun:06:00"` | no |
| <a name="input_db_proxy"></a> [db\_proxy](#input\_db\_proxy) | Whether to create an RDS proxy. | `bool` | `false` | no |
| <a name="input_db_public_instance_count"></a> [db\_public\_instance\_count](#input\_db\_public\_instance\_count) | The number of public instances in the DB cluster. | `number` | `0` | no |
| <a name="input_db_storage_encrypted"></a> [db\_storage\_encrypted](#input\_db\_storage\_encrypted) | Whether to enable storage encryption for the database. | `bool` | `true` | no |
| <a name="input_ecr_config"></a> [ecr\_config](#input\_ecr\_config) | The configuration to use for the ECR repositories. | <pre>list(<br/>    object(<br/>      {<br/>        name                 = string<br/>        image_tag_mutability = optional(string, "MUTABLE")<br/>        lifecycle_policy_rules = optional(<br/>          map(<br/>            object(<br/>              {<br/>                description     = string<br/>                tag_status      = string<br/>                tag_prefix_list = optional(list(string), [])<br/>                count_type      = string<br/>                count_unit      = optional(string)<br/>                count_number    = number<br/>              }<br/>            )<br/>          ),<br/>          {}<br/>        )<br/>      }<br/>    )<br/>  )</pre> | `[]` | no |
| <a name="input_ecs_cluster_inbound_sg_ids"></a> [ecs\_cluster\_inbound\_sg\_ids](#input\_ecs\_cluster\_inbound\_sg\_ids) | The list of security groups that are allowed to access the ECS cluster resources. | `list(string)` | `[]` | no |
| <a name="input_ecs_cluster_secrets"></a> [ecs\_cluster\_secrets](#input\_ecs\_cluster\_secrets) | A set of secrets to store on Secrets Manager for the ECS cluster. | `map(string)` | `{}` | no |
| <a name="input_ecs_load_balancer"></a> [ecs\_load\_balancer](#input\_ecs\_load\_balancer) | The configuration to use for the Load Balancer. | <pre>object(<br/>    {<br/>      domain          = optional(string)<br/>      public          = optional(bool, true)<br/>      security_groups = optional(list(string), [])<br/>      prefix_lists    = optional(list(string), [])<br/>      waf             = optional(bool, false)<br/>    }<br/>  )</pre> | n/a | yes |
| <a name="input_id"></a> [id](#input\_id) | The unique identifier for this deployment. | `string` | n/a | yes |
| <a name="input_sns_topic"></a> [sns\_topic](#input\_sns\_topic) | The ARN of the SNS topic to which to send notifications. | `string` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The ID of the AWS VPC. | `string` | n/a | yes |
| <a name="input_vpc_private_subnets"></a> [vpc\_private\_subnets](#input\_vpc\_private\_subnets) | The IDs of the private subnets in the VPC. | `list(string)` | n/a | yes |
| <a name="input_vpc_public_subnets"></a> [vpc\_public\_subnets](#input\_vpc\_public\_subnets) | The IDs of the public subnets in the VPC. | `list(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_aurora_cluster"></a> [aurora\_cluster](#output\_aurora\_cluster) | The RDS Aurora cluster. |
| <a name="output_aurora_cluster_instances"></a> [aurora\_cluster\_instances](#output\_aurora\_cluster\_instances) | The RDS Aurora database instances. |
| <a name="output_aurora_cluster_proxy"></a> [aurora\_cluster\_proxy](#output\_aurora\_cluster\_proxy) | The RDS Aurora cluster proxy. |
| <a name="output_aurora_cluster_proxy_sg"></a> [aurora\_cluster\_proxy\_sg](#output\_aurora\_cluster\_proxy\_sg) | The RDS Aurora security group for the cluster proxy. |
| <a name="output_aurora_cluster_sg"></a> [aurora\_cluster\_sg](#output\_aurora\_cluster\_sg) | The RDS Aurora security group. |
| <a name="output_batch_compute_environment"></a> [batch\_compute\_environment](#output\_batch\_compute\_environment) | The Batch compute environment. |
| <a name="output_batch_job_queue"></a> [batch\_job\_queue](#output\_batch\_job\_queue) | The Batch job queue. |
| <a name="output_batch_task_role"></a> [batch\_task\_role](#output\_batch\_task\_role) | The IAM role for Batch tasks. |
| <a name="output_ecr_repos"></a> [ecr\_repos](#output\_ecr\_repos) | The ECR repositories. |
| <a name="output_ecs_cluster"></a> [ecs\_cluster](#output\_ecs\_cluster) | The ECS cluster. |
| <a name="output_ecs_cluster_http_listener"></a> [ecs\_cluster\_http\_listener](#output\_ecs\_cluster\_http\_listener) | The HTTP listener for the cluster load balancer. |
| <a name="output_ecs_cluster_https_listener"></a> [ecs\_cluster\_https\_listener](#output\_ecs\_cluster\_https\_listener) | The HTTPS listener for the cluster load balancer. |
| <a name="output_ecs_cluster_load_balancer"></a> [ecs\_cluster\_load\_balancer](#output\_ecs\_cluster\_load\_balancer) | Load balancer for the cluster. |
| <a name="output_ecs_cluster_load_balancer_sg"></a> [ecs\_cluster\_load\_balancer\_sg](#output\_ecs\_cluster\_load\_balancer\_sg) | Cluster load balancer security group. |
| <a name="output_ecs_cluster_secrets"></a> [ecs\_cluster\_secrets](#output\_ecs\_cluster\_secrets) | The ECS cluster SecretsManager Secret. |
| <a name="output_ecs_cluster_sg"></a> [ecs\_cluster\_sg](#output\_ecs\_cluster\_sg) | The ECS cluster security group. |
| <a name="output_ecs_cluster_task_execution_role"></a> [ecs\_cluster\_task\_execution\_role](#output\_ecs\_cluster\_task\_execution\_role) | The ECS cluster task execution role. |
| <a name="output_redis_cluster"></a> [redis\_cluster](#output\_redis\_cluster) | The Elasticache Redis cache. |
| <a name="output_redis_cluster_sg"></a> [redis\_cluster\_sg](#output\_redis\_cluster\_sg) | The Elasticache Redis security group. |
<!-- END_TF_DOCS -->