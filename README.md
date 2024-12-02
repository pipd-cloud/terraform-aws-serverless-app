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
| <a name="module_ecr_batch_repo"></a> [ecr\_batch\_repo](#module\_ecr\_batch\_repo) | ./modules/ecr | n/a |
| <a name="module_ecr_service_repos"></a> [ecr\_service\_repos](#module\_ecr\_service\_repos) | ./modules/ecr | n/a |
| <a name="module_ecs_cluster"></a> [ecs\_cluster](#module\_ecs\_cluster) | ./modules/ecs_cluster | n/a |
| <a name="module_ecs_services"></a> [ecs\_services](#module\_ecs\_services) | ./modules/ecs_service | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_tags"></a> [aws\_tags](#input\_aws\_tags) | Additional AWS tags to apply to resources in this module. | `map(string)` | `{}` | no |
| <a name="input_batch"></a> [batch](#input\_batch) | The AWS Batch configuration to apply, if any. | <pre>object(<br/>    {<br/>      container = object(<br/>        {<br/>          name    = optional(string, "batch")<br/>          tag     = optional(string)<br/>          cpu     = optional(number, 1)<br/>          memory  = optional(number, 2048)<br/>          command = optional(list(string), [])<br/>          environment = optional(list(<br/>            object(<br/>              {<br/>                name  = string<br/>                value = string<br/>              }<br/>            )<br/>            ),<br/>            []<br/>          )<br/>          secret_keys         = optional(list(string), [])<br/>          cluster_secret_keys = optional(list(string), [])<br/>        }<br/>      )<br/>      iam_custom_policy = optional(<br/>        list(<br/>          object(<br/>            {<br/>              sid       = string<br/>              effect    = string<br/>              actions   = list(string)<br/>              resources = list(string)<br/>              conditions = optional(list(object({<br/>                test     = string<br/>                variable = string<br/>                values   = list(string)<br/>                }<br/>                )<br/>                ),<br/>                []<br/>              )<br/>            }<br/>          )<br/>        ),<br/>        []<br/>      )<br/>      iam_managed_policies = optional(list(string), [])<br/>      batch_compute = optional(<br/>        object(<br/>          {<br/>            type      = optional(string, "FARGATE_SPOT")<br/>            max_vcpus = optional(number, 16)<br/>          }<br/>        ),<br/>        {<br/>          type      = "FARGATE_SPOT"<br/>          max_vcpus = 16<br/>        }<br/>      )<br/>    }<br/>  )</pre> | `null` | no |
| <a name="input_cache_config"></a> [cache\_config](#input\_cache\_config) | The configuration for the cache. | <pre>object({<br/>    data_storage = object({<br/>      min = number<br/>      max = number<br/>    })<br/>    ecpu = object({<br/>      min = number<br/>      max = number<br/>    })<br/>    ttl = object({<br/>      create = optional(string, "40m")<br/>      update = optional(string, "80m")<br/>      delete = optional(string, "40m")<br/>    })<br/>  })</pre> | <pre>{<br/>  "data_storage": {<br/>    "max": 2,<br/>    "min": 1<br/>  },<br/>  "ecpu": {<br/>    "max": 2000,<br/>    "min": 1000<br/>  },<br/>  "ttl": {<br/>    "create": "40m",<br/>    "delete": "40m",<br/>    "update": "80m"<br/>  }<br/>}</pre> | no |
| <a name="input_cache_inbound_sg_ids"></a> [cache\_inbound\_sg\_ids](#input\_cache\_inbound\_sg\_ids) | The list of security groups that may access the cache. | `list(string)` | `[]` | no |
| <a name="input_db_acu_config"></a> [db\_acu\_config](#input\_db\_acu\_config) | Minimum and maximum ACU to allocate to instances in the cluster. | <pre>object({<br/>    min = number<br/>    max = number<br/>  })</pre> | <pre>{<br/>  "max": 1,<br/>  "min": 0.5<br/>}</pre> | no |
| <a name="input_db_engine_version"></a> [db\_engine\_version](#input\_db\_engine\_version) | The version of the engine to deploy. | `string` | `null` | no |
| <a name="input_db_inbound_sg_ids"></a> [db\_inbound\_sg\_ids](#input\_db\_inbound\_sg\_ids) | The list of security groups that may access the database. | `list(string)` | `[]` | no |
| <a name="input_db_instance_count"></a> [db\_instance\_count](#input\_db\_instance\_count) | The number of instances in the cluster. | `number` | `1` | no |
| <a name="input_db_proxy"></a> [db\_proxy](#input\_db\_proxy) | Whether to create an RDS proxy. | `bool` | `false` | no |
| <a name="input_db_source_snapshot"></a> [db\_source\_snapshot](#input\_db\_source\_snapshot) | The snapshot from which to create the database. | `string` | `null` | no |
| <a name="input_ecs_cluster_inbound_sg_ids"></a> [ecs\_cluster\_inbound\_sg\_ids](#input\_ecs\_cluster\_inbound\_sg\_ids) | The list of security groups that are allowed to access the ECS cluster resources. | `list(string)` | `[]` | no |
| <a name="input_ecs_cluster_secrets"></a> [ecs\_cluster\_secrets](#input\_ecs\_cluster\_secrets) | A set of secrets to store on Secrets Manager for the ECS cluster. | `map(string)` | `null` | no |
| <a name="input_ecs_services"></a> [ecs\_services](#input\_ecs\_services) | The list of ECS services to create. | <pre>list(<br/>    object(<br/>      {<br/>        container = object(<br/>          {<br/>            name    = string<br/>            digest  = string<br/>            port    = number<br/>            cpu     = optional(number, 2048)<br/>            memory  = optional(number, 4096)<br/>            command = optional(list(string), [])<br/>            environment = optional(<br/>              list(<br/>                object(<br/>                  {<br/>                    name  = string<br/>                    value = string<br/>                  }<br/>                )<br/>              ),<br/>              []<br/>            )<br/>            secret_keys         = optional(list(string), [])<br/>            cluster_secret_keys = optional(list(string), [])<br/>            health_check_route  = optional(string, "/")<br/>          }<br/>        )<br/>        iam_custom_policy = optional(<br/>          list(<br/>            object(<br/>              {<br/>                sid       = string<br/>                effect    = string<br/>                actions   = list(string)<br/>                resources = list(string)<br/>                conditions = optional(<br/>                  list(<br/>                    object(<br/>                      {<br/>                        test     = string<br/>                        variable = string<br/>                        values   = list(string)<br/>                      }<br/>                    )<br/>                  ),<br/>                  []<br/>                )<br/>              }<br/>            )<br/>          ),<br/>          []<br/>        )<br/>        iam_managed_policies = optional(list(string), [])<br/>        scale_policy = optional(<br/>          object(<br/>            {<br/>              min_capacity       = number<br/>              max_capacity       = number<br/>              cpu_target         = number<br/>              scale_in_cooldown  = number<br/>              scale_out_cooldown = number<br/>            }<br/>          ),<br/>          {<br/>            min_capacity       = 1<br/>            max_capacity       = 8<br/>            cpu_target         = 70<br/>            memory_target      = 70<br/>            scale_in_cooldown  = 60<br/>            scale_out_cooldown = 60<br/>          }<br/>        )<br/>        load_balancer = optional(<br/>          object(<br/>            {<br/>              public          = optional(bool, true)<br/>              security_groups = optional(list(string), [])<br/>              prefix_lists    = optional(list(string), [])<br/>              waf             = optional(bool, false)<br/>              tls = optional(<br/>                object(<br/>                  {<br/>                    domain = string<br/>                  }<br/>                )<br/>              )<br/>            }<br/>          )<br/>        )<br/>      }<br/>    )<br/>  )</pre> | `[]` | no |
| <a name="input_id"></a> [id](#input\_id) | The unique identifier for this deployment. | `string` | n/a | yes |
| <a name="input_sns_topic"></a> [sns\_topic](#input\_sns\_topic) | The ARN of the SNS topic to which to send notifications. | `string` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The ID of the AWS VPC. | `string` | n/a | yes |
| <a name="input_vpc_private_subnets"></a> [vpc\_private\_subnets](#input\_vpc\_private\_subnets) | The IDs of the private subnets in the VPC. | `list(string)` | n/a | yes |
| <a name="input_vpc_public_subnets"></a> [vpc\_public\_subnets](#input\_vpc\_public\_subnets) | The IDs of the public subnets in the VPC. | `list(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_aurora_cluster"></a> [aurora\_cluster](#output\_aurora\_cluster) | The RDS Aurora database. |
| <a name="output_load_balancers"></a> [load\_balancers](#output\_load\_balancers) | Load balancers for the services. |
| <a name="output_redis_cluster"></a> [redis\_cluster](#output\_redis\_cluster) | The Elasticache Redis cache. |
<!-- END_TF_DOCS -->