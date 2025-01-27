module "ecs_cluster" {
  source             = "./modules/ecs_cluster"
  id                 = var.id
  aws_tags           = var.aws_tags
  load_balancer      = var.ecs_load_balancer
  security_groups    = var.ecs_cluster_inbound_sg_ids
  secrets            = var.ecs_cluster_secrets
  sns_topic          = var.sns_topic
  vpc_id             = var.vpc_id
  vpc_public_subnets = var.vpc_public_subnets
}

module "ecr_repo" {
  source                 = "./modules/ecr"
  id                     = var.id
  aws_tags               = var.aws_tags
  buildcache_expiry_days = var.ecr_buildcache_expiry_days
  buildcache_tag_prefix  = var.ecr_buildcache_tag_prefix
  image_tag_mutability   = var.ecr_image_tag_mutability
  repo_name              = var.ecr_repo_name
  task_expiry_days       = var.ecr_task_expiry_days
}

module "batch" {
  source              = "./modules/batch"
  id                  = var.id
  aws_tags            = var.aws_tags
  batch_compute       = var.batch.batch_compute
  cluster_secrets     = module.ecs_cluster.cluster_secrets.arn
  cluster_sg          = module.ecs_cluster.cluster_sg.id
  managed_policies    = var.batch.iam_managed_policies
  policy              = var.batch.iam_custom_policy
  sns_topic           = var.sns_topic
  task_execution_role = module.ecs_cluster.task_execution_role.name
  vpc_id              = var.vpc_id
  vpc_private_subnets = var.vpc_private_subnets
}

module "database" {
  source                                = "./modules/database"
  id                                    = var.id
  aws_tags                              = var.aws_tags
  allow_major_version_upgrade           = var.db_allow_major_version_upgrade
  acu_config                            = var.db_acu_config
  cluster_snapshot                      = var.db_cluster_snapshot
  copy_tags_to_snapshot                 = var.db_copy_tags_to_snapshot
  engine                                = var.db_engine
  engine_version                        = var.db_engine_version
  iam_auth_enabled                      = var.db_iam_auth_enabled
  instance_count                        = var.db_instance_count
  instance_snapshot                     = var.db_instance_snapshot
  monitoring_interval                   = var.db_monitoring_interval
  performance_insights_enabled          = var.db_performance_insights_enabled
  performance_insights_retention_period = var.db_performance_insights_retention_period
  preferred_backup_window               = var.db_preferred_backup_window
  preferred_maintenance_window          = var.db_preferred_maintenance_window
  proxy                                 = var.db_proxy
  security_groups                       = concat([module.ecs_cluster.cluster_sg.id], var.db_inbound_sg_ids)
  sns_topic                             = var.sns_topic
  storage_encrypted                     = var.db_storage_encrypted
  vpc_id                                = var.vpc_id
  vpc_subnet_ids                        = var.vpc_private_subnets

  depends_on = [module.ecs_cluster.cluster]
}

module "cache" {
  source            = "./modules/cache"
  id                = var.id
  aws_tags          = var.aws_tags
  config            = var.cache_config
  security_groups   = concat([module.ecs_cluster.cluster_sg.id], var.cache_inbound_sg_ids)
  serverless        = var.cache_serverless
  serverless_config = var.cache_serverless_config
  sns_topic         = var.sns_topic
  vpc_id            = var.vpc_id
  vpc_subnet_ids    = length(var.vpc_private_subnets) > 3 ? slice(var.vpc_private_subnets, 0, 3) : var.vpc_private_subnets

  depends_on = [module.ecs_cluster.cluster]
}
