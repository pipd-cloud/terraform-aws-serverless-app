module "ecs_cluster" {
  source             = "./modules/ecs_cluster"
  id                 = var.id
  aws_tags           = var.aws_tags
  load_balancer      = var.ecs_load_balancer
  sns_topic          = var.sns_topic
  security_groups    = var.ecs_cluster_inbound_sg_ids
  secrets            = var.ecs_cluster_secrets
  vpc_id             = var.vpc_id
  vpc_public_subnets = var.vpc_public_subnets
}

module "ecr_repo" {
  count                  = length(var.ecr_config)
  source                 = "./modules/ecr"
  id                     = var.id
  aws_tags               = var.aws_tags
  repo_name              = var.ecr_config[count.index].name
  image_tag_mutability   = var.ecr_config[count.index].image_tag_mutability
  lifecycle_policy_rules = var.ecr_config[count.index].lifecycle_policy_rules
}

module "batch" {
  source              = "./modules/batch"
  id                  = var.id
  aws_tags            = var.aws_tags
  batch_compute       = var.batch.batch_compute
  cluster_sg          = module.ecs_cluster.cluster_sg.id
  cluster_secrets     = module.ecs_cluster.cluster_secrets.arn
  managed_policies    = var.batch.iam_managed_policies
  policy              = var.batch.iam_custom_policy
  sns_topic           = var.sns_topic
  task_execution_role = module.ecs_cluster.task_execution_role.name
  vpc_id              = var.vpc_id
  vpc_private_subnets = var.vpc_private_subnets
}

module "database" {
  depends_on                            = [module.ecs_cluster.cluster]
  source                                = "./modules/database"
  id                                    = var.id
  aws_tags                              = var.aws_tags
  allow_major_version_upgrade           = var.db_allow_major_version_upgrade
  acu_config                            = var.db_acu_config
  copy_tags_to_snapshot                 = var.db_copy_tags_to_snapshot
  storage_encrypted                     = var.db_storage_encrypted
  engine                                = var.db_engine
  engine_version                        = var.db_engine_version
  iam_auth_enabled                      = var.db_iam_auth_enabled
  instance_snapshot                     = var.db_instance_snapshot
  cloudwatch_log_group_exports          = var.db_cloudwatch_log_group_exports
  cluster_snapshot                      = var.db_cluster_snapshot
  deletion_protection                   = var.db_deletion_protection
  global_cluster                        = var.db_global_cluster
  public_instance_count                 = var.db_public_instance_count
  private_instance_count                = var.db_instance_count
  monitoring_interval                   = var.db_monitoring_interval
  performance_insights_enabled          = var.db_performance_insights_enabled
  performance_insights_retention_period = var.db_performance_insights_retention_period
  preferred_backup_window               = var.db_preferred_backup_window
  preferred_maintenance_window          = var.db_preferred_maintenance_window
  proxy                                 = var.db_proxy
  security_groups                       = concat([module.ecs_cluster.cluster_sg.id], var.db_inbound_sg_ids)
  sns_topic                             = var.sns_topic
  vpc_id                                = var.vpc_id
  vpc_public_subnet_ids                 = var.vpc_public_subnets
  vpc_private_subnet_ids                = var.vpc_private_subnets
}

module "cache" {
  depends_on        = [module.ecs_cluster.cluster]
  source            = "./modules/cache"
  id                = var.id
  aws_tags          = var.aws_tags
  serverless        = var.cache_serverless
  serverless_config = var.cache_serverless_config
  config            = var.cache_config
  sns_topic         = var.sns_topic
  security_groups   = concat([module.ecs_cluster.cluster_sg.id], var.cache_inbound_sg_ids)
  vpc_id            = var.vpc_id
  vpc_subnet_ids    = length(var.vpc_private_subnets) > 3 ? slice(var.vpc_private_subnets, 0, 3) : var.vpc_private_subnets
}
