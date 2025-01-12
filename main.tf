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

module "ecr_repos" {
  source   = "./modules/ecr"
  id       = var.id
  aws_tags = var.aws_tags
  repo     = "${var.id}-repo"
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
  depends_on        = [module.ecs_cluster.cluster]
  source            = "./modules/database"
  id                = var.id
  aws_tags          = var.aws_tags
  acu_config        = var.db_acu_config
  engine_version    = var.db_engine_version
  instance_snapshot = var.db_instance_snapshot
  cluster_snapshot  = var.db_cluster_snapshot
  instance_count    = var.db_instance_count
  proxy             = var.db_proxy
  security_groups   = concat([module.ecs_cluster.cluster_sg.id], var.db_inbound_sg_ids)
  sns_topic         = var.sns_topic
  vpc_id            = var.vpc_id
  vpc_subnet_ids    = var.vpc_private_subnets
}

module "cache" {
  depends_on      = [module.ecs_cluster.cluster]
  source          = "./modules/cache"
  id              = var.id
  aws_tags        = var.aws_tags
  config          = var.cache_config
  sns_topic       = var.sns_topic
  security_groups = concat([module.ecs_cluster.cluster_sg.id], var.cache_inbound_sg_ids)
  vpc_id          = var.vpc_id
  vpc_subnet_ids  = length(var.vpc_private_subnets) > 3 ? slice(var.vpc_private_subnets, 0, 3) : var.vpc_private_subnets
}
