module "ecs_cluster" {
  source          = "./modules/ecs_cluster"
  id              = var.id
  aws_tags        = var.aws_tags
  sns_topic       = var.sns_topic
  security_groups = var.ecs_cluster_inbound_sg_ids
  vpc_id          = var.vpc_id
}

module "http" {
  depends_on          = [module.ecs_cluster.cluster]
  source              = "./modules/http"
  id                  = var.id
  aws_tags            = var.aws_tags
  acm_domain          = var.http_acm_domain
  cluster_name        = module.ecs_cluster.cluster.name
  cluster_sg          = module.ecs_cluster.cluster_sg.id
  container           = var.http_container
  scale_policy        = var.http_scale_policy
  task_execution_role = module.ecs_cluster.task_execution_role.name
  managed_policies    = var.http_managed_policies
  policy              = var.http_policy
  sns_topic           = var.sns_topic
  vpc_id              = var.vpc_id
  vpc_public_subnets  = var.vpc_public_subnets
  vpc_private_subnets = var.vpc_private_subnets
}

module "database" {
  depends_on      = [module.ecs_cluster.cluster]
  source          = "./modules/database"
  id              = var.id
  aws_tags        = var.aws_tags
  acu_config      = var.db_acu_config
  engine_version  = var.db_engine_version
  source_snapshot = var.db_source_snapshot
  instance_count  = var.db_instance_count
  proxy           = var.db_proxy
  security_groups = concat([module.ecs_cluster.cluster_sg.id], var.db_inbound_sg_ids)
  sns_topic       = var.sns_topic
  vpc_id          = var.vpc_id
  vpc_subnet_ids  = var.vpc_private_subnets
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
  vpc_subnet_ids  = var.vpc_private_subnets
}
