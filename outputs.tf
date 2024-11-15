output "alb" {
  value = { for k, v in var.ecs_services : k => module.ecs_svc.alb }
}
